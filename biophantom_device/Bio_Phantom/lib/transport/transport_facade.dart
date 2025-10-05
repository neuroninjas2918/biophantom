import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:protocol/protocol.dart';
import 'ws_client.dart';
import 'ble_advertiser_stub.dart';

class TransportFacade {
  static TransportFacade? _instance;
  static TransportFacade get instance => _instance ??= TransportFacade._();

  TransportFacade._();

  WsClient? _wsClient;
  BleAdvertiserStub? _bleAdvertiser;
  Timer? _heartbeatTimer;
  String? _deviceId;
  String? _roomId;
  double _lastRisk = 0.0;

  Future<void> start() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = 'unknown';
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? 'unknown';
    }
    _deviceId = deviceId;
    final prefs = await SharedPreferences.getInstance();
    _roomId = prefs.getString('roomId') ?? 'default';

    _wsClient = WsClient();
    await _wsClient!.connect();

    // BLE advertiser optional
    _bleAdvertiser = BleAdvertiserStub();
    await _bleAdvertiser!.start();

    // Start heartbeat
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _sendHeartbeat(),
    );
  }

  Future<void> sendRisk(RiskEvent event) async {
    _lastRisk = event.fusedRisk;
    await _wsClient?.sendRisk(event);
    await _bleAdvertiser?.advertiseRisk(event);
  }

  Future<void> _sendHeartbeat() async {
    if (_deviceId == null || _roomId == null) return;
    final heartbeat = Heartbeat(
      deviceId: _deviceId!,
      roomId: _roomId!,
      ts: DateTime.now().millisecondsSinceEpoch,
      lastRisk: _lastRisk,
    );
    await _wsClient?.sendHeartbeat(heartbeat);
  }

  Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    await _wsClient?.disconnect();
    await _bleAdvertiser?.stop();
  }

  String? get deviceId => _deviceId;
  String? get roomId => _roomId;
}
