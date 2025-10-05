class WearableIntegrationService {
  // Stub for wearable sensor input
  Map<String, dynamic> getLatestData() {
    return {
      'heartRate': 72,
      'motion': [0.1, 0.2, 0.3],
      'timestamp': DateTime.now().toString(),
    };
  }
}
