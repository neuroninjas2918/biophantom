import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:protocol/protocol.dart';

class DeviceData {
  double risk;
  int ts;
  DeviceData(this.risk, this.ts);
}

class RoomData {
  Map<String, DeviceData> devices = {};
  double roomRisk = 0.0;
  double peakRisk = 0.0;
  bool isSealed = false;
  int lastUpdate = 0;

  void updateRisk() {
    if (devices.isEmpty) {
      roomRisk = 0.0;
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final maxDeviceRisk = devices.values
        .map((d) => d.risk)
        .reduce((a, b) => a > b ? a : b);

    // EMA with α=0.4
    roomRisk = 0.4 * maxDeviceRisk + 0.6 * roomRisk;

    // Peak hold 20s
    if (roomRisk > peakRisk) {
      peakRisk = roomRisk;
    } else if (now - lastUpdate > 20000) {
      peakRisk = roomRisk;
    }

    lastUpdate = now;

    // Sealing logic
    final highRiskDevices = devices.values.where((d) => d.risk >= 0.9).length;
    if (roomRisk >= 0.90 && highRiskDevices >= 2 && !isSealed) {
      isSealed = true;
      _persistSealed();
      _triggerSealActions();
    }
  }

  void _persistSealed() {
    final file = File('data/rooms.json');
    file.parent.createSync(recursive: true);
    final data = {'sealed': true, 'ts': DateTime.now().millisecondsSinceEpoch};
    file.writeAsStringSync(jsonEncode(data));

    // Log event
    final logFile = File('data/events.log');
    final logEntry = '${DateTime.now().toIso8601String()}: Room sealed\n';
    logFile.writeAsStringSync(logEntry, mode: FileMode.append);
  }

  void _triggerSealActions() {
    // Display alert and notify
    print('Room sealed! Triggering actions...');
    // TODO: UI alert, BLE notifications
  }
}

class Aggregator {
  final Map<String, RoomData> _rooms = {};
  final StreamController<Map<String, RoomData>> _controller =
      StreamController.broadcast();

  Stream<Map<String, RoomData>> get stream => _controller.stream;

  void handleRiskEvent(RiskEvent event) {
    final room = _rooms.putIfAbsent(event.roomId, () => RoomData());
    room.devices[event.deviceId] = DeviceData(event.fusedRisk, event.ts);
    room.updateRisk();
    _controller.add(_rooms);
  }

  void handleHeartbeat(Heartbeat heartbeat) {
    final room = _rooms.putIfAbsent(heartbeat.roomId, () => RoomData());
    room.devices[heartbeat.deviceId] = DeviceData(
      heartbeat.lastRisk,
      heartbeat.ts,
    );
    room.updateRisk();
    _controller.add(_rooms);
  }

  Map<String, RoomData> get rooms => _rooms;
}
