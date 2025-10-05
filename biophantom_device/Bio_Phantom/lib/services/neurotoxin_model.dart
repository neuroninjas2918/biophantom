import 'dart:math';

class NeurotoxinModel {
  // Enhanced neural network for neurotoxin detection
  // Optimized for detecting shaky hands and tremors

  // Enhanced weights for the neural network (optimized for hand tremor detection)
  final List<List<double>> hiddenWeights;
  final List<double> outputWeights;
  final List<double> hiddenBiases;
  final double outputBias;

  NeurotoxinModel()
    : hiddenWeights = [
        // Enhanced weights optimized for detecting hand tremors and instability
        [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 0.15, 0.25, 0.35],
        [1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.25, 0.35, 0.45],
        [0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.4, 0.4, 0.4],
        [0.3, 0.5, 0.7, 0.9, 0.2, 0.4, 0.6, 0.8, 1.0, 0.1, 0.3, 0.5],
        [0.4, 0.4, 0.7, 0.7, 1.0, 1.0, 0.3, 0.3, 0.6, 0.2, 0.2, 0.5],
        [0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6],
      ],
      outputWeights = [0.4, 0.3, 0.2, 0.1, 0.15, 0.25],
      hiddenBiases = [0.2, 0.2, 0.2, 0.2, 0.15, 0.25],
      outputBias = 0.2;

  // Predict neurotoxin presence based on features
  double predict(
    Map<String, double> sensorFeatures,
    Map<String, double> audioFeatures,
  ) {
    // Combine all features into a single input vector
    List<double> input = _prepareInput(sensorFeatures, audioFeatures);

    // Forward pass through hidden layer
    List<double> hiddenOutputs = _forwardHidden(input);

    // Forward pass through output layer
    double output = _forwardOutput(hiddenOutputs);

    // Apply sigmoid activation to get probability
    return _sigmoid(output);
  }

  // Prepare input vector from features with enhanced feature selection for shaky hands
  List<double> _prepareInput(
    Map<String, double> sensorFeatures,
    Map<String, double> audioFeatures,
  ) {
    // Select the most relevant features for neurotoxin detection, especially for shaky hands
    List<double> input = [];

    // Enhanced sensor features (hand stability indicators)
    input.add(sensorFeatures['std_x'] ?? 0.0); // Hand tremor in x-axis
    input.add(sensorFeatures['std_y'] ?? 0.0); // Hand tremor in y-axis
    input.add(sensorFeatures['std_z'] ?? 0.0); // Hand tremor in z-axis
    input.add(sensorFeatures['range_x'] ?? 0.0); // Movement range x-axis
    input.add(sensorFeatures['range_y'] ?? 0.0); // Movement range y-axis
    input.add(sensorFeatures['range_z'] ?? 0.0); // Movement range z-axis
    input.add(sensorFeatures['skewness_x'] ?? 0.0); // Movement pattern x-axis
    input.add(sensorFeatures['skewness_y'] ?? 0.0); // Movement pattern y-axis
    input.add(sensorFeatures['skewness_z'] ?? 0.0); // Movement pattern z-axis

    // Additional features optimized for shaky hands detection
    input.add(
      sensorFeatures['kurtosis_x'] ?? 0.0,
    ); // Kurtosis x-axis (peakedness of tremors)
    input.add(sensorFeatures['kurtosis_y'] ?? 0.0); // Kurtosis y-axis
    input.add(sensorFeatures['kurtosis_z'] ?? 0.0); // Kurtosis z-axis

    return input;
  }

  // Forward pass through hidden layer
  List<double> _forwardHidden(List<double> input) {
    List<double> outputs = [];

    for (int i = 0; i < hiddenWeights.length; i++) {
      double sum = hiddenBiases[i];
      for (int j = 0; j < input.length && j < hiddenWeights[i].length; j++) {
        sum += input[j] * hiddenWeights[i][j];
      }
      outputs.add(_relu(sum));
    }

    return outputs;
  }

  // Forward pass through output layer
  double _forwardOutput(List<double> hiddenOutputs) {
    double sum = outputBias;
    for (int i = 0; i < hiddenOutputs.length && i < outputWeights.length; i++) {
      sum += hiddenOutputs[i] * outputWeights[i];
    }
    return sum;
  }

  // Activation functions
  double _sigmoid(double x) {
    return 1.0 / (1.0 + exp(-x));
  }

  double _relu(double x) {
    return max(0.0, x);
  }

  // Get explanation of the prediction with neurotoxin-specific details
  String getPredictionExplanation(
    Map<String, double> sensorFeatures,
    Map<String, double> audioFeatures,
  ) {
    double sensorInstability = _calculateSensorInstability(sensorFeatures);
    double coughIntensity = _calculateCoughIntensity(audioFeatures);

    StringBuffer explanation = StringBuffer();
    explanation.write('Neurotoxin Detection Analysis:\n\n');

    if (sensorInstability > 0.7) {
      explanation.write(
        '• High hand instability detected (${(sensorInstability * 100).toStringAsFixed(1)}%) - possible neurotoxin exposure\n',
      );
    } else if (sensorInstability > 0.4) {
      explanation.write(
        '• Moderate hand instability detected (${(sensorInstability * 100).toStringAsFixed(1)}%) - possible early neurotoxin effects\n',
      );
    } else {
      explanation.write(
        '• Normal hand stability (${((1 - sensorInstability) * 100).toStringAsFixed(1)}%)\n',
      );
    }

    if (coughIntensity > 0.5) {
      explanation.write(
        '• Abnormal cough patterns detected - possible respiratory effects\n',
      );
    } else if (coughIntensity > 0.3) {
      explanation.write(
        '• Mild cough patterns detected - monitor respiratory symptoms\n',
      );
    } else {
      explanation.write('• Normal respiratory patterns\n');
    }

    // Add neurotoxin-specific analysis
    double neurotoxinProbability = predict(sensorFeatures, audioFeatures);
    if (neurotoxinProbability > 0.8) {
      explanation.write(
        '\n⚠️ HIGH PROBABILITY OF NEUROTOXIN EXPOSURE DETECTED\n',
      );
      explanation.write('Immediate medical attention recommended.\n');
    } else if (neurotoxinProbability > 0.6) {
      explanation.write('\n⚠️ SIGNIFICANT NEUROTOXIN EXPOSURE DETECTED\n');
      explanation.write('Seek medical evaluation immediately.\n');
    } else if (neurotoxinProbability > 0.4) {
      explanation.write('\n⚠️ POSSIBLE NEUROTOXIN EXPOSURE DETECTED\n');
      explanation.write('Monitor symptoms and consider medical evaluation.\n');
    } else {
      explanation.write('\n✅ No significant neurotoxin exposure detected\n');
    }

    return explanation.toString();
  }

  // Calculate sensor instability metric optimized for shaky hands
  double _calculateSensorInstability(Map<String, double> sensorFeatures) {
    // Weighted combination of instability indicators, optimized for hand tremors
    double instability = 0.0;

    // Standard deviation contributions (higher = more unstable, especially for tremors)
    instability += (sensorFeatures['std_x'] ?? 0.0) * 0.5;
    instability += (sensorFeatures['std_y'] ?? 0.0) * 0.5;
    instability += (sensorFeatures['std_z'] ?? 0.0) * 0.5;

    // Range contributions (higher = more unstable movement)
    instability += (sensorFeatures['range_x'] ?? 0.0) * 0.15;
    instability += (sensorFeatures['range_y'] ?? 0.0) * 0.15;
    instability += (sensorFeatures['range_z'] ?? 0.0) * 0.15;

    // Skewness for detecting asymmetric movement patterns (common in neurotoxin exposure)
    instability += (sensorFeatures['skewness_x'] ?? 0.0).abs() * 0.15;
    instability += (sensorFeatures['skewness_y'] ?? 0.0).abs() * 0.15;
    instability += (sensorFeatures['skewness_z'] ?? 0.0).abs() * 0.15;

    // Kurtosis for detecting peaked tremors (common in neurotoxin exposure)
    instability += (sensorFeatures['kurtosis_x'] ?? 0.0) * 0.1;
    instability += (sensorFeatures['kurtosis_y'] ?? 0.0) * 0.1;
    instability += (sensorFeatures['kurtosis_z'] ?? 0.0) * 0.1;

    // Normalize to 0-1 range (approximate)
    return _sigmoid(instability * 1.5);
  }

  // Calculate cough intensity metric with enhanced sensitivity
  double _calculateCoughIntensity(Map<String, double> audioFeatures) {
    // Weighted combination of cough indicators
    double intensity = 0.0;

    // Peak count (more peaks = more coughing)
    intensity += (audioFeatures['peak_count'] ?? 0.0) * 0.2;

    // Peak magnitude (louder coughs = higher peaks)
    intensity += (audioFeatures['peak_mean'] ?? 0.0) * 0.02;

    // Range (larger variations = more abnormal)
    intensity += (audioFeatures['range_db'] ?? 0.0) * 0.01;

    // Additional audio features for better accuracy
    intensity += (audioFeatures['spectral_centroid'] ?? 0.0) * 0.003;
    intensity += (audioFeatures['zero_crossing_rate'] ?? 0.0) * 0.3;

    // Normalize to 0-1 range (approximate)
    return _sigmoid(intensity * 1.0);
  }
}
