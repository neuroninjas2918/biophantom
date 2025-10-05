import 'dart:async';
import 'dart:math';
import 'package:vibration/vibration.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';
import '../services/fusion_config.dart';
import '../services/tflite_runner.dart';

class VibrationChallenge {
  final _accel = <DateTime, List<double>>{};
  final _gyro = <DateTime, List<double>>{};

  Future<bool> canVibrate() async => await Vibration.hasVibrator() ?? false;

  Future<ChallengeResult> run({
    required int windowLength,
    required int smoothingWindow,
    void Function(int step)? onStep,
  }) async {
    _accel.clear();
    _gyro.clear();
    final subs = <StreamSubscription>[];

    subs.add(
      accelerometerEvents.listen((e) {
        _accel[DateTime.now()] = [
          e.x.toDouble(),
          e.y.toDouble(),
          e.z.toDouble(),
        ];
      }),
    );
    subs.add(
      gyroscopeEvents.listen((e) {
        _gyro[DateTime.now()] = [
          e.x.toDouble(),
          e.y.toDouble(),
          e.z.toDouble(),
        ];
      }),
    );

    Future<void> _buzz(List<int> pattern, {List<int>? intensities}) async {
      final can = await canVibrate();
      if (can) {
        try {
          await Vibration.vibrate(
            pattern: pattern,
            intensities: intensities ?? [],
          );
        } catch (_) {
          await Vibration.vibrate(pattern: pattern);
        }
      } else {
        // fallback haptics (no-op here; UI can show a tip)
        await Future.delayed(
          Duration(milliseconds: pattern.fold(0, (a, b) => a + b)),
        );
      }
    }

    // 5 patterns optimized for neurotoxin detection calibration
    final patterns = <List<int>>[
      [150, 150, 150, 150, 150], // Short taps to test response time
      [250, 100, 250, 100, 250], // Rhythmic pattern for frequency response
      [
        50,
        50,
        50,
        50,
        50,
        50,
        50,
        50,
        50,
        50,
      ], // Rapid vibration for sensitivity
      [100, 100, 50, 50, 25, 25], // Decaying pattern for damping analysis
      [800, 1000], // Long vibration for baseline measurement
    ];

    for (var i = 0; i < patterns.length; i++) {
      onStep?.call(i + 1);
      await _buzz(patterns[i]);
      // quiet tail after each pattern to observe decay
      await Future.delayed(const Duration(milliseconds: 400));
    }

    // final quiet window for baseline measurement
    await Future.delayed(const Duration(milliseconds: 400));
    for (final s in subs) {
      await s.cancel();
    }

    // Convert to sorted lists
    final aEntries = _accel.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final gEntries = _gyro.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Build windows per pattern (simplified: split the whole capture into 5 equal segments)
    final aMag = _toMagnitudeSeries(aEntries);
    final windows = _segmentAndResample(
      aMag,
      nSegments: 5,
      T: windowLength,
    ).map((raw) => _toTwoChannel(raw)).toList(); // List<[T,2]>

    // Enhanced features for better shaking detection
    final feats = _enhancedFeatures(aMag);

    // Run TFLite per window
    final runner = TfliteRunner();
    final vibProbs = <double>[];
    for (final w in windows) {
      final p = await runner.runVibrationWindow(w);
      vibProbs.add(p);
    }

    // Smooth
    final avg = _movingAverage(vibProbs, smoothingWindow).last;

    final tilt = _estimateTiltDegrees(aMag);
    final stability = _stabilityLabel(aMag);

    return ChallengeResult(
      windows: windows,
      vibProbs: vibProbs,
      vibProbAvg: avg,
      tiltDegrees: tilt,
      stability: stability,
      features: feats,
    );
  }

  // --- helpers (implement simply; exact math can be improved) ---
  List<double> _toMagnitudeSeries(
    List<MapEntry<DateTime, List<double>>> entries,
  ) {
    final out = <double>[];
    for (final e in entries) {
      final v = e.value; // [x,y,z]
      out.add(sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]));
    }
    return out;
  }

  List<double> _resample(List<double> x, int T) {
    if (x.isEmpty) return List.filled(T, 0);
    final out = List<double>.filled(T, 0);
    for (int i = 0; i < T; i++) {
      final idx = i * (x.length - 1) / (T - 1);
      final lo = idx.floor().clamp(0, x.length - 1);
      final hi = idx.ceil().clamp(0, x.length - 1);
      final t = idx - lo;
      out[i] = x[lo] * (1 - t) + x[hi] * t;
    }
    return out;
  }

  List<List<double>> _toTwoChannel(List<double> raw) {
    final T = raw.length;
    final deriv = List<double>.filled(T, 0);
    for (int i = 1; i < T; i++) {
      deriv[i] = raw[i] - raw[i - 1];
    }
    return List.generate(T, (i) => [raw[i], deriv[i]]);
  }

  List<List<double>> _segmentAndResample(
    List<double> x, {
    required int nSegments,
    required int T,
  }) {
    final segLen = (x.length / nSegments).floor().clamp(1, x.length);
    final segs = <List<double>>[];
    for (int k = 0; k < nSegments; k++) {
      final start = (k * segLen).clamp(0, x.length);
      final end = ((k + 1) * segLen).clamp(0, x.length);
      final seg = x.sublist(start, end);
      segs.add(_resample(seg, T));
    }
    return segs;
  }

  // Enhanced features for better shaking detection
  Map<String, double> _enhancedFeatures(List<double> x) {
    if (x.isEmpty) return {};

    final mean = x.isEmpty ? 0 : x.reduce((a, b) => a + b) / x.length;
    final std = x.isEmpty
        ? 0
        : sqrt(
            x.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / x.length,
          );

    // Additional features for better discrimination
    final rms = sqrt(
      (x.map((v) => v * v).reduce((a, b) => a + b) / max(1, x.length)),
    );

    // Peak-to-peak amplitude
    final minVal = x.reduce(min);
    final maxVal = x.reduce(max);
    final peakToPeak = maxVal - minVal;

    // Zero crossing rate
    int zeroCrossings = 0;
    for (int i = 1; i < x.length; i++) {
      if ((x[i] >= mean && x[i - 1] < mean) ||
          (x[i] < mean && x[i - 1] >= mean)) {
        zeroCrossings++;
      }
    }
    final zeroCrossingRate = zeroCrossings / x.length;

    // Dominant frequency approximation
    final dominantFreq = _estimateDominantFrequency(x);

    return {
      "rms": rms.toDouble(),
      "std": std.toDouble(),
      "mean": mean.toDouble(),
      "peak_to_peak": peakToPeak.toDouble(),
      "zero_crossing_rate": zeroCrossingRate.toDouble(),
      "dominant_freq": dominantFreq.toDouble(),
    };
  }

  double _estimateDominantFrequency(List<double> data) {
    if (data.length < 2) return 0.0;

    // Simplified frequency analysis - find the most common difference between consecutive points
    List<double> diffs = [];
    for (int i = 1; i < data.length; i++) {
      diffs.add((data[i] - data[i - 1]).abs());
    }

    // Return the mean of differences as a proxy for dominant frequency
    if (diffs.isEmpty) return 0.0;
    return diffs.reduce((a, b) => a + b) / diffs.length;
  }

  List<double> _movingAverage(List<double> x, int w) {
    if (x.isEmpty || w <= 1) return x;
    final out = <double>[];
    double s = 0;
    for (int i = 0; i < x.length; i++) {
      s += x[i];
      if (i >= w) s -= x[i - w];
      out.add(i + 1 < w ? s / (i + 1) : s / w);
    }
    return out;
  }

  double _estimateTiltDegrees(List<double> x) {
    // crude: compare early vs late median to infer a rough tilt proxy
    if (x.length < 10) return 0;
    final m1 = x.sublist(0, x.length ~/ 3)..sort();
    final m2 = x.sublist(2 * x.length ~/ 3).toList()..sort();
    final med1 = m1[m1.length ~/ 2];
    final med2 = m2[m2.length ~/ 2];
    return (atan2((med2 - med1).abs(), 9.81) * 180 / pi).clamp(0, 85);
    // (Replace with gravity LPF if desired)
  }

  String _stabilityLabel(List<double> x) {
    if (x.length < 2) return "Unknown";
    final mean = x.reduce((a, b) => a + b) / x.length;
    final std = sqrt(
      x.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / x.length,
    );
    final cv = mean.abs() < 1e-6 ? 0 : std / mean.abs();
    if (cv < 0.05) return "High";
    if (cv < 0.15) return "Medium";
    return "Low";
  }
}

class ChallengeResult {
  final List<List<List<double>>> windows;
  final List<double> vibProbs;
  final double vibProbAvg;
  final double tiltDegrees;
  final String stability;
  final Map<String, double> features;

  ChallengeResult({
    required this.windows,
    required this.vibProbs,
    required this.vibProbAvg,
    required this.tiltDegrees,
    required this.stability,
    required this.features,
  });
}
