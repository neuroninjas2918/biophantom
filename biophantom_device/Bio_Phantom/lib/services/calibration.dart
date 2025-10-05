import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Calibration {
  final List<double> vibMean, vibStd, audMean, audStd;

  Calibration({
    required this.vibMean,
    required this.vibStd,
    required this.audMean,
    required this.audStd,
  });

  static Future<Calibration?> load() async {
    try {
      final s = await rootBundle.loadString(
        'assets/models/biophantom_calibration.json',
      );
      final j = jsonDecode(s) as Map<String, dynamic>;
      List<double> toD(List v) => v.map((e) => (e as num).toDouble()).toList();
      return Calibration(
        vibMean: toD(j['vibration']['mean']),
        vibStd: toD(j['vibration']['std']),
        audMean: toD(j['audio']['mean']),
        audStd: toD(j['audio']['std']),
      );
    } catch (_) {
      return null;
    }
  }

  List<List<double>> zVib(List<List<double>> t2) {
    if (vibStd.any((s) => s == 0)) return t2;
    return List.generate(
      t2.length,
      (i) => [
        (t2[i][0] - vibMean[0]) / vibStd[0],
        (t2[i][1] - vibMean[1]) / vibStd[1],
      ],
    );
  }

  List<List<double>> zAud(List<List<double>> t2) {
    if (audStd.any((s) => s == 0)) return t2;
    return List.generate(
      t2.length,
      (i) => [
        (t2[i][0] - audMean[0]) / audStd[0],
        (t2[i][1] - audMean[1]) / audStd[1],
      ],
    );
  }
}
