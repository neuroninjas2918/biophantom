import 'dart:convert';

class RiskEvent {
  final String deviceId;
  final String roomId;
  final double fusedRisk;
  final double motion;
  final double audio;
  final int ts;
  final String appVer;

  RiskEvent({
    required this.deviceId,
    required this.roomId,
    required this.fusedRisk,
    required this.motion,
    required this.audio,
    required this.ts,
    required this.appVer,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'roomId': roomId,
    'fusedRisk': fusedRisk,
    'motion': motion,
    'audio': audio,
    'ts': ts,
    'appVer': appVer,
  };

  static RiskEvent fromJson(Map<String, dynamic> json) => RiskEvent(
    deviceId: json['deviceId'],
    roomId: json['roomId'],
    fusedRisk: json['fusedRisk'],
    motion: json['motion'],
    audio: json['audio'],
    ts: json['ts'],
    appVer: json['appVer'],
  );
}

class Heartbeat {
  final String deviceId;
  final String roomId;
  final int ts;
  final double lastRisk;

  Heartbeat({
    required this.deviceId,
    required this.roomId,
    required this.ts,
    required this.lastRisk,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'roomId': roomId,
    'ts': ts,
    'lastRisk': lastRisk,
  };

  static Heartbeat fromJson(Map<String, dynamic> json) => Heartbeat(
    deviceId: json['deviceId'],
    roomId: json['roomId'],
    ts: json['ts'],
    lastRisk: json['lastRisk'],
  );
}

int crc16(String s) {
  const int poly = 0x1021;
  int crc = 0xFFFF;
  for (int byte in utf8.encode(s)) {
    crc ^= (byte << 8);
    for (int i = 0; i < 8; i++) {
      if ((crc & 0x8000) != 0) {
        crc = (crc << 1) ^ poly;
      } else {
        crc <<= 1;
      }
    }
  }
  return crc & 0xFFFF;
}
