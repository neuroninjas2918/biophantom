import 'package:protocol/protocol.dart';

class BleAdvertiserStub {
  bool _enabled = false; // Default disabled

  Future<void> start() async {
    if (!_enabled) return;
    // TODO: Implement BLE advertising if flutter_ble_peripheral is available
    print('BLE advertiser stub started (disabled)');
  }

  Future<void> advertiseRisk(RiskEvent event) async {
    if (!_enabled) return;
    // Encode and advertise
    print('BLE advertise risk: ${event.fusedRisk}');
  }

  Future<void> stop() async {
    // Stop advertising
  }
}
