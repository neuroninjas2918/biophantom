import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class FusionConfig {
  final double motionWeight, audioWeight, riskThreshold;
  final double vibThreshold, audThreshold;
  final int vibT, audT, channels, smoothWindow;
  final double gateMicAt;

  FusionConfig({
    required this.motionWeight,
    required this.audioWeight,
    required this.riskThreshold,
    required this.vibThreshold,
    required this.audThreshold,
    required this.vibT,
    required this.audT,
    required this.channels,
    required this.smoothWindow,
    required this.gateMicAt,
  });

  static Future<FusionConfig> load() async {
    final s = await rootBundle.loadString('assets/models/fusion_config.json');
    final j = jsonDecode(s) as Map<String, dynamic>;
    // Extract values from the new JSON structure
    double motionWeight = (j['motionWeight'] ?? 0.7).toDouble();
    double audioWeight = (j['audioWeight'] ?? 0.3).toDouble();
    double riskThreshold = (j['riskThreshold'] ?? 0.6).toDouble();

    // Load thresholds from txt files
    final vibThrStr = await rootBundle.loadString(
      'assets/models/motion_threshold.txt',
    );
    double vibThreshold = double.parse(vibThrStr.trim());
    final audThrStr = await rootBundle.loadString(
      'assets/models/audio_threshold.txt',
    );
    double audThreshold = double.parse(audThrStr.trim());

    // Default values for other parameters (assuming fixed for new model)
    int vibT = 40;
    int audT = 40;
    int channels = 2;
    int smoothWindow = 3;
    double gateMicAt = 0.9;

    return FusionConfig(
      motionWeight: motionWeight,
      audioWeight: audioWeight,
      riskThreshold: riskThreshold,
      vibThreshold: vibThreshold,
      audThreshold: audThreshold,
      vibT: vibT,
      audT: audT,
      channels: channels,
      smoothWindow: smoothWindow,
      gateMicAt: gateMicAt,
    );
  }
}
