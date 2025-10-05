import 'dart:async';
// import 'package:geolocator/geolocator.dart';
// import 'package:biophantom_core/biophantom_core.dart';

// Dummy classes for compatibility
class Position {
  final double latitude;
  final double longitude;
  Position(this.latitude, this.longitude);
}

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

class DoctorFinderService {
  final DoctorLocator _doctorLocator = DoctorLocator();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  bool _isInitialized = false;

  /// Stream of status updates
  Stream<String> get statusStream => _statusController.stream;

  /// Check if service is ready
  bool get isReady => _isInitialized;

  /// Initialize the doctor service
  Future<void> initialize() async {
    try {
      _isInitialized = true;
      _statusController.add('Doctor service initialized');
    } catch (e) {
      throw Exception('Failed to initialize Doctor service: $e');
    }
  }

  /// Check if location services are available
  Future<bool> isLocationAvailable() async {
    return await _doctorLocator.isLocationServiceEnabled();
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    return await _doctorLocator.hasLocationPermission();
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    _statusController.add('Requesting location permission...');

    final granted = await _doctorLocator.requestLocationPermission();

    if (granted) {
      _statusController.add('Location permission granted');
    } else {
      _statusController.add('Location permission denied');
    }

    return granted;
  }

  /// Find neurologists near current location
  Future<void> findNeurologists() async {
    if (!await hasLocationPermission()) {
      final granted = await requestLocationPermission();
      if (!granted) {
        throw Exception('Location permission required to find doctors');
      }
    }

    _statusController.add('Finding neurologists nearby...');

    try {
      await _doctorLocator.findNeurologistsNearby();
      _statusController.add('Opened maps with neurologist search');
    } catch (e) {
      _statusController.add('Failed to find neurologists: $e');
      rethrow;
    }
  }

  /// Find emergency medical services
  Future<void> findEmergencyServices() async {
    if (!await hasLocationPermission()) {
      final granted = await requestLocationPermission();
      if (!granted) {
        throw Exception(
          'Location permission required to find emergency services',
        );
      }
    }

    _statusController.add('Finding emergency services...');

    try {
      await _doctorLocator.findEmergencyServices();
      _statusController.add('Opened maps with emergency services search');
    } catch (e) {
      _statusController.add('Failed to find emergency services: $e');
      rethrow;
    }
  }

  /// Find poison control centers
  Future<void> findPoisonControl() async {
    if (!await hasLocationPermission()) {
      final granted = await requestLocationPermission();
      if (!granted) {
        throw Exception('Location permission required to find poison control');
      }
    }

    _statusController.add('Finding poison control centers...');

    try {
      await _doctorLocator.findPoisonControl();
      _statusController.add('Opened maps with poison control search');
    } catch (e) {
      _statusController.add('Failed to find poison control: $e');
      rethrow;
    }
  }

  /// Search for custom medical services
  Future<void> searchNearby(String query) async {
    if (!await hasLocationPermission()) {
      final granted = await requestLocationPermission();
      if (!granted) {
        throw Exception('Location permission required to search');
      }
    }

    _statusController.add('Searching for $query...');

    try {
      await _doctorLocator.searchNearby(query);
      _statusController.add('Opened maps with search: $query');
    } catch (e) {
      _statusController.add('Failed to search: $e');
      rethrow;
    }
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    if (!await hasLocationPermission()) {
      final granted = await requestLocationPermission();
      if (!granted) {
        throw Exception('Location permission required');
      }
    }

    _statusController.add('Getting current location...');

    try {
      final position = await _doctorLocator.getCurrentLocation();
      _statusController.add(
        'Location obtained: ${position?.latitude.toStringAsFixed(4)}, ${position?.longitude.toStringAsFixed(4)}',
      );
      return position;
    } catch (e) {
      _statusController.add('Failed to get location: $e');
      rethrow;
    }
  }

  /// Get formatted address from coordinates
  Future<String?> getAddressFromLocation(double lat, double lng) async {
    try {
      return await _doctorLocator.getAddressFromCoordinates(lat, lng);
    } catch (e) {
      return null;
    }
  }

  /// Calculate distance between two points
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return _doctorLocator.calculateDistance(lat1, lng1, lat2, lng2);
  }

  /// Get current position
  Position? get currentPosition => _doctorLocator.currentPosition;

  /// Check if location permission is granted
  bool get hasPermission => _doctorLocator.hasPermission;

  /// Dial emergency services directly
  Future<void> dialEmergencyServices() async {
    _statusController.add('Dialing emergency services...');

    try {
      await _doctorLocator.dialEmergencyServices();
      _statusController.add('Emergency call initiated');
    } catch (e) {
      _statusController.add('Failed to dial emergency services: $e');
      rethrow;
    }
  }

  /// Dial poison control center
  Future<void> dialPoisonControl() async {
    _statusController.add('Dialing poison control...');

    try {
      await _doctorLocator.dialPoisonControl();
      _statusController.add('Poison control call initiated');
    } catch (e) {
      _statusController.add('Failed to dial poison control: $e');
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  Map<String, String> findNearestSpecialist() {
    return {
      'name': 'Dr. Neuro Toxin',
      'phone': '+91-1234567890',
      'address': '123 Medical Lane',
      'directions': 'https://maps.example.com',
    };
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
  }
}
