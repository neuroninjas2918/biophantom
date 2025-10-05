import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import 'services/emergency_actions.dart';
import 'services/doctor_finder.dart';
import 'services/sensor_fusion.dart';
import 'services/community_alert.dart';
import 'services/settings.dart';
import 'admin_login.dart';
import 'map_page.dart';
import 'app_info_screen.dart';

import 'organization_dashboard.dart';
import 'server/api_bridge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.instance.load();
  await ServerBridge.start();
  runApp(const BioPhantomMainframeApp());
}

class BioPhantomMainframeApp extends StatelessWidget {
  const BioPhantomMainframeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final color = settings.primaryColor;
        final brightness = settings.darkMode
            ? Brightness.dark
            : Brightness.light;
        final scheme = ColorScheme.fromSeed(
          seedColor: color,
          brightness: brightness,
        );
        final baseTheme = ThemeData(brightness: brightness, useMaterial3: true);

        return MaterialApp(
          title: 'BioPhantom Mainframe',
          theme: baseTheme.copyWith(
            colorScheme: scheme,
            textTheme: GoogleFonts.montserratTextTheme(baseTheme.textTheme),
            scaffoldBackgroundColor: scheme.background,
            appBarTheme: AppBarTheme(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              elevation: 8,
              shadowColor: scheme.primaryContainer,
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: scheme.primary,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: scheme.primary,
              indicatorColor: Colors.white.withOpacity(0.2),
              elevation: 12,
              surfaceTintColor: scheme.primary,
              shadowColor: scheme.primaryContainer,
              height: 64,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            ),
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaleFactor: settings.textScale),
              child: child!,
            );
          },
          initialRoute: '/',
          routes: {
            '/': (context) => const AdminLoginPage(),
            '/main': (context) => const MainframeNavigation(),
            '/map': (context) => const MapPage(),
            '/app_info': (context) => const AppInfoScreen(),
          },
        );
      },
    );
  }
}

class MainframeNavigation extends StatefulWidget {
  const MainframeNavigation({super.key});

  @override
  State<MainframeNavigation> createState() => _MainframeNavigationState();
}

class _MainframeNavigationState extends State<MainframeNavigation>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final GlobalKey _captureKey = GlobalKey();

  final List<Widget> _screens = [
    OrganizationDashboardScreen(),
    HomeScreen(),
    SettingsScreen(),
    CommunityScreen(),
    MapPage(),
  ];

  final List<String> _titles = [
    'Site Integrity Matrix',
    'Detection & Analysis',
    'Settings',
    'Community Chat',
    'Live Risk Map',
  ];

  late final PageController _pageController;
  late final AnimationController _alertAnimController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    CommunityAlertService.instance.addListener(_onAlertChanged);
    _alertAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (CommunityAlertService.instance.hasAlert) {
      _alertAnimController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    CommunityAlertService.instance.removeListener(_onAlertChanged);
    _alertAnimController.dispose();
    super.dispose();
  }

  void _onAlertChanged() {
    if (!mounted) return;
    setState(() {
      if (CommunityAlertService.instance.hasAlert) {
        _alertAnimController.repeat(reverse: true);
      } else {
        _alertAnimController.stop();
        _alertAnimController.reset();
      }
    });
  }

  void _onItemTapped(int index) {
    if (SettingsService.instance.haptics) {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _captureAndShare() async {
    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/biophantom_screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'BioPhantom Mainframe screenshot');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to capture: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAlert = CommunityAlertService.instance.hasAlert;
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            _titles[_selectedIndex],
            key: ValueKey<int>(_selectedIndex),
          ),
        ),
        backgroundColor: hasAlert ? Colors.red.shade800 : Colors.blue,
        elevation: 8,
        shadowColor: hasAlert ? Colors.redAccent : Colors.blueAccent,
        actions: [
          if (hasAlert)
            FadeTransition(
              opacity: _alertAnimController,
              child: const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.warning_amber_rounded, color: Colors.white),
              ),
            ),
          IconButton(
            tooltip: 'Share screenshot',
            icon: const Icon(Icons.camera_alt),
            onPressed: _captureAndShare,
          ),
          IconButton(
            tooltip: 'Open settings',
            icon: const Icon(Icons.settings),
            onPressed: () {
              _onItemTapped(2); // jump to Settings tab
            },
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _captureKey,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          color: Colors.white,
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: _screens,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard, color: Colors.white70),
            selectedIcon: Icon(Icons.dashboard, color: Colors.white),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.home, color: Colors.white70),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings, color: Colors.white70),
            selectedIcon: Icon(Icons.settings, color: Colors.white),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.group, color: Colors.white70),
            selectedIcon: Icon(Icons.group, color: Colors.white),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.map, color: Colors.white70),
            selectedIcon: Icon(Icons.map, color: Colors.white),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EmergencyActionsService _emergencyService = EmergencyActionsService();
  final DoctorFinderService _doctorService = DoctorFinderService();
  final SensorFusionService _fusionService = SensorFusionService();

  double _vibProb = 0.0;
  double _audProb = 0.0;
  double _riskScore = 0.0;
  String _action = '';
  Map<String, String>? _doctorInfo;
  final List<NodeStat> _nodes = <NodeStat>[];

  @override
  void initState() {
    super.initState();
    _seedNodes();
  }

  void _seedNodes() {
    _nodes
      ..clear()
      ..addAll([
        NodeStat(name: 'Phone A'),
        NodeStat(name: 'Phone B'),
        NodeStat(name: 'Phone C'),
        NodeStat(name: 'Phone D'),
        NodeStat(name: 'Phone E'),
      ]);
    _refreshAnalytics();
  }

  void _refreshAnalytics() {
    final rng = Random();
    setState(() {
      for (final n in _nodes) {
        final risk = rng.nextDouble();
        final health = (1.0 - risk).clamp(0.0, 1.0);
        String status;
        if (risk > 0.8) {
          status = 'Critical';
        } else if (risk > 0.5) {
          status = 'Risk';
        } else if (risk > 0.25) {
          status = 'Watch';
        } else {
          status = 'Healthy';
        }
        n
          ..risk = risk
          ..health = health
          ..status = status;
      }
    });
  }

  void _runDetection() {
    setState(() {
      // Simulate detection
      _vibProb = 0.95; // Simulated high vibration probability
      _audProb = 0.92; // Simulated high audio probability
      _riskScore = _fusionService.getRiskScore(_vibProb, _audProb);
      _action = _emergencyService.getAction(_riskScore);
      if (_riskScore > 0.9) {
        _doctorInfo = _doctorService.findNearestSpecialist();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detection & Analysis',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vibration Probability: ${_vibProb.toStringAsFixed(2)}'),
                  Text('Audio Probability: ${_audProb.toStringAsFixed(2)}'),
                  Text('Risk Score: ${_riskScore.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _runDetection,
                    child: const Text('Start Detection'),
                  ),
                  if (_action.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'AI Action: $_action',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ],
                  if (_doctorInfo != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Nearest Specialist:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Name: ${_doctorInfo!['name']}'),
                    Text('Phone: ${_doctorInfo!['phone']}'),
                    Text('Address: ${_doctorInfo!['address']}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Node Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _nodes.length,
              itemBuilder: (context, index) {
                final n = _nodes[index];
                Color barColor;
                Color chipColor;
                Color chipText;
                switch (n.status) {
                  case 'Critical':
                    barColor = Colors.red;
                    chipColor = Colors.red.shade100;
                    chipText = Colors.red.shade900;
                    break;
                  case 'Risk':
                    barColor = Colors.orange;
                    chipColor = Colors.orange.shade100;
                    chipText = Colors.orange.shade900;
                    break;
                  case 'Watch':
                    barColor = Colors.amber;
                    chipColor = Colors.amber.shade100;
                    chipText = Colors.amber.shade900;
                    break;
                  default:
                    barColor = Colors.green;
                    chipColor = Colors.green.shade100;
                    chipText = Colors.green.shade900;
                }
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                n.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: chipColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                n.status,
                                style: TextStyle(
                                  color: chipText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const SizedBox(width: 2),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: n.risk,
                                  minHeight: 10,
                                  backgroundColor: Colors.grey.shade200,
                                  color: barColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('${(n.risk * 100).toStringAsFixed(0)}%'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Colors.pink.shade300,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Health ratio: ${(n.health * 100).toStringAsFixed(0)}%',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _refreshAnalytics,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Analytics'),
          ),
        ],
      ),
    );
  }
}

class NodeStat {
  final String name;
  double risk;
  double health;
  String status;
  NodeStat({
    required this.name,
    this.risk = 0,
    this.health = 1,
    this.status = 'Healthy',
  });
}

// ChatbotScreen removed

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    final colorChoices = <MaterialColor>[
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          leading: Icon(Icons.settings),
          title: Text('Settings'),
          subtitle: Text('Personalize your experience'),
        ),
        SwitchListTile(
          title: const Text('Dark Mode'),
          value: settings.darkMode,
          onChanged: (v) => settings.darkMode = v,
          secondary: const Icon(Icons.dark_mode),
        ),
        SwitchListTile(
          title: const Text('Notifications'),
          value: settings.notifications,
          onChanged: (v) => settings.notifications = v,
          secondary: const Icon(Icons.notifications_active),
        ),
        SwitchListTile(
          title: const Text('Haptics'),
          value: settings.haptics,
          onChanged: (v) => settings.haptics = v,
          secondary: const Icon(Icons.vibration),
        ),
        const SizedBox(height: 8),
        const Text('Text Size', style: TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: settings.textScale,
          min: 0.9,
          max: 1.4,
          divisions: 10,
          label: settings.textScale.toStringAsFixed(2),
          onChanged: (v) => settings.textScale = v,
        ),
        const SizedBox(height: 8),
        const Text(
          'Primary Color',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Wrap(
          spacing: 10,
          children: [
            for (final c in colorChoices)
              ChoiceChip(
                label: Text(c.toString().split('.').last),
                selected: settings.primaryColor == c,
                selectedColor: c.shade300,
                onSelected: (_) => settings.primaryColor = c,
                avatar: CircleAvatar(backgroundColor: c, radius: 8),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          subtitle: const Text('BioPhantom Mainframe v1.0'),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'BioPhantom Mainframe',
            applicationVersion: '1.0.0',
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _showClearDataDialog(context, settings),
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset to defaults'),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.build_circle_outlined),
          title: Text('Advanced'),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Device & App Info'),
          onTap: () => Navigator.of(context).pushNamed('/app_info'),
        ),
      ],
    );
  }

  void _showClearDataDialog(BuildContext context, SettingsService settings) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Reset'),
          content: const Text(
            'Are you sure you want to clear all application data and reset settings to their defaults? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
              onPressed: () {
                settings.reset();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Application data has been cleared.'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityAlertService _alertService = CommunityAlertService();
  String _alertMessage = '';
  final TextEditingController _msgController = TextEditingController();
  bool _urgent = false;
  final List<_ChatMessage> _messages = <_ChatMessage>[];
  @override
  void initState() {
    super.initState();
    // Start with no detections; area is safe by default
    _alertMessage = _alertService.getAlertMessage();
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        _ChatMessage(text: text, urgent: _urgent, time: DateTime.now()),
      );
      _msgController.clear();
      if (_urgent) {
        // Trigger an alert for admins to see immediately
        _alertService.addDetectedUser('community_urgent');
      }
      _alertMessage = _alertService.getAlertMessage();
    });
  }

  String _fmtTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.group, size: 28, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _alertMessage.isEmpty
                      ? 'Community status: Safe'
                      : _alertMessage,
                  style: TextStyle(
                    color: _alertService.hasAlert ? Colors.red : Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _alertService.clearDetections();
                    _alertMessage = _alertService.getAlertMessage();
                  });
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text('No messages yet. Send a message below.'),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[_messages.length - 1 - index];
                      final bubbleColor = m.urgent
                          ? Colors.red.shade100
                          : Colors.blue.shade50;
                      final textColor = m.urgent
                          ? Colors.red.shade900
                          : Colors.blue.shade900;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: m.urgent
                                    ? Colors.red
                                    : Colors.blueAccent.withOpacity(0.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (m.urgent)
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                    if (m.urgent) const SizedBox(width: 6),
                                    Text(
                                      m.urgent ? 'Urgent' : 'Message',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  m.text,
                                  style: TextStyle(color: textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _fmtTime(m.time),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message for admin...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  const Text(
                    'Urgent',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Switch(
                    value: _urgent,
                    onChanged: (v) => setState(() => _urgent = v),
                    activeColor: Colors.red,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
                label: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool urgent;
  final DateTime time;
  _ChatMessage({required this.text, required this.urgent, required this.time});
}
