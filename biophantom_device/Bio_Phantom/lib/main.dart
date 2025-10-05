import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'logic/detector_logic.dart';
import 'chatbot_screen.dart';
import 'settings_screen.dart';
import 'dashboard_screen.dart';
import 'services/fusion_engine.dart';
import 'services/neurotoxin_detector.dart';
import 'widgets/prob_sparkline.dart';
import 'transport/transport_facade.dart';
import 'package:protocol/protocol.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const NeurotoxinDetectorApp());
}

class NeurotoxinDetectorApp extends StatefulWidget {
  const NeurotoxinDetectorApp({super.key});

  @override
  State<NeurotoxinDetectorApp> createState() => _NeurotoxinDetectorAppState();
}

class _NeurotoxinDetectorAppState extends State<NeurotoxinDetectorApp> {
  ThemeMode _themeMode = ThemeMode.system;
  final detectorLogic = DetectorLogic();

  @override
  void initState() {
    super.initState();
    detectorLogic.init();
    TransportFacade.instance.start();
  }

  @override
  void dispose() {
    detectorLogic.dispose();
    TransportFacade.instance.dispose();
    super.dispose();
  }

  void _updateThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  static ThemeData buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2), // Professional blue
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      brightness: Brightness.light,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.black26,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFFE3F2FD),
        labelStyle: TextStyle(color: Color(0xFF1976D2)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: Colors.black26,
        ),
      ),
    );
  }

  static ThemeData buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      brightness: Brightness.dark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFF0D47A1),
        labelStyle: TextStyle(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neurotoxin Detector',
      themeMode: _themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: MainScreen(
        detectorLogic: detectorLogic,
        onThemeModeChanged: _updateThemeMode,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final DetectorLogic detectorLogic;
  final Function(ThemeMode) onThemeModeChanged;

  const MainScreen({
    super.key,
    required this.detectorLogic,
    required this.onThemeModeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Widget> _buildScreens() {
    return [
      DetectorScreen(detectorLogic: widget.detectorLogic),
      const ChatbotScreen(),
      SettingsScreen(onThemeModeChanged: widget.onThemeModeChanged),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreens()[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          // When navigating to the detector screen, update settings
          if (index == 0 && _currentIndex != 0) {
            await widget.detectorLogic.updateSettings();
          }

          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Detector'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chatbot'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DetectorScreen extends StatefulWidget {
  final DetectorLogic detectorLogic;

  const DetectorScreen({super.key, required this.detectorLogic});

  @override
  State<DetectorScreen> createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen> {
  double motionValue = 0, audioProb = 0;
  Decision dec = Decision.safe;
  SensorData? latestSensorData;
  late StreamSubscription<DetectorState> _subscription;

  // Hardcoded doctors database
  final Map<String, List<Map<String, String>>> doctors = {
    'New York': [
      {
        'name': 'Dr. Emily Johnson',
        'phone': '+1-212-555-0123',
        'specialty': 'Neurology',
      },
      {
        'name': 'Dr. Michael Chen',
        'phone': '+1-212-555-0456',
        'specialty': 'Toxicology',
      },
    ],
    'Los Angeles': [
      {
        'name': 'Dr. Sarah Williams',
        'phone': '+1-213-555-0789',
        'specialty': 'Emergency Medicine',
      },
      {
        'name': 'Dr. David Rodriguez',
        'phone': '+1-213-555-0321',
        'specialty': 'Neurology',
      },
    ],
    'Chicago': [
      {
        'name': 'Dr. Lisa Thompson',
        'phone': '+1-312-555-0654',
        'specialty': 'Toxicology',
      },
      {
        'name': 'Dr. Robert Kim',
        'phone': '+1-312-555-0987',
        'specialty': 'Emergency Medicine',
      },
    ],
    'Houston': [
      {
        'name': 'Dr. Jennifer Davis',
        'phone': '+1-713-555-0213',
        'specialty': 'Neurology',
      },
      {
        'name': 'Dr. James Wilson',
        'phone': '+1-713-555-0546',
        'specialty': 'Toxicology',
      },
    ],
    'Phoenix': [
      {
        'name': 'Dr. Maria Garcia',
        'phone': '+1-602-555-0879',
        'specialty': '+1-602-555-0321',
      },
      {
        'name': 'Dr. Thomas Brown',
        'phone': '+1-602-555-0654',
        'specialty': 'Emergency Medicine',
      },
    ],
  };

  // Detection state - removed separate detection

  @override
  void initState() {
    super.initState();
    _subscription = widget.detectorLogic.stream.listen((s) {
      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          // Show sensor magnitude as motion value (normalized to 0-1 range)
          if (s.sensorData != null) {
            motionValue =
                (s.sensorData!.accMagnitude + s.sensorData!.gyroMagnitude) /
                20.0; // Normalize
            motionValue = motionValue.clamp(0.0, 1.0);
          }
          audioProb = s.audProb ?? 0;
          dec = s.decision;
          latestSensorData = s.sensorData;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Color _statusColor() {
    switch (dec) {
      case Decision.alert:
        return Colors.red.shade600;
      case Decision.warning:
        return Colors.orange.shade600;
      case Decision.safe:
        return Colors.green.shade600;
    }
  }

  List<Color> _statusGradient() {
    switch (dec) {
      case Decision.alert:
        return [Colors.red.shade400, Colors.red.shade800];
      case Decision.warning:
        return [Colors.orange.shade400, Colors.orange.shade800];
      case Decision.safe:
        return [Colors.green.shade400, Colors.green.shade800];
    }
  }

  String _statusText() {
    switch (dec) {
      case Decision.alert:
        return 'ALERT';
      case Decision.warning:
        return 'WARNING';
      case Decision.safe:
        return 'SAFE';
    }
  }

  void _toggleDetector() async {
    if (widget.detectorLogic.isRunning) {
      // Show explanation when stopping detection
      await widget.detectorLogic.stop();
      _showDetectionSummary();
    } else {
      await widget.detectorLogic.start();
    }
    // Check if the widget is still mounted before calling setState
    if (mounted) {
      setState(() {}); // Refresh UI
    }
  }

  void _showDetectionSummary() {
    String explanation = _generateDetectionExplanation();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detection Summary'),
          content: SingleChildScrollView(child: Text(explanation)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to chatbot for more detailed explanation
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatbotScreen()),
                );
              },
              child: const Text('Ask Chatbot'),
            ),
          ],
        );
      },
    );
  }

  void _showEmergencyDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final locationController = TextEditingController();
    final symptomsController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Emergency Medical Assistance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please provide your information to connect with the nearest doctor.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'City/Area',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., New York, Los Angeles',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: symptomsController,
                  decoration: const InputDecoration(
                    labelText: 'Symptoms',
                    border: OutlineInputBorder(),
                    hintText: 'Describe your symptoms',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final location = locationController.text.trim();
                final symptoms = symptomsController.text.trim();

                if (name.isEmpty || phone.isEmpty || location.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                _findAndCallDoctor(name, phone, location, symptoms);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Call Doctor'),
            ),
          ],
        );
      },
    );
  }

  void _findAndCallDoctor(
    String name,
    String userPhone,
    String location,
    String symptoms,
  ) {
    // Find doctors in the specified location
    final locationDoctors = doctors[location];

    if (locationDoctors == null || locationDoctors.isEmpty) {
      // If location not found, use default (first available)
      final defaultLocation = doctors.keys.first;
      final defaultDoctors = doctors[defaultLocation]!;
      _callDoctor(defaultDoctors[0], name, userPhone, location, symptoms);
      return;
    }

    // For simplicity, call the first doctor
    _callDoctor(locationDoctors[0], name, userPhone, location, symptoms);
  }

  void _callDoctor(
    Map<String, String> doctor,
    String name,
    String userPhone,
    String location,
    String symptoms,
  ) {
    final phoneNumber = doctor['phone']!;
    final doctorName = doctor['name']!;
    final specialty = doctor['specialty']!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Doctor Found'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: $doctorName'),
              Text('Specialty: $specialty'),
              Text('Phone: $phoneNumber'),
              const SizedBox(height: 12),
              const Text(
                'Emergency information will be shared with the doctor.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final url = Uri.parse('tel:$phoneNumber');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to make phone call'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Call Now'),
            ),
          ],
        );
      },
    );
  }

  String _generateDetectionExplanation() {
    StringBuffer explanation = StringBuffer();

    explanation.writeln('Detection Session Summary:\n');

    // Add sensor data summary
    if (latestSensorData != null) {
      explanation.writeln('Sensor Analysis:');
      explanation.writeln(
        '• Accelerometer magnitude: ${latestSensorData!.accMagnitude.toStringAsFixed(2)} m/s²',
      );
      explanation.writeln(
        '• Gyroscope magnitude: ${latestSensorData!.gyroMagnitude.toStringAsFixed(2)} rad/s',
      );
      explanation.writeln(
        '• Motion probability: ${(motionValue * 100).toStringAsFixed(1)}%',
      );
      explanation.writeln(
        '• Audio probability: ${(audioProb * 100).toStringAsFixed(1)}%\n',
      );
    }

    // Add decision explanation
    explanation.writeln('Final Assessment:');
    switch (dec) {
      case Decision.safe:
        explanation.writeln(
          '✅ SAFE - No significant neurotoxin symptoms detected.',
        );
        explanation.writeln(
          'Your sensor readings indicate normal, stable movement patterns.',
        );
        break;
      case Decision.warning:
        explanation.writeln('⚠️ WARNING - Moderate symptoms detected.');
        explanation.writeln(
          'Some unusual movement patterns were observed. Monitor for changes.',
        );
        break;
      case Decision.alert:
        explanation.writeln('🚨 ALERT - High risk of neurotoxin exposure!');
        explanation.writeln(
          'Significant tremor-like symptoms detected. Audio analysis was triggered.',
        );
        explanation.writeln('Immediate medical evaluation recommended.');
        break;
    }

    // Add neurotoxin probability if available
    double neuroProb = widget.detectorLogic.getNeurotoxinProbability();
    if (neuroProb > 0) {
      explanation.writeln('\nNeurotoxin Detection:');
      explanation.writeln(
        '• Probability: ${(neuroProb * 100).toStringAsFixed(1)}%',
      );
      if (neuroProb > 0.7) {
        explanation.writeln('• HIGH RISK - Seek immediate medical attention');
      } else if (neuroProb > 0.5) {
        explanation.writeln('• MODERATE RISK - Consult healthcare provider');
      } else {
        explanation.writeln('• LOW RISK - Continue monitoring');
      }
    }

    explanation.writeln(
      '\n💡 Tip: For more detailed analysis or questions about neurotoxin symptoms,',
    );
    explanation.writeln('tap "Ask Chatbot" to consult our AI assistant.');

    return explanation.toString();
  }

  void _showDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DashboardScreen(detectorLogic: widget.detectorLogic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neurotoxin Detector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: _showDashboard,
            tooltip: 'Sensor Dashboard',
          ),
        ],
        leading: Image.asset(
          'assets/biophantom_logo.png',
          width: 40,
          height: 40,
        ), // Custom logo
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    Colors.grey.shade900,
                    Colors.grey.shade800,
                    Colors.grey.shade900,
                  ]
                : [Colors.white, Colors.grey.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Enhanced Start/Stop button with gradient and animation
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.detectorLogic.isRunning
                            ? [Colors.red.shade400, Colors.red.shade700]
                            : [Colors.green.shade400, Colors.green.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (widget.detectorLogic.isRunning
                                      ? Colors.red
                                      : Colors.green)
                                  .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _toggleDetector,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          widget.detectorLogic.isRunning
                              ? Icons.stop_circle
                              : Icons.play_circle,
                          key: ValueKey(widget.detectorLogic.isRunning),
                          size: 28,
                        ),
                      ),
                      label: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          widget.detectorLogic.isRunning
                              ? 'Stop Detection'
                              : 'Start Detection',
                          key: ValueKey(widget.detectorLogic.isRunning),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Enhanced status indicator with gradient and animation
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _statusGradient(),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: _statusColor().withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            dec == Decision.alert
                                ? Icons.warning
                                : dec == Decision.warning
                                ? Icons.info
                                : Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _statusText(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Accelerometer magnitude meter
                _meter(
                  'Accelerometer Magnitude (m/s²)',
                  latestSensorData?.accMagnitude ?? 0.0,
                  Icons.vibration,
                  Colors.blue,
                  showAsPercentage: false,
                ),
                const SizedBox(height: 20),

                // Gyroscope magnitude meter
                _meter(
                  'Gyroscope Magnitude (rad/s)',
                  latestSensorData?.gyroMagnitude ?? 0.0,
                  Icons.rotate_right,
                  Colors.green,
                  showAsPercentage: false,
                ),
                const SizedBox(height: 20),

                // Emergency Call Button (show when WARNING or ALERT)
                if (dec == Decision.warning || dec == Decision.alert) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: _showEmergencyDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        shadowColor: Colors.red.shade200,
                      ),
                      icon: const Icon(Icons.call, size: 28),
                      label: const Text(
                        'EMERGENCY CALL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Model Probability meter
                _meter(
                  'Model Probability',
                  motionValue,
                  Icons.directions_run,
                  Colors.orange,
                ),
                const SizedBox(height: 20),

                // Cough Probability meter
                _meter(
                  'Cough Probability',
                  audioProb,
                  Icons.mic,
                  Colors.purple,
                ),
                const SizedBox(height: 20),

                const SizedBox(height: 20),

                // Enhanced continuous neurotoxin detection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade50,
                        Colors.deepPurple.shade100,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.deepPurple.shade200,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.shade100,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.monitor_heart,
                                color: Colors.deepPurple,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Continuous Neurotoxin Monitoring',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Neurotoxin detection is running continuously in the background with advanced vibration and audio analysis.',
                          style: TextStyle(fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Colors.deepPurple,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Next check: Every 30 seconds',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Show current neurotoxin probability if available
                        if (widget.detectorLogic.getNeurotoxinProbability() >
                            0) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Neurotoxin Probability:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: widget.detectorLogic
                                        .getNeurotoxinProbability()
                                        .clamp(0, 1),
                                    backgroundColor: Colors.grey[300],
                                    color:
                                        widget.detectorLogic
                                                .getNeurotoxinProbability() >
                                            0.7
                                        ? Colors.red.shade600
                                        : widget.detectorLogic
                                                  .getNeurotoxinProbability() >
                                              0.5
                                        ? Colors.orange.shade600
                                        : Colors.green.shade600,
                                    minHeight: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color:
                                        widget.detectorLogic
                                                .getNeurotoxinProbability() >
                                            0.7
                                        ? Colors.red.shade600
                                        : widget.detectorLogic
                                                  .getNeurotoxinProbability() >
                                              0.5
                                        ? Colors.orange.shade600
                                        : Colors.green.shade600,
                                  ),
                                  child: Text(
                                    '${(widget.detectorLogic.getNeurotoxinProbability() * 100).toStringAsFixed(1)}%',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sensor data section
                if (latestSensorData != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Latest Sensor Readings',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Accelerometer: X=${latestSensorData!.accX.toStringAsFixed(2)}, Y=${latestSensorData!.accY.toStringAsFixed(2)}, Z=${latestSensorData!.accZ.toStringAsFixed(2)}',
                          ),
                          Text(
                            'Gyroscope: X=${latestSensorData!.gyroX.toStringAsFixed(2)}, Y=${latestSensorData!.gyroY.toStringAsFixed(2)}, Z=${latestSensorData!.gyroZ.toStringAsFixed(2)}',
                          ),
                          Text(
                            'Timestamp: ${latestSensorData!.timestamp.toIso8601String()}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Information text
                Text(
                  'Press Start Detection to begin monitoring sensors. Neurotoxin detection uses motion and audio analysis with weighted fusion.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20), // Add some bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meter(
    String label,
    double v,
    IconData icon,
    Color color, {
    bool showAsPercentage = true,
  }) {
    final normalizedValue = showAsPercentage
        ? v.clamp(0, 1)
        : (v / 20.0).clamp(0, 1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 16,
                  width:
                      MediaQuery.of(context).size.width * 0.7 * normalizedValue,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 18,
              ),
              child: Text(
                showAsPercentage
                    ? '${(v * 100).toStringAsFixed(1)}%'
                    : '${v.toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
