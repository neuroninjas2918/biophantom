import 'dart:math' as math;

class FeatureBuilder {
  static List<double> deriv(List<double> x) {
    final out = List<double>.filled(x.length, 0.0);
    out[0] = x[0];
    for (int i = 1; i < x.length; i++) {
      out[i] = x[i] - x[i - 1];
    }
    return out;
  }

  static List<List<double>> toT2(List<double> raw) {
    final dx = deriv(raw);
    return List.generate(raw.length, (i) => [raw[i], dx[i]]);
  }

  static double smoothMA(List<double> v, int w) {
    if (v.isEmpty) return 0;
    final win = math.max(1, w);
    final n = math.min(v.length, win);
    final slice = v.sublist(v.length - n);
    final s = slice.fold<double>(0.0, (a, b) => a + b);
    return s / n;
  }
}
