import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:biophantom_core/biophantom_core.dart';

/// BLE host service for Mainframe app to receive votes from devices
class BluetoothHostService {
  final BluetoothMesh _bluetoothMesh = BluetoothMesh();
  final StreamController<DeviceVote> _votesController = StreamController<DeviceVote>.broadcast();
  final StreamController<BluetoothConnectionState> _connectionController = 
      StreamController<BluetoothConnectionState>.broadcast();

  bool _isInitialized = false;
  bool _isAdvertising = false;
  final Map<String, BluetoothDevice> _connectedDevices = {};

  /// Stream of incoming device votes
  Stream<DeviceVote> get votesStream => _votesController.stream;

  /// Stream of connection state changes
  Stream<BluetoothConnectionState> get connectionStream => _connectionController.stream;

  /// Check if advertising
  bool get isAdvertising => _isAdvertising;

  /// Get connected devices count
  int get connectedDevicesCount => _connectedDevices.length;

  /// Get connected device IDs
  List<String> get connectedDeviceIds => _connectedDevices.keys.toList();

  /// Initialize the BLE host
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _bluetoothMesh.initialize();
      
      // Listen to connection state changes
      _bluetoothMesh.connectionStream.listen((state) {
        _connectionController.add(state);
      });

      // Listen to device votes
      _bluetoothMesh.votesStream.listen((vote) {
        _votesController.add(vote);
      });

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Bluetooth host: $e');
    }
  }

  /// Start advertising as Mainframe
  Future<void> startAdvertising() async {
    if (!_isInitialized) {
      throw StateError('BluetoothHostService not initialized');
    }

    try {
      await _bluetoothMesh.startAdvertising();
      _isAdvertising = true;
    } catch (e) {
      throw Exception('Failed to start advertising: $e');
    }
  }

  /// Stop advertising
  Future<void> stopAdvertising() async {
    try {
      await _bluetoothMesh.stopAdvertising();
      _isAdvertising = false;
    } catch (e) {
      // Ignore errors when stopping
    }
  }

  /// Send room alert to all connected devices
  Future<void> broadcastRoomAlert(RoomAlert alert) async {
    if (!_isInitialized) {
      throw StateError('BluetoothHostService not initialized');
    }

    try {
      await _bluetoothMesh.sendAlert(alert);
    } catch (e) {
      throw Exception('Failed to broadcast room alert: $e');
    }
  }

  /// Check if Bluetooth is available
  Future<bool> isBluetoothAvailable() async {
    try {
      return await _bluetoothMesh.isBluetoothAvailable();
    } catch (e) {
      // BLE not supported on this device
      return false;
    }
  }

  /// Get current connection state
  BluetoothConnectionState get connectionState => _bluetoothMesh.connectionState;

  /// Dispose resources
  void dispose() {
    _votesController.close();
    _connectionController.close();
    _bluetoothMesh.dispose();
  }
}
