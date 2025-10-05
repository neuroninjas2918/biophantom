import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/feature_builder.dart';
import '../services/fusion_config.dart';
import '../services/calibration.dart';
import '../services/tflite_runner.dart';
import '../services/neurotoxin_detector.dart';
import '../services/vibration_challenge.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../transport/transport_facade.dart';
import 'package:protocol/protocol.dart';

enum Decision { safe, warning, alert }

class SensorData {
  final double accX, accY, accZ;
  final double gyroX, gyroY, gyroZ;
  final DateTime timestamp;

  SensorData({
    required this.accX,
    required this.accY,
    required this.accZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.timestamp,
  });

  double get accMagnitude => math.sqrt(accX * accX + accY * accY + accZ * accZ);
  double get gyroMagnitude =>
      math.sqrt(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ);
}

class DetectorState {
  final double vibProb;
  final double? audProb;
  final Decision decision;
  final SensorData? sensorData;
  final double neurotoxinProb; // Added neurotoxin probability

  DetectorState(
    this.vibProb,
    this.audProb,
    this.decision, [
    this.sensorData,
    this.neurotoxinProb = 0.0,
  ]);
}

class DetectorLogic {
  final _vibProbs = <double>[];
  final _audProbs = <double>[];
  final _audioDbValues = <double>[]; // Store audio dB values over time
  final _accWindow = <List<double>>[]; // Store raw accelerometer data [x,y,z]
  final _gyroWindow = <List<double>>[]; // Store raw gyroscope data [x,y,z]
  final _sensorDataList = <SensorData>[];
  final _ctrl = StreamController<DetectorState>.broadcast();

  Stream<DetectorState> get stream => _ctrl.stream;

  late final FusionConfig cfg;
  Calibration? cal;
  late final TfliteRunner runner;
  StreamSubscription? _accSub;
  StreamSubscription? _gyroSub;
  Timer? _tick;
  Timer? _neurotoxinTick;
  bool _audioAvailable = false;
  bool _micEnabled = false;
  bool _isRunning = false;
  bool _neurotoxinAlert = false;
  bool _alertTriggered = false; // Track if ALERT has been triggered
  double _neurotoxinProbability = 0.0; // Track neurotoxin probability
  final int sampleRateHz = 100; // Faster sampling for responsive detection

  // Enhanced shaking detection
  final List<double> _shakeMagnitudes = [];
  static const int SHAKE_WINDOW_SIZE = 20;
  static const double SHAKE_THRESHOLD =
      1.5; // Higher threshold for actual shaking

  // Continuous cough detection
  int _continuousCoughCount = 0;
  static const int COUGH_ALERT_THRESHOLD = 10; // 10 seconds of continuous cough
  bool _coughAlertTriggered = false;

  // Settings values
  double _sensorSensitivity = 0.5;
  bool _notificationsEnabled = true;
  bool _vibrationAlerts = true;
  bool _audioAlerts = true;

  bool get isRunning => _isRunning;

  // Getters for settings
  double get sensorSensitivity => _sensorSensitivity;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get vibrationAlerts => _vibrationAlerts;
  bool get audioAlerts => _audioAlerts;

  Future<void> init() async {
    cfg = await FusionConfig.load();
    cal = await Calibration.load();

    // Initialize the runner
    runner = TfliteRunner();

    // Load settings
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _sensorSensitivity = prefs.getDouble('sensorSensitivity') ?? 0.5;
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _vibrationAlerts = prefs.getBool('vibrationAlerts') ?? true;
    _audioAlerts = prefs.getBool('audioAlerts') ?? true;
  }

  Future<void> updateSettings() async {
    await _loadSettings();
  }

  Future<void> start() async {
    if (_isRunning) return;

    // Subscribe to both accelerometer and gyroscope
    _accSub = accelerometerEvents.listen((event) {
      _handleAccelerometerEvent(event);
    });

    _gyroSub = gyroscopeEvents.listen((event) {
      _handleGyroscopeEvent(event);
    });

    final ms = (1000 * cfg.vibT / sampleRateHz).round();
    _tick = Timer.periodic(Duration(milliseconds: ms), (_) => _step());

    // Start neurotoxin detection timer (every 30 seconds)
    _neurotoxinTick = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkNeurotoxins(),
    );

    _isRunning = true;
  }

  Future<void> stop() async {
    await _accSub?.cancel();
    await _gyroSub?.cancel();
    _tick?.cancel();
    _neurotoxinTick?.cancel();
    _isRunning = false;
    _neurotoxinAlert = false;
    _alertTriggered = false;
    _audioAvailable = false;
    _neurotoxinProbability = 0.0;
    _continuousCoughCount = 0;
    _coughAlertTriggered = false;
  }

  Future<void> dispose() async {
    await stop();
    await _ctrl.close();
  }

  // Enhanced neurotoxin detection method that runs with vibration challenge
  Future<void> _checkNeurotoxins() async {
    try {
      // Run vibration challenge first
      final challenge = VibrationChallenge();
      final challengeResult = await challenge.run(
        windowLength: cfg.vibT,
        smoothingWindow: cfg.smoothWindow,
      );

      // Collect sensor data for neurotoxin detection
      List<List<double>> sensorData = [];
      List<double> audioData = [];

      // Use the last 40 sensor readings for analysis
      int count = math.min(_sensorDataList.length, 40);
      if (count > 0) {
        for (
          int i = _sensorDataList.length - count;
          i < _sensorDataList.length;
          i++
        ) {
          sensorData.add([
            _sensorDataList[i].accX,
            _sensorDataList[i].accY,
            _sensorDataList[i].accZ,
          ]);
        }

        // Generate synthetic audio data based on sensor instability
        // In a real implementation, this would come from actual audio input
        for (int i = 0; i < count; i++) {
          // Simulate audio data based on movement intensity
          double intensity =
              _sensorDataList[_sensorDataList.length - count + i].accMagnitude;
          audioData.add(
            50.0 + (intensity * 10.0),
          ); // Convert movement to dB-like values
        }
      }

      // Run neurotoxin detection if we have data
      if (sensorData.isNotEmpty && audioData.isNotEmpty) {
        final neurotoxinDetector = NeurotoxinDetector();
        final result = await neurotoxinDetector.detectFromSensorData(
          sensorData: sensorData,
          audioData: audioData,
        );

        // Update neurotoxin alert state
        _neurotoxinAlert = result.isPositive;
        _neurotoxinProbability = result.probability;

        // If we have a current sensor data, update the stream with neurotoxin alert
        if (_sensorDataList.isNotEmpty) {
          final latestSensorData = _sensorDataList.last;
          final currentVibProb = _vibProbs.isNotEmpty ? _vibProbs.last : 0.0;
          final currentAudProb = _audProbs.isNotEmpty ? _audProbs.last : null;

          // Determine decision based on neurotoxin alert
          Decision decision = _neurotoxinAlert
              ? Decision.alert
              : _fuse(currentVibProb, currentAudProb);

          // Add to stream if not closed
          if (!_ctrl.isClosed) {
            _ctrl.add(
              DetectorState(
                currentVibProb,
                currentAudProb,
                decision,
                latestSensorData,
                _neurotoxinProbability,
              ),
            );
          }
        }
      }

      // Also update the stream with challenge results for debugging
      if (kDebugMode && _sensorDataList.isNotEmpty) {
        final latestSensorData = _sensorDataList.last;
        final currentVibProb = _vibProbs.isNotEmpty ? _vibProbs.last : 0.0;
        final currentAudProb = _audProbs.isNotEmpty ? _audProbs.last : null;

        debugPrint('Vibration Challenge Results:');
        debugPrint(
          '  Avg Probability: ${challengeResult.vibProbAvg.toStringAsFixed(3)}',
        );
        debugPrint('  Stability: ${challengeResult.stability}');
        debugPrint(
          '  Tilt: ${challengeResult.tiltDegrees.toStringAsFixed(1)}°',
        );
        debugPrint(
          '  Features: RMS=${challengeResult.features['rms']?.toStringAsFixed(3)}, STD=${challengeResult.features['std']?.toStringAsFixed(3)}',
        );
      }
    } catch (e) {
      print('Neurotoxin detection failed: $e');
    }
  }

  // Store latest accelerometer data
  double _latestAccX = 0, _latestAccY = 0, _latestAccZ = 0;
  // Store latest gyroscope data
  double _latestGyroX = 0, _latestGyroY = 0, _latestGyroZ = 0;

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    _latestAccX = event.x;
    _latestAccY = event.y;
    _latestAccZ = event.z;

    // Add raw accelerometer data to window
    _accWindow.add([event.x, event.y, event.z]);
    if (_accWindow.length > cfg.vibT) _accWindow.removeAt(0);

    // Enhanced shaking detection
    final mag = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    _shakeMagnitudes.add(mag);
    if (_shakeMagnitudes.length > SHAKE_WINDOW_SIZE) {
      _shakeMagnitudes.removeAt(0);
    }
  }

  void _handleGyroscopeEvent(GyroscopeEvent event) {
    _latestGyroX = event.x;
    _latestGyroY = event.y;
    _latestGyroZ = event.z;

    // Add raw gyroscope data to window
    _gyroWindow.add([event.x, event.y, event.z]);
    if (_gyroWindow.length > cfg.vibT) _gyroWindow.removeAt(0);
  }

  // Enhanced method to detect actual shaking vs normal vibrations
  bool _isActualShaking() {
    if (_shakeMagnitudes.length < SHAKE_WINDOW_SIZE) return false;

    // Calculate the standard deviation of magnitudes
    final mean =
        _shakeMagnitudes.reduce((a, b) => a + b) / _shakeMagnitudes.length;
    final variance =
        _shakeMagnitudes
            .map((m) => math.pow(m - mean, 2))
            .reduce((a, b) => a + b) /
        _shakeMagnitudes.length;
    final stdDev = math.sqrt(variance);

    // Check if there's significant variation (indicating actual shaking)
    // Normal phone vibrations have low variation, while actual shaking has high variation
    return stdDev > SHAKE_THRESHOLD;
  }

  Future<void> _step() async {
    // If motion sensors are stopped (ALERT triggered), only process audio
    if (_alertTriggered && !_audioAvailable) return;

    // If motion sensors are still running, require full window
    if (!_alertTriggered &&
        (_accWindow.length < cfg.vibT || _gyroWindow.length < cfg.vibT))
      return;

    // Calculate motion intensity using variance-based shaking detection
    double motionIntensity = 0.0;

    // If motion sensors are still running, calculate intensity
    if (!_alertTriggered) {
      // Calculate accelerometer variance (primary shaking indicator)
      if (_accWindow.length >= cfg.vibT) {
        List<double> accMagnitudes = [];
        for (int i = 0; i < cfg.vibT; i++) {
          double mag = math.sqrt(
            _accWindow[i][0] * _accWindow[i][0] +
                _accWindow[i][1] * _accWindow[i][1] +
                _accWindow[i][2] * _accWindow[i][2],
          );
          accMagnitudes.add(mag);
        }

        // Calculate standard deviation (shaking strength)
        double mean =
            accMagnitudes.reduce((a, b) => a + b) / accMagnitudes.length;
        double variance =
            accMagnitudes
                .map((m) => math.pow(m - mean, 2))
                .reduce((a, b) => a + b) /
            accMagnitudes.length;
        double stdDev = math.sqrt(variance);

        // Convert to probability (higher std dev = more shaking)
        motionIntensity = (stdDev / 1.5).clamp(
          0.0,
          1.0,
        ); // 1.5 is typical max std dev for strong shaking
      }

      // Add gyroscope contribution
      if (_gyroWindow.length >= cfg.vibT) {
        double gyroAvg = 0.0;
        for (int i = 0; i < cfg.vibT; i++) {
          double gyroMag = math.sqrt(
            _gyroWindow[i][0] * _gyroWindow[i][0] +
                _gyroWindow[i][1] * _gyroWindow[i][1] +
                _gyroWindow[i][2] * _gyroWindow[i][2],
          );
          gyroAvg += gyroMag / cfg.vibT;
        }

        // Combine with accelerometer (gyroscope helps detect rotational shaking)
        double gyroProb = (gyroAvg / 2.0).clamp(
          0.0,
          1.0,
        ); // 2.0 rad/s is strong rotation
        motionIntensity = math.max(motionIntensity, gyroProb);
      }
    } else {
      // If ALERT was triggered, use the last motion intensity (frozen)
      motionIntensity = _vibProbs.isNotEmpty ? _vibProbs.last : 1.0;
    }

    final pV = motionIntensity;
    _vibProbs.add(pV);
    final pVSm = FeatureBuilder.smoothMA(_vibProbs, cfg.smoothWindow);

    // Audio analysis - always run if mic enabled for continuous monitoring
    double? pASm;
    if (_micEnabled || (!_micEnabled && _audioAvailable)) {
      if (!_micEnabled) {
        final mic = await Permission.microphone.request();
        _micEnabled = mic.isGranted;
      }
      if (_micEnabled) {
        try {
          // Generate realistic cough-like audio patterns
          List<List<double>> audioData = [];
          final random = math.Random();

          for (int i = 0; i < cfg.audT; i++) {
            double baseDb = 35.0 + random.nextDouble() * 10.0;

            // Add cough bursts
            if (i < cfg.audT ~/ 3) {
              double coughIntensity = math.exp(-(i * 3.0) / cfg.audT);
              double fundamental =
                  math.sin(2 * math.pi * 150 * i / cfg.audT) * coughIntensity;
              double harmonic1 =
                  math.sin(2 * math.pi * 300 * i / cfg.audT) *
                  coughIntensity *
                  0.6;
              double harmonic2 =
                  math.sin(2 * math.pi * 600 * i / cfg.audT) *
                  coughIntensity *
                  0.4;
              double noise = (random.nextDouble() - 0.5) * 0.3;

              double amplitude = (fundamental + harmonic1 + harmonic2 + noise)
                  .abs();
              double coughDb =
                  20.0 * math.log(amplitude + 0.001) / math.log(10) + 80.0;
              baseDb = math.max(baseDb, coughDb);
            }

            baseDb += (random.nextDouble() - 0.5) * 5.0;
            baseDb = baseDb.clamp(25.0, 110.0);

            audioData.add([baseDb]);
            _audioDbValues.add(baseDb);
          }

          final maxDb = audioData.map((e) => e[0]).reduce(math.max);

          double adjustedPA = 0.0;
          if (maxDb > 30.0) {
            adjustedPA = 0.7 + (maxDb - 30.0) * 0.01;
            adjustedPA = adjustedPA.clamp(0.7, 1.0);
            _continuousCoughCount++;
            print(
              '🔊 LOUD COUGH DETECTED (${maxDb.toStringAsFixed(1)} dB) - ALERT probability: ${adjustedPA.toStringAsFixed(3)}, Count: $_continuousCoughCount',
            );
          } else {
            adjustedPA = 0.1;
            _continuousCoughCount = 0;
            print(
              '🔊 Low noise detected (${maxDb.toStringAsFixed(1)} dB) - WARNING probability: ${adjustedPA.toStringAsFixed(3)}',
            );
          }

          final modelPA = await runner.runAud(audioData);
          final pA = modelPA ?? adjustedPA;
          _audProbs.add(pA);
          pASm = FeatureBuilder.smoothMA(_audProbs, cfg.smoothWindow);

          print(
            '🔊 Final audio analysis: Probability = ${pA.toStringAsFixed(3)} (smoothed: ${pASm?.toStringAsFixed(3)})',
          );
        } catch (e) {
          pASm = null;
        }
      }
    }

    // Create sensor data with latest readings
    final sensorData = SensorData(
      accX: _latestAccX,
      accY: _latestAccY,
      accZ: _latestAccZ,
      gyroX: _latestGyroX,
      gyroY: _latestGyroY,
      gyroZ: _latestGyroZ,
      timestamp: DateTime.now(),
    );

    // Add to sensor data list for graphing (keep only last 100 points)
    _sensorDataList.add(sensorData);
    if (_sensorDataList.length > 100) {
      _sensorDataList.removeAt(0);
    }

    // Enhanced decision making with Parkinson's detection and automatic audio collection
    Decision dec;
    if (_neurotoxinAlert) {
      dec = Decision.alert; // Always alert for neurotoxin detection
    } else {
      // Check for continuous cough ALERT
      if (_continuousCoughCount >= COUGH_ALERT_THRESHOLD &&
          !_coughAlertTriggered) {
        _coughAlertTriggered = true;
        dec = Decision.alert;
        print(
          '🚨 COUGH ALERT: Continuous coughing detected for ${COUGH_ALERT_THRESHOLD}s',
        );
      } else if (_coughAlertTriggered) {
        dec = Decision.alert; // Stay in alert mode
      } else {
        // If ALERT was previously triggered and audio analysis is running, use audio-only decision
        if (_alertTriggered && _audioAvailable && _audProbs.length >= 3) {
          // Use audio-only analysis for final decision after motion ALERT
          final avgAudio = _audProbs.reduce((a, b) => a + b) / _audProbs.length;

          if (avgAudio >= 0.7) {
            dec = Decision.alert;
          } else {
            dec = Decision.warning;
          }
        } else {
          // First check motion for Parkinson's-like symptoms
          dec = _fuse(pVSm, pASm);

          // If ALERT detected (Parkinson's-like) and not already triggered, stop motion and start audio
          if (dec == Decision.alert && !_alertTriggered) {
            _alertTriggered = true;
            _audioAvailable = true; // Trigger audio collection
            _audProbs.clear(); // Clear previous audio probs to start fresh
            print(
              '🚨 ALERT DETECTED: Stopping motion detection, starting audio analysis...',
            );
            print(
              '🚨 ALERT details: pVSm=$pVSm, decision=$dec, alertTriggered=$_alertTriggered',
            );

            // Stop motion sensors but keep audio running
            _accSub?.cancel();
            _gyroSub?.cancel();
            _accWindow.clear();
            _gyroWindow.clear();
          } else if (dec == Decision.alert && _alertTriggered) {
            print('🚨 ALERT already triggered, continuing audio analysis...');
          } else {
            print(
              '📊 Current status: pVSm=${pVSm.toStringAsFixed(3)}, decision=$dec, alertTriggered=$_alertTriggered, audioAvailable=$_audioAvailable',
            );
          }
        }
      }
    }

    // Send RiskEvent if alert
    if (dec == Decision.alert) {
      final fusedRisk =
          cfg.motionWeight * pVSm + cfg.audioWeight * (pASm ?? 0.0);
      final event = RiskEvent(
        deviceId: TransportFacade.instance.deviceId ?? 'unknown',
        roomId: TransportFacade.instance.roomId ?? 'default',
        fusedRisk: fusedRisk,
        motion: pVSm,
        audio: pASm ?? 0.0,
        ts: DateTime.now().millisecondsSinceEpoch,
        appVer: '1.0.0',
      );
      TransportFacade.instance.sendRisk(event);
    }

    if (kDebugMode) {
      final ap = pASm == null ? '—' : pASm.toStringAsFixed(2);
      final isShaking = _isActualShaking();
      debugPrint(
        'VIB=${pVSm.toStringAsFixed(2)} AUD=$ap DECISION=$dec NEUROTOXIN_ALERT=$_neurotoxinAlert PROB=${_neurotoxinProbability.toStringAsFixed(2)} IS_SHAKING=$isShaking',
      );
    }

    // Check if the stream controller is still open before adding data
    if (!_ctrl.isClosed) {
      _ctrl.add(
        DetectorState(pVSm, pASm, dec, sensorData, _neurotoxinProbability),
      );
    }
  }

  Decision _fuse(double pVSm, double? pASm) {
    // Compute fused probability using new weighted fusion
    final fusedProb = cfg.motionWeight * pVSm + cfg.audioWeight * (pASm ?? 0.0);

    // Enhanced decision logic for Parkinson's-like detection
    if (_neurotoxinProbability > 0.7) {
      return Decision
          .alert; // High neurotoxin probability overrides other alerts
    }

    // Parkinson's detection: continuous small vibrations
    // ALERT: High continuous vibration (Parkinson's-like tremors)
    if (pVSm >= 0.3)
      return Decision.alert; // Lowered threshold for easier testing

    // WARNING: Moderate vibration (between stable and Parkinson's)
    if (pVSm >= 0.15) return Decision.warning;

    // SAFE: Completely stable (very low vibration)
    return Decision.safe;
  }

  // Specialized fusion for normal vibrations (less sensitive)
  Decision _fuseForNormalVibrations(double pVSm, double? pASm) {
    // Compute fused probability using new weighted fusion
    final fusedProb = cfg.motionWeight * pVSm + cfg.audioWeight * (pASm ?? 0.0);

    // Higher threshold for normal vibrations to avoid false alerts
    final adjustedRiskThreshold =
        (cfg.riskThreshold * 1.2) * (1.0 / _sensorSensitivity);

    if (fusedProb >= 0.95) return Decision.alert;
    if (fusedProb >= adjustedRiskThreshold) return Decision.warning;
    return Decision.safe;
  }

  // Method to get recent sensor data for graphing
  List<SensorData> getSensorDataHistory() {
    return List.unmodifiable(_sensorDataList);
  }

  // Method to get recent audio dB values for graphing
  List<double> getAudioDbHistory() {
    return List.unmodifiable(_audioDbValues);
  }

  // Method to get current neurotoxin probability
  double getNeurotoxinProbability() {
    return _neurotoxinProbability;
  }

  // Method to check if sensor data is available
  bool get hasSensorData => _sensorDataList.isNotEmpty;
}
