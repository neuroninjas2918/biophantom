import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Service for managing Mainframe calibration settings
class MainframeCalibrationService {
  static const String _calibrationFile = 'assets/models/mainframe_calibration.json';

  // Default calibration values
  static const Map<String, dynamic> _defaultCalibration = {
    'consensus': {
      'outbreak_threshold': 2, // Min danger votes for outbreak
      'watch_threshold': 1,    // Min danger votes for watch
      'vote_window_seconds': 30,
      'max_votes_per_room': 100,
    },
    'alerts': {
      'notification_enabled': true,
      'vibration_enabled': true,
      'sound_enabled': false,
    },
    'bluetooth': {
      'advertising_timeout': 300, // seconds
      'connection_timeout': 10,
      'max_retry_attempts': 3,
    },
  };

  Map<String, dynamic> _calibration = Map.from(_defaultCalibration);

  /// Load calibration from assets
  Future<void> loadCalibration() async {
    try {
      final jsonString = await rootBundle.loadString(_calibrationFile);
      final loadedCalibration = json.decode(jsonString) as Map<String, dynamic>;

      // Merge with defaults
      _calibration = _mergeCalibration(_defaultCalibration, loadedCalibration);
    } catch (e) {
      // Use defaults if loading fails
      _calibration = Map.from(_defaultCalibration);
    }
  }

  /// Get consensus calibration settings
  Map<String, dynamic> get consensusSettings => _calibration['consensus'];

  /// Get alert calibration settings
  Map<String, dynamic> get alertSettings => _calibration['alerts'];

  /// Get Bluetooth calibration settings
  Map<String, dynamic> get bluetoothSettings => _calibration['bluetooth'];

  /// Get outbreak threshold
  int get outbreakThreshold => consensusSettings['outbreak_threshold'];

  /// Get watch threshold
  int get watchThreshold => consensusSettings['watch_threshold'];

  /// Get vote window duration
  Duration get voteWindowDuration => Duration(seconds: consensusSettings['vote_window_seconds']);

  /// Get max votes per room
  int get maxVotesPerRoom => consensusSettings['max_votes_per_room'];

  /// Check if notifications are enabled
  bool get notificationsEnabled => alertSettings['notification_enabled'];

  /// Check if vibration is enabled
  bool get vibrationEnabled => alertSettings['vibration_enabled'];

  /// Check if sound is enabled
  bool get soundEnabled => alertSettings['sound_enabled'];

  /// Get advertising timeout
  Duration get advertisingTimeout => Duration(seconds: bluetoothSettings['advertising_timeout']);

  /// Get connection timeout
  Duration get connectionTimeout => Duration(seconds: bluetoothSettings['connection_timeout']);

  /// Get max retry attempts
  int get maxRetryAttempts => bluetoothSettings['max_retry_attempts'];

  /// Update calibration settings
  Future<void> updateCalibration(Map<String, dynamic> newCalibration) async {
    _calibration = _mergeCalibration(_calibration, newCalibration);
    // In a real app, you might save this to persistent storage
  }

  /// Reset to default calibration
  void resetToDefaults() {
    _calibration = Map.from(_defaultCalibration);
  }

  /// Get all calibration settings
  Map<String, dynamic> getAllSettings() => Map.from(_calibration);

  /// Merge two calibration maps
  Map<String, dynamic> _mergeCalibration(Map<String, dynamic> base, Map<String, dynamic> overlay) {
    final result = Map<String, dynamic>.from(base);

    overlay.forEach((key, value) {
      if (value is Map<String, dynamic> && result[key] is Map<String, dynamic>) {
        result[key] = _mergeCalibration(result[key], value);
      } else {
        result[key] = value;
      }
    });

    return result;
  }
}