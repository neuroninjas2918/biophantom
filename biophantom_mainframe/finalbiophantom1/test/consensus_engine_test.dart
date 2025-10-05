import 'package:flutter_test/flutter_test.dart';
import 'package:biophantom_core/biophantom_core.dart';
import '../lib/services/consensus_engine.dart';

void main() {
  group('ConsensusEngine Mainframe Tests', () {
    late ConsensusEngine consensusEngine;

    setUp(() {
      consensusEngine = ConsensusEngine();
    });

    tearDown(() {
      consensusEngine.dispose();
    });

    test('should initialize with empty state', () {
      expect(consensusEngine.roomCount, equals(0));
      expect(consensusEngine.totalVoteCount, equals(0));
      expect(consensusEngine.roomAlerts, isEmpty);
    });

    test('should add votes and update consensus', () {
      // Add danger votes
      final vote1 = DeviceVote(
        deviceId: 'device1',
        roomId: 'room1',
        probability: 0.9,
        decision: Decision.danger,
        timestamp: DateTime.now(),
      );

      final vote2 = DeviceVote(
        deviceId: 'device2',
        roomId: 'room1',
        probability: 0.8,
        decision: Decision.danger,
        timestamp: DateTime.now(),
      );

      consensusEngine.addVote(vote1);
      consensusEngine.addVote(vote2);

      expect(consensusEngine.roomCount, equals(1));
      expect(consensusEngine.totalVoteCount, equals(2));

      final alerts = consensusEngine.roomAlerts;
      expect(alerts.length, equals(1));
      expect(alerts['room1']?.isOutbreak, isTrue);
      expect(alerts['room1']?.dangerVoteCount, equals(2));
    });

    test('should handle room statistics', () {
      final vote = DeviceVote(
        deviceId: 'device1',
        roomId: 'room1',
        probability: 0.7,
        decision: Decision.danger,
        timestamp: DateTime.now(),
      );

      consensusEngine.addVote(vote);

      final stats = consensusEngine.getRoomStatistics('room1');
      expect(stats['totalVotes'], equals(1));
      expect(stats['dangerVotes'], equals(1));
      expect(stats['averageProbability'], closeTo(0.7, 0.01));
    });

    test('should reset room alerts', () {
      final vote = DeviceVote(
        deviceId: 'device1',
        roomId: 'room1',
        probability: 0.9,
        decision: Decision.danger,
        timestamp: DateTime.now(),
      );

      consensusEngine.addVote(vote);
      expect(consensusEngine.roomAlerts.containsKey('room1'), isTrue);

      consensusEngine.resetRoomAlert('room1');
      expect(consensusEngine.roomAlerts['room1']?.isNormal, isTrue);
    });

    test('should clear all data', () {
      final vote = DeviceVote(
        deviceId: 'device1',
        roomId: 'room1',
        probability: 0.8,
        decision: Decision.danger,
        timestamp: DateTime.now(),
      );

      consensusEngine.addVote(vote);
      expect(consensusEngine.totalVoteCount, equals(1));

      consensusEngine.clear();
      expect(consensusEngine.totalVoteCount, equals(0));
      expect(consensusEngine.roomCount, equals(0));
    });
  });
}