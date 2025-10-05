import 'package:flutter/material.dart';

class CommunityAlertService extends ChangeNotifier {
  // Singleton instance for app-wide alerts
  static final CommunityAlertService instance = CommunityAlertService._internal();
  CommunityAlertService._internal();
  factory CommunityAlertService() => instance;

  // Simulate a list of detected users with neurotoxin risk
  final List<String> detectedUsers = [];

  // Threshold for closing area (e.g., 3 users)
  final int closureThreshold = 3;

  // Add a detected user
  void addDetectedUser(String userId) {
    detectedUsers.add(userId);
    notifyListeners();
  }

  // Clear all detections (area safe again)
  void clearDetections() {
    detectedUsers.clear();
    notifyListeners();
  }

  // Any alert present
  bool get hasAlert => detectedUsers.isNotEmpty;

  // Check if area should be closed
  bool shouldCloseArea() {
    return detectedUsers.length >= closureThreshold;
  }

  // Get alert message
  String getAlertMessage() {
    if (shouldCloseArea()) {
      return 'Area closed: Multiple neurotoxin risks detected!';
    } else if (detectedUsers.isNotEmpty) {
      return 'Warning: ${detectedUsers.length} user(s) at risk.';
    }
    return 'Area safe.';
  }
}
