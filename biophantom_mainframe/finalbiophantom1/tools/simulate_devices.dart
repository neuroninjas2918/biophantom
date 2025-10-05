import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:protocol/protocol.dart';

void main() async {
  print('Starting device simulation...');

  // Simulate 3 devices
  final devices = [
    {'id': 'dev1', 'room': 'room1'},
    {'id': 'dev2', 'room': 'room1'},
    {'id': 'dev3', 'room': 'room2'},
  ];

  final channels = <WebSocketChannel>[];

  for (final dev in devices) {
    final channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.1.9:8765/ws'),
    );
    await channel.ready;
    channels.add(channel);

    // Send heartbeat every 10s
    Timer.periodic(const Duration(seconds: 10), (_) {
      final heartbeat = Heartbeat(
        deviceId: dev['id']!,
        roomId: dev['room']!,
        ts: DateTime.now().millisecondsSinceEpoch,
        lastRisk: 0.0,
      );
      channel.sink.add(jsonEncode(heartbeat.toJson()));
    });
  }

  // Simulate alerts
  Timer(const Duration(seconds: 5), () {
    // Device 1 sends high risk
    final event1 = RiskEvent(
      deviceId: 'dev1',
      roomId: 'room1',
      fusedRisk: 0.95,
      motion: 0.9,
      audio: 0.8,
      ts: DateTime.now().millisecondsSinceEpoch,
      appVer: '1.0.0',
    );
    channels[0].sink.add(jsonEncode(event1.toJson()));
    print('Sent high risk from dev1');
  });

  Timer(const Duration(seconds: 10), () {
    // Device 2 sends high risk
    final event2 = RiskEvent(
      deviceId: 'dev2',
      roomId: 'room1',
      fusedRisk: 0.92,
      motion: 0.85,
      audio: 0.7,
      ts: DateTime.now().millisecondsSinceEpoch,
      appVer: '1.0.0',
    );
    channels[1].sink.add(jsonEncode(event2.toJson()));
    print('Sent high risk from dev2');
  });

  // Listen for responses
  for (final channel in channels) {
    channel.stream.listen((message) {
      print('Received: $message');
    });
  }

  // Keep running
  await Future.delayed(const Duration(minutes: 1));
  for (final channel in channels) {
    channel.sink.close();
  }
}
