import 'dart:io';
import 'neurotoxin_model.dart';
import 'data_processor.dart';
import 'feature_extractor.dart';

class NeurotoxinResult {
  final double probability;
  final String explanation;
  final Map<String, double> sensorFeatures;
  final Map<String, double> audioFeatures;

  NeurotoxinResult({
    required this.probability,
    required this.explanation,
    required this.sensorFeatures,
    required this.audioFeatures,
  });

  bool get isPositive => probability > 0.5;
}

class NeurotoxinDetector {
  final NeurotoxinModel _model = NeurotoxinModel();

  // Detect neurotoxins based on sensor and audio data
  Future<NeurotoxinResult> detect({
    required String sensorFilePath,
    required String audioFilePath,
  }) async {
    try {
      // Process sensor data
      List<List<double>> sensorData = await DataProcessor.processSensorCSV(
        sensorFilePath,
      );
      if (sensorData.isEmpty) {
        throw Exception('Failed to process sensor data');
      }

      // Process audio data
      List<double> audioData = await DataProcessor.processAudioCSV(
        audioFilePath,
      );
      if (audioData.isEmpty) {
        throw Exception('Failed to process audio data');
      }

      // Extract features
      Map<String, double> sensorFeatures =
          FeatureExtractor.extractSensorFeatures(sensorData);
      Map<String, double> audioFeatures = FeatureExtractor.extractAudioFeatures(
        audioData,
      );

      // Make prediction
      double probability = _model.predict(sensorFeatures, audioFeatures);
      String explanation = _model.getPredictionExplanation(
        sensorFeatures,
        audioFeatures,
      );

      return NeurotoxinResult(
        probability: probability,
        explanation: explanation,
        sensorFeatures: sensorFeatures,
        audioFeatures: audioFeatures,
      );
    } catch (e) {
      throw Exception('Neurotoxin detection failed: $e');
    }
  }

  // Enhanced detection method using real-time sensor data
  Future<NeurotoxinResult> detectFromSensorData({
    required List<List<double>> sensorData,
    required List<double> audioData,
  }) async {
    try {
      // Extract features
      Map<String, double> sensorFeatures =
          FeatureExtractor.extractSensorFeatures(sensorData);
      Map<String, double> audioFeatures = FeatureExtractor.extractAudioFeatures(
        audioData,
      );

      // Make prediction
      double probability = _model.predict(sensorFeatures, audioFeatures);
      String explanation = _model.getPredictionExplanation(
        sensorFeatures,
        audioFeatures,
      );

      return NeurotoxinResult(
        probability: probability,
        explanation: explanation,
        sensorFeatures: sensorFeatures,
        audioFeatures: audioFeatures,
      );
    } catch (e) {
      throw Exception('Neurotoxin detection failed: $e');
    }
  }

  // Quick test method for demonstration with enhanced sample data for shaky hands
  Future<NeurotoxinResult> detectFromSampleData() async {
    // Create sample sensor data simulating shaky hands due to neurotoxin exposure
    // This data represents the irregular, tremoring movements characteristic of neurotoxin exposure
    List<List<double>> sampleSensorData = [
      [0.9, -0.6, 1.3], // Unstable hand movement with tremor
      [-0.7, 0.4, -1.0], // Erratic shaking
      [1.2, -0.8, 1.5], // Severe instability and tremor
      [-1.3, 0.7, -1.2], // Uncontrolled shaking
      [1.0, -0.5, 1.1], // Continued tremors
      [-0.9, 0.6, -1.4], // Uncontrolled shaking with high amplitude
      [1.4, -1.0, 1.7], // Extreme instability and tremor
      [-1.1, 0.8, -1.5], // Severe tremors
      [0.8, -0.7, 1.2], // Unstable hand movement
      [-0.6, 0.5, -0.9], // Tremoring movements
      [1.1, -0.9, 1.4], // Severe instability
      [-1.0, 0.7, -1.1], // Erratic shaking
    ];

    // Create sample audio data simulating coughing due to neurotoxin exposure
    // This represents the respiratory effects that often accompany neurotoxin exposure
    List<double> sampleAudioData = [
      45.0, // Baseline
      48.0, // Slight increase
      52.0, // Normal speech
      85.0, // Cough onset
      95.0, // Strong cough
      92.0, // Cough peak
      88.0, // Cough decrease
      82.0, // Recovery
      75.0, // Continuing recovery
      60.0, // Near baseline
      55.0, // Baseline recovery
      50.0, // Stable
      48.0, // Stable
      90.0, // Another cough episode
      98.0, // Severe cough
      95.0, // Cough peak
      90.0, // Decreasing
      85.0, // Recovery
      78.0, // Continuing recovery
      65.0, // Near baseline
      50.0, // Return to baseline
      88.0, // New cough episode
      92.0, // Cough peak
      85.0, // Decreasing
      75.0, // Recovery
    ];

    // Extract features
    Map<String, double> sensorFeatures = FeatureExtractor.extractSensorFeatures(
      sampleSensorData,
    );
    Map<String, double> audioFeatures = FeatureExtractor.extractAudioFeatures(
      sampleAudioData,
    );

    // Make prediction
    double probability = _model.predict(sensorFeatures, audioFeatures);
    String explanation = _model.getPredictionExplanation(
      sensorFeatures,
      audioFeatures,
    );

    return NeurotoxinResult(
      probability: probability,
      explanation: explanation,
      sensorFeatures: sensorFeatures,
      audioFeatures: audioFeatures,
    );
  }
}
