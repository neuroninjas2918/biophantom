import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:protocol/protocol.dart';

class WsClient {
  WebSocketChannel? _channel;
  String? _mainframeIp;
  bool _connected = false;
  final List<String> _queue = [];
  Timer? _reconnectTimer;

  Future<void> connect() async {
    _mainframeIp = await _discoverMainframeIp();
    if (_mainframeIp == null) {
      print('No mainframe IP found, operating offline');
      return;
    }

    try {
      final uri = Uri.parse('ws://$_mainframeIp:8765/ws');
      print('Attempting to connect to $uri');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _connected = true;
      print('Connected to mainframe at $_mainframeIp');

      // Send queued messages
      for (final msg in _queue) {
        _channel!.sink.add(msg);
      }
      _queue.clear();

      _channel!.stream.listen(
        (message) {
          // Handle incoming messages if needed
          print('Received: $message');
        },
        onDone: () {
          _connected = false;
          _scheduleReconnect();
        },
        onError: (error) {
          _connected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      print('Failed to connect: $e');
      _scheduleReconnect();
    }
  }

  Future<String?> _discoverMainframeIp() async {
    // Hardcoded for testing - both apps on same device
    return '127.0.0.1';
  }

  Future<void> sendRisk(RiskEvent event) async {
    final msg = jsonEncode(event.toJson());
    if (_connected && _channel != null) {
      _channel!.sink.add(msg);
    } else {
      _queue.add(msg);
      // Save to disk if needed
    }
  }

  Future<void> sendHeartbeat(Heartbeat heartbeat) async {
    final msg = jsonEncode(heartbeat.toJson());
    if (_connected && _channel != null) {
      _channel!.sink.add(msg);
    } else {
      // Queue or save
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), connect);
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    _connected = false;
  }
}
