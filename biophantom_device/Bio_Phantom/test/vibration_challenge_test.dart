import 'package:flutter_test/flutter_test.dart';
import 'package:bio_phantom_app/services/vibration_challenge.dart';

void main() {
  group('VibrationChallenge', () {
    test('can be instantiated', () {
      final challenge = VibrationChallenge();
      expect(challenge, isNotNull);
    });

    test('ChallengeResult can be created', () {
      final result = ChallengeResult(
        windows: [],
        vibProbs: [],
        vibProbAvg: 0.5,
        tiltDegrees: 30.0,
        stability: 'Medium',
        features: {'rms': 1.0, 'std': 0.1},
      );

      expect(result.vibProbAvg, 0.5);
      expect(result.tiltDegrees, 30.0);
      expect(result.stability, 'Medium');
    });
  });
}
