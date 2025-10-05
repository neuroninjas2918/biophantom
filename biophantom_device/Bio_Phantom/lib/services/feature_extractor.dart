import 'dart:math';

class FeatureExtractor {
  // Extract features from sensor data (accelerometer readings) with enhanced features for neurotoxin detection
  // Optimized for detecting shaky hands and tremors
  static Map<String, double> extractSensorFeatures(List<List<double>> data) {
    if (data.isEmpty) return {};

    // Separate x, y, z axes data
    List<double> x = data.map((row) => row[0]).toList();
    List<double> y = data.map((row) => row[1]).toList();
    List<double> z = data.map((row) => row[2]).toList();

    // Statistical features for each axis
    Map<String, double> features = {};

    // Mean
    features['mean_x'] = _mean(x);
    features['mean_y'] = _mean(y);
    features['mean_z'] = _mean(z);

    // Standard deviation - crucial for detecting tremors
    features['std_x'] = _std(x, features['mean_x']!);
    features['std_y'] = _std(y, features['mean_y']!);
    features['std_z'] = _std(z, features['mean_z']!);

    // Root Mean Square
    features['rms_x'] = _rms(x);
    features['rms_y'] = _rms(y);
    features['rms_z'] = _rms(z);

    // Min and Max
    features['min_x'] = x.reduce(min);
    features['min_y'] = y.reduce(min);
    features['min_z'] = z.reduce(min);
    features['max_x'] = x.reduce(max);
    features['max_y'] = y.reduce(max);
    features['max_z'] = z.reduce(max);

    // Range
    features['range_x'] = features['max_x']! - features['min_x']!;
    features['range_y'] = features['max_y']! - features['min_y']!;
    features['range_z'] = features['max_z']! - features['min_z']!;

    // Skewness - important for detecting asymmetric movement patterns
    features['skewness_x'] = _skewness(
      x,
      features['mean_x']!,
      features['std_x']!,
    );
    features['skewness_y'] = _skewness(
      y,
      features['mean_y']!,
      features['std_y']!,
    );
    features['skewness_z'] = _skewness(
      z,
      features['mean_z']!,
      features['std_z']!,
    );

    // Kurtosis - crucial for detecting peaked tremors
    features['kurtosis_x'] = _kurtosis(
      x,
      features['mean_x']!,
      features['std_x']!,
    );
    features['kurtosis_y'] = _kurtosis(
      y,
      features['mean_y']!,
      features['std_y']!,
    );
    features['kurtosis_z'] = _kurtosis(
      z,
      features['mean_z']!,
      features['std_z']!,
    );

    // Additional features optimized for shaky hands detection
    // Zero crossing rate - useful for detecting tremor frequency
    features['zero_crossing_rate_x'] = _zeroCrossingRate(x);
    features['zero_crossing_rate_y'] = _zeroCrossingRate(y);
    features['zero_crossing_rate_z'] = _zeroCrossingRate(z);

    // Spectral features - help identify tremor patterns
    features['spectral_centroid_x'] = _spectralCentroid(x);
    features['spectral_centroid_y'] = _spectralCentroid(y);
    features['spectral_centroid_z'] = _spectralCentroid(z);

    // Energy features - indicate overall movement intensity
    features['energy_x'] = _energy(x);
    features['energy_y'] = _energy(y);
    features['energy_z'] = _energy(z);

    // Frequency domain features - detect tremor frequency
    features['dominant_freq_x'] = _dominantFrequency(x);
    features['dominant_freq_y'] = _dominantFrequency(y);
    features['dominant_freq_z'] = _dominantFrequency(z);

    // Additional features specifically for neurotoxin detection
    // Tremor frequency analysis
    features['tremor_frequency_x'] = _analyzeTremorFrequency(x);
    features['tremor_frequency_y'] = _analyzeTremorFrequency(y);
    features['tremor_frequency_z'] = _analyzeTremorFrequency(z);

    return features;
  }

  // Extract features from audio data (dB levels) with enhanced features for neurotoxin detection
  static Map<String, double> extractAudioFeatures(List<double> dBLevels) {
    if (dBLevels.isEmpty) return {};

    Map<String, double> features = {};

    // Statistical features
    features['mean_db'] = _mean(dBLevels);
    features['std_db'] = _std(dBLevels, features['mean_db']!);
    features['rms_db'] = _rms(dBLevels);
    features['min_db'] = dBLevels.reduce(min);
    features['max_db'] = dBLevels.reduce(max);
    features['range_db'] = features['max_db']! - features['min_db']!;

    // Peak detection features - important for detecting cough patterns
    features['peak_count'] = _countPeaks(dBLevels).toDouble();
    features['peak_mean'] = _meanPeaks(dBLevels);
    features['peak_std'] = _stdPeaks(dBLevels);

    // Additional features for better neurotoxin detection
    // Zero crossing rate - useful for detecting respiratory patterns
    features['zero_crossing_rate'] = _zeroCrossingRate(dBLevels);

    // Spectral features - help identify cough characteristics
    features['spectral_centroid'] = _spectralCentroid(dBLevels);

    // Energy features - indicate overall audio intensity
    features['energy'] = _energy(dBLevels);

    // Frequency features - detect cough frequency
    features['dominant_freq_audio'] = _dominantFrequency(dBLevels);

    return features;
  }

  // Helper functions
  static double _mean(List<double> data) {
    if (data.isEmpty) return 0.0;
    double sum = data.reduce((a, b) => a + b);
    return sum / data.length;
  }

  static double _std(List<double> data, double mean) {
    if (data.length <= 1) return 0.0;
    double variance =
        data.map((x) => pow(x - mean, 2).toDouble()).reduce((a, b) => a + b) /
        (data.length - 1);
    return sqrt(variance);
  }

  static double _rms(List<double> data) {
    if (data.isEmpty) return 0.0;
    double sumSquares = data.map((x) => x * x).reduce((a, b) => a + b);
    return sqrt(sumSquares / data.length);
  }

  static double _skewness(List<double> data, double mean, double std) {
    if (data.length <= 2 || std == 0) return 0.0;
    double sumCubes = data
        .map((x) => pow((x - mean) / std, 3).toDouble())
        .reduce((a, b) => a + b);
    return sumCubes / data.length;
  }

  static double _kurtosis(List<double> data, double mean, double std) {
    if (data.length <= 3 || std == 0) return 0.0;
    double sumQuads = data
        .map((x) => pow((x - mean) / std, 4).toDouble())
        .reduce((a, b) => a + b);
    return (sumQuads / data.length) - 3.0; // Excess kurtosis
  }

  static double _zeroCrossingRate(List<double> data) {
    if (data.length < 2) return 0.0;

    int crossings = 0;
    for (int i = 1; i < data.length; i++) {
      if ((data[i] >= 0 && data[i - 1] < 0) ||
          (data[i] < 0 && data[i - 1] >= 0)) {
        crossings++;
      }
    }

    return crossings / (data.length - 1).toDouble();
  }

  static double _spectralCentroid(List<double> data) {
    if (data.isEmpty) return 0.0;

    double sum = 0.0;
    double weightedSum = 0.0;

    for (int i = 0; i < data.length; i++) {
      sum += data[i].abs();
      weightedSum += i * data[i].abs();
    }

    return sum == 0 ? 0.0 : weightedSum / sum;
  }

  static double _energy(List<double> data) {
    if (data.isEmpty) return 0.0;

    double sum = 0.0;
    for (int i = 0; i < data.length; i++) {
      sum += data[i] * data[i];
    }

    return sum;
  }

  static double _dominantFrequency(List<double> data) {
    if (data.length < 2) return 0.0;

    // Simplified frequency analysis - find the most common difference between consecutive points
    List<double> diffs = [];
    for (int i = 1; i < data.length; i++) {
      diffs.add((data[i] - data[i - 1]).abs());
    }

    // Return the mean of differences as a proxy for dominant frequency
    return _mean(diffs);
  }

  // Enhanced tremor frequency analysis
  static double _analyzeTremorFrequency(List<double> data) {
    if (data.length < 4) return 0.0;

    // Look for oscillatory patterns that indicate tremors
    List<double> peaks = [];
    List<double> troughs = [];

    for (int i = 1; i < data.length - 1; i++) {
      if (data[i] > data[i - 1] && data[i] > data[i + 1]) {
        peaks.add(data[i]);
      } else if (data[i] < data[i - 1] && data[i] < data[i + 1]) {
        troughs.add(data[i]);
      }
    }

    // If we have both peaks and troughs, we likely have tremors
    if (peaks.isNotEmpty && troughs.isNotEmpty) {
      // Calculate the average distance between peaks as a frequency measure
      double avgPeakDistance = (data.length - 1) / peaks.length;
      return 1.0 / avgPeakDistance; // Simple frequency approximation
    }

    return 0.0;
  }

  static int _countPeaks(List<double> data) {
    if (data.length < 3) return 0;

    int peaks = 0;
    double threshold =
        _mean(data) + _std(data, _mean(data)) * 0.5; // 0.5 std above mean

    for (int i = 1; i < data.length - 1; i++) {
      if (data[i] > data[i - 1] &&
          data[i] > data[i + 1] &&
          data[i] > threshold) {
        peaks++;
      }
    }

    return peaks;
  }

  static double _meanPeaks(List<double> data) {
    if (data.length < 3) return 0.0;

    List<double> peaks = [];
    double threshold = _mean(data) + _std(data, _mean(data)) * 0.5;

    for (int i = 1; i < data.length - 1; i++) {
      if (data[i] > data[i - 1] &&
          data[i] > data[i + 1] &&
          data[i] > threshold) {
        peaks.add(data[i]);
      }
    }

    return peaks.isEmpty ? 0.0 : _mean(peaks);
  }

  static double _stdPeaks(List<double> data) {
    if (data.length < 3) return 0.0;

    List<double> peaks = [];
    double threshold = _mean(data) + _std(data, _mean(data)) * 0.5;

    for (int i = 1; i < data.length - 1; i++) {
      if (data[i] > data[i - 1] &&
          data[i] > data[i + 1] &&
          data[i] > threshold) {
        peaks.add(data[i]);
      }
    }

    return peaks.isEmpty ? 0.0 : _std(peaks, _mean(peaks));
  }
}
