// Dummy biophantom_core package for compatibility

class DoctorLocator {
  bool hasPermission = true;
  Position? currentPosition;

  Future<bool> isLocationServiceEnabled() async => true;
  Future<bool> hasLocationPermission() async => true;
  Future<bool> requestLocationPermission() async => true;
  Future<void> findNeurologistsNearby() async {}
  Future<void> findEmergencyServices() async {}
  Future<void> findPoisonControl() async {}
  Future<void> searchNearby(String query) async {}
  Future<Position?> getCurrentLocation() async => Position(0, 0);
  Future<String?> getAddressFromCoordinates(double lat, double lng) async =>
      'Dummy Address';
  double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) => 0.0;
  Future<void> dialEmergencyServices() async {}
  Future<void> dialPoisonControl() async {}
}

class Position {
  final double latitude;
  final double longitude;
  Position(this.latitude, this.longitude);
}

// Add other dummy classes as needed
class ConsensusEngine {
  // Dummy
}

class NeurotoxinChatbot {
  // Dummy
}

class BluetoothHost {
  // Dummy
}
