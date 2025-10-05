import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'fusion_config.dart';
import 'tflite_runner.dart';
import 'neurotoxin_detector.dart';
import '../logic/detector_logic.dart';

class FusionDecision {
  final double motionProb;
  final double? audioProb;
  final Decision decision;

  FusionDecision({
    required this.motionProb,
    required this.audioProb,
    required this.decision,
  });
}

class FusionEngine {
  Future<FusionDecision> runDetection() async {
    // Load configuration
    final config = await FusionConfig.load();

    // For now, use placeholder probabilities - in real implementation,
    // this would run the motion and audio models with sensor data
    final motionProb = 0.0; // Placeholder
    double? audioProb;

    Decision decision = Decision.safe;

    // If gating is enabled, run audio model
    if (config.gateMicAt > 0 && motionProb >= config.gateMicAt) {
      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      if (micStatus.isGranted) {
        // TODO: Run audio model for a short cough window
        // For now, we'll use a placeholder
        audioProb = 0.0; // Placeholder
      }
    }

    // Run neurotoxin detection
    final neurotoxinDetector = NeurotoxinDetector();
    final neurotoxinResult = await neurotoxinDetector.detectFromSampleData();

    // If neurotoxins detected, override decision to alert
    if (neurotoxinResult.isPositive) {
      decision = Decision.alert; // NEUROTOXIN ALERT
    } else {
      // Compute fused probability using new weighted fusion
      final fusedProb =
          config.motionWeight * motionProb +
          config.audioWeight * (audioProb ?? 0.0);

      if (fusedProb >= config.riskThreshold) {
        decision = Decision.alert; // HIGH RISK
      } else if (fusedProb >= config.riskThreshold * 0.7) {
        decision = Decision.warning; // MODERATE RISK
      } else {
        decision = Decision.safe;
      }
    }

    return FusionDecision(
      motionProb: motionProb,
      audioProb: audioProb,
      decision: decision,
    );
  }
}
