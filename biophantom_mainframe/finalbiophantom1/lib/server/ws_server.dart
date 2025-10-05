import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:protocol/protocol.dart';
import 'aggregator.dart';

class WsServer {
  HttpServer? _server;
  final Aggregator _aggregator = Aggregator();

  Future<void> start() async {
    final handler = webSocketHandler((webSocket) {
      print('WebSocket connection established from client');
      webSocket.stream.listen((message) {
        _handleMessage(message, webSocket);
      });
    });

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8765);
    print('WebSocket server listening on ws://0.0.0.0:8765');
  }

  void _handleMessage(dynamic message, WebSocketChannel webSocket) {
    try {
      final data = jsonDecode(message);
      if (data is Map<String, dynamic>) {
        if (data.containsKey('fusedRisk')) {
          // RiskEvent
          final event = RiskEvent.fromJson(data);
          _aggregator.handleRiskEvent(event);
        } else if (data.containsKey('lastRisk')) {
          // Heartbeat
          final heartbeat = Heartbeat.fromJson(data);
          _aggregator.handleHeartbeat(heartbeat);
        }
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  Future<void> stop() async {
    await _server?.close();
  }

  Aggregator get aggregator => _aggregator;
}
