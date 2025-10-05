import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ws_server.dart';
import 'ble_scanner.dart';
import 'aggregator.dart';

class ServerBridge {
  static WsServer? _wsServer;
  static BleScanner? _bleScanner;

  static Future<void> start() async {
    _wsServer = WsServer();
    await _wsServer!.start();

    _bleScanner = BleScanner(_wsServer!.aggregator);
    await _bleScanner!.start();
  }

  static Future<void> stop() async {
    await _wsServer?.stop();
    await _bleScanner?.stop();
  }

  // Bind to existing UI - since no specific state manager known, provide a stream
  static Stream<Map<String, RoomData>> get roomUpdates =>
      _wsServer?.aggregator.stream ?? Stream.empty();

  // For UI to subscribe without modifying existing files
  static ValueNotifier<Map<String, RoomData>> roomNotifier = ValueNotifier({});

  static void bindToExistingUi() {
    // Attach listener to update the notifier
    _wsServer?.aggregator.stream.listen((rooms) {
      roomNotifier.value = rooms;
    });
  }
}
