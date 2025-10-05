import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biophantom_core/biophantom_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'services/bluetooth_host.dart';
import 'services/consensus_engine.dart';
import 'services/notification_service.dart';
import 'screens/room_dashboard.dart';
import 'admin_login.dart';
import 'map_page.dart';
import 'app_info_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await _initializeServices();
  
  runApp(const BioPhantomMainframeApp());
}

Future<void> _initializeServices() async {
  // Initialize core services
  try {
    // Initialize notification service
    await NotificationService().initialize();

    // Initialize Bluetooth host
    final bluetoothService = BluetoothHostService();
    await bluetoothService.initialize();

    // Initialize consensus engine
    final consensusEngine = ConsensusEngine();

    // Store services globally (in a real app, you'd use a service locator)
    // For now, we'll pass them through the widget tree
  } catch (e) {
    debugPrint('Failed to initialize services: $e');
  }
}

class BioPhantomMainframeApp extends StatelessWidget {
  const BioPhantomMainframeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BioPhantom Mainframe',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: const AdminLoginPage(),
      routes: {
        '/main': (context) => const MainframeNavigation(),
        '/map': (context) => const MapPage(),
        '/app_info': (context) => const AppInfoScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildLightTheme() {
    const primaryColor = Color(0xFF1976D2); // Professional blue
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.montserratTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
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
        backgroundColor: Color(0xFFE3F2FD),
        labelStyle: TextStyle(color: primaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const primaryColor = Color(0xFF1976D2);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme),
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
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class MainframeNavigation extends StatefulWidget {
  const MainframeNavigation({super.key});

  @override
  State<MainframeNavigation> createState() => _MainframeNavigationState();
}

class _MainframeNavigationState extends State<MainframeNavigation> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final GlobalKey _captureKey = GlobalKey();

  // Services
  late final BluetoothHostService _bluetoothService;
  late final ConsensusEngine _consensusEngine;

  final List<Widget> _screens = [];
  final List<String> _titles = [
    'Room Dashboard',
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
    _initializeServices();
    _pageController = PageController(initialPage: _selectedIndex);
    _alertAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  }

  Future<void> _initializeServices() async {
    _bluetoothService = BluetoothHostService();
    _consensusEngine = ConsensusEngine();

    try {
      await _bluetoothService.initialize();

      // Listen to room alerts for notifications
      _consensusEngine.alertStream.listen((alert) {
        if (alert.level == AlertLevel.outbreak) {
          NotificationService().showOutbreakNotification(
            alert.roomId,
            alert.message ?? 'Outbreak detected',
          );
        }
      });

      // Set up screens with services
      _screens.addAll([
        RoomDashboardScreen(
          bluetoothService: _bluetoothService,
          consensusEngine: _consensusEngine,
        ),
        HomeScreen(),
        SettingsScreen(),
        CommunityScreen(),
        const MapPage(),
      ]);
    } catch (e) {
      debugPrint('Service initialization error: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _alertAnimController.dispose();
    _bluetoothService.dispose();
    _consensusEngine.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
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
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/biophantom_screenshot_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'BioPhantom Mainframe screenshot');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to capture: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAlert = _consensusEngine.roomAlerts.values.any((alert) => alert.isOutbreak);
    
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(_titles[_selectedIndex], key: ValueKey<int>(_selectedIndex)),
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
          child: _screens.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : PageView(
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

// Placeholder screens (you can implement these or use existing ones)
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Home Screen - Implement as needed'),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings Screen - Implement as needed'),
    );
  }
}

class CommunityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Community Screen - Implement as needed'),
    );
  }
}
