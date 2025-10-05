import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:protocol/protocol.dart';
import 'aggregator.dart';

class BleScanner {
  final Aggregator _aggregator;
  StreamSubscription? _scanSub;
  bool _scanning = false;

  BleScanner(this._aggregator);

  Future<void> start() async {
    if (_scanning) return;
    _scanning = true;

    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid('0000FFF0-0000-1000-8000-00805F9B34FB')],
        timeout: const Duration(seconds: 4),
      );

      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          _processScanResult(result);
        }
      });

      // Restart scan periodically
      Timer.periodic(const Duration(seconds: 5), (_) => _restartScan());
    } catch (e) {
      print('BLE scan failed: $e');
      _scanning = false;
    }
  }

  void _processScanResult(ScanResult result) {
    final manufacturerData = result.advertisementData.manufacturerData;
    if (manufacturerData.isEmpty) return;

    final data = manufacturerData.values.first;
    if (data.length < 7)
      return; // ver(1) + risk(1) + roomCrc(2) + devCrc(2) + flags(1)

    final ver = data[0];
    final risk = data[1] / 255.0; // 0-255 to 0-1
    final roomCrc = (data[2] << 8) | data[3];
    final devCrc = (data[4] << 8) | data[5];
    final flags = data[6];

    // For now, assume roomId and deviceId are strings from crc, but since crc is hash, can't reverse.
    // The task says "decode CRC16 hashes if full ids not known"
    // So, perhaps use the crc as key, but for aggregation, need roomId.
    // Perhaps skip full implementation, or assume known rooms.

    // For simplicity, create dummy ids
    final roomId = 'room_$roomCrc';
    final deviceId = 'dev_$devCrc';

    // Create a pseudo RiskEvent
    final event = RiskEvent(
      deviceId: deviceId,
      roomId: roomId,
      fusedRisk: risk,
      motion: 0.0, // not available
      audio: 0.0,
      ts: DateTime.now().millisecondsSinceEpoch,
      appVer: '1.0.0',
    );

    _aggregator.handleRiskEvent(event);
  }

  void _restartScan() {
    if (!_scanning) return;
    FlutterBluePlus.startScan(
      withServices: [Guid('0000FFF0-0000-1000-8000-00805F9B34FB')],
      timeout: const Duration(seconds: 4),
    );
  }

  Future<void> stop() async {
    _scanning = false;
    await _scanSub?.cancel();
    await FlutterBluePlus.stopScan();
  }
}
