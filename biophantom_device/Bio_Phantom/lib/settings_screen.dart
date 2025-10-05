import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeModeChanged;

  const SettingsScreen({super.key, this.onThemeModeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings values with default values
  double _sensorSensitivity = 0.5;
  bool _notificationsEnabled = true;
  bool _vibrationAlerts = true;
  bool _audioAlerts = true;
  bool _dataCollection = false;
  String _selectedTheme = 'system';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _sensorSensitivity = prefs.getDouble('sensorSensitivity') ?? 0.5;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _vibrationAlerts = prefs.getBool('vibrationAlerts') ?? true;
      _audioAlerts = prefs.getBool('audioAlerts') ?? true;
      _dataCollection = prefs.getBool('dataCollection') ?? false;
      _selectedTheme = prefs.getString('selectedTheme') ?? 'system';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('sensorSensitivity', _sensorSensitivity);
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('vibrationAlerts', _vibrationAlerts);
    await prefs.setBool('audioAlerts', _audioAlerts);
    await prefs.setBool('dataCollection', _dataCollection);
    await prefs.setString('selectedTheme', _selectedTheme);

    // Apply theme changes
    _applyThemeChanges();

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _applyThemeChanges() {
    if (widget.onThemeModeChanged != null) {
      switch (_selectedTheme) {
        case 'light':
          widget.onThemeModeChanged!(ThemeMode.light);
          break;
        case 'dark':
          widget.onThemeModeChanged!(ThemeMode.dark);
          break;
        case 'system':
        default:
          widget.onThemeModeChanged!(ThemeMode.system);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: isDarkMode
            ? const Color(0xFF0D47A1)
            : const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.black26,
        centerTitle: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            'assets/biophantom_logo.png',
            width: 32,
            height: 32,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDarkMode ? Colors.grey.shade900 : Colors.white,
              isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
              isDarkMode ? Colors.grey.shade900 : Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1976D2).withOpacity(0.1),
                        const Color(0xFF1976D2).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF1976D2).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.settings,
                              color: Color(0xFF1976D2),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'BioPhantom Settings',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Configure your BioPhantom detector preferences',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Sensor Sensitivity Section
                _buildSectionHeader('Detection Settings'),
                _buildSliderSetting(
                  'Sensor Sensitivity',
                  'Adjust how sensitive the detector is to biohazards',
                  _sensorSensitivity,
                  (value) {
                    setState(() {
                      _sensorSensitivity = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Alert Settings
                _buildSectionHeader('Alert Preferences'),
                _buildToggleSetting(
                  'Enable Notifications',
                  'Receive alerts when biohazards are detected',
                  _notificationsEnabled,
                  (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                _buildToggleSetting(
                  'Vibration Alerts',
                  'Use device vibration for critical alerts',
                  _vibrationAlerts,
                  (value) {
                    setState(() {
                      _vibrationAlerts = value;
                    });
                  },
                ),
                _buildToggleSetting(
                  'Audio Alerts',
                  'Play sounds for different alert levels',
                  _audioAlerts,
                  (value) {
                    setState(() {
                      _audioAlerts = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Data Privacy Section
                _buildSectionHeader('Privacy & Data'),
                _buildToggleSetting(
                  'Data Collection',
                  'Allow anonymous usage data collection for research',
                  _dataCollection,
                  (value) {
                    setState(() {
                      _dataCollection = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Theme Settings
                _buildSectionHeader('Appearance'),
                _buildThemeSelector(),
                const SizedBox(height: 32),

                // Save Button
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1976D2).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _saveSettings,
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Save Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1976D2).withOpacity(0.1),
            const Color(0xFF1976D2).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getSectionIcon(title),
              color: const Color(0xFF1976D2),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Detection Settings':
        return Icons.sensors;
      case 'Alert Preferences':
        return Icons.notifications;
      case 'Privacy & Data':
        return Icons.security;
      case 'Appearance':
        return Icons.palette;
      default:
        return Icons.settings;
    }
  }

  Widget _buildSliderSetting(
    String title,
    String description,
    double value,
    Function(double) onChanged,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.grey.shade50.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.sensors,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: Color(0xFF1976D2)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: value,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label: value.toStringAsFixed(1),
                      activeColor: const Color(0xFF1976D2),
                      inactiveColor: Colors.grey[300],
                      onChanged: onChanged,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${(value * 100).round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSetting(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.grey.shade50.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? const Color(0xFF1976D2).withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: value
                ? const Color(0xFF1976D2).withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
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
                    color: value
                        ? const Color(0xFF1976D2).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getToggleIcon(title),
                    color: value ? const Color(0xFF1976D2) : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: value
                              ? const Color(0xFF1976D2)
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: value
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1976D2).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF1976D2),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getToggleIcon(String title) {
    switch (title) {
      case 'Enable Notifications':
        return Icons.notifications;
      case 'Vibration Alerts':
        return Icons.vibration;
      case 'Audio Alerts':
        return Icons.volume_up;
      case 'Data Collection':
        return Icons.analytics;
      default:
        return Icons.settings;
    }
  }

  Widget _buildThemeSelector() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.grey.shade50.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.palette,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'App Theme',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildThemeOption('Light', 'light', Icons.light_mode),
                _buildThemeOption('Dark', 'dark', Icons.dark_mode),
                _buildThemeOption('System', 'system', Icons.auto_mode),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String name, String value, IconData icon) {
    final isSelected = _selectedTheme == value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: IconButton(
              icon: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 32,
              ),
              onPressed: () {
                setState(() {
                  _selectedTheme = value;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isSelected ? const Color(0xFF1976D2) : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
            child: Text(name),
          ),
        ],
      ),
    );
  }
}
