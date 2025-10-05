import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/consensus_engine.dart';

/// Service for exporting Mainframe logs and consensus data
class LogsExportService {
  final ConsensusEngine _consensusEngine;

  LogsExportService(this._consensusEngine);

  /// Export room alerts to CSV
  Future<String> exportAlertsToCsv() async {
    final alerts = _consensusEngine.roomAlerts.values.toList();

    if (alerts.isEmpty) {
      throw Exception('No alert data to export');
    }

    // Prepare CSV data
    final csvData = <List<dynamic>>[];

    // Add header
    csvData.add([
      'Room ID',
      'Alert Level',
      'Danger Votes',
      'Warning Votes',
      'Normal Votes',
      'Total Votes',
      'Average Probability',
      'Timestamp',
      'Message',
    ]);

    // Add data rows
    for (final alert in alerts) {
      final normalVotes = alert.totalVoteCount - alert.dangerVoteCount - alert.warningVoteCount;
      csvData.add([
        alert.roomId,
        alert.level.name,
        alert.dangerVoteCount,
        alert.warningVoteCount,
        normalVotes,
        alert.totalVoteCount,
        alert.averageProbability,
        alert.timestamp.toIso8601String(),
        alert.message ?? '',
      ]);
    }

    // Convert to CSV string
    const converter = ListToCsvConverter();
    final csvString = converter.convert(csvData);

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'mainframe_alerts_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvString);

    return file.path;
  }

  /// Export room statistics to CSV
  Future<String> exportStatisticsToCsv() async {
    final stats = _consensusEngine.getAllRoomStatistics();

    if (stats.isEmpty) {
      throw Exception('No statistics data to export');
    }

    // Prepare CSV data
    final csvData = <List<dynamic>>[];

    // Add header
    csvData.add([
      'Room ID',
      'Total Votes',
      'Danger Votes',
      'Warning Votes',
      'Normal Votes',
      'Average Probability',
      'Last Vote Timestamp',
    ]);

    // Add data rows
    stats.forEach((roomId, roomStats) {
      csvData.add([
        roomId,
        roomStats['totalVotes'],
        roomStats['dangerVotes'],
        roomStats['warningVotes'],
        roomStats['normalVotes'],
        roomStats['averageProbability'],
        roomStats['lastVote']?.toString() ?? '',
      ]);
    });

    // Convert to CSV string
    const converter = ListToCsvConverter();
    final csvString = converter.convert(csvData);

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'mainframe_statistics_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvString);

    return file.path;
  }

  /// Export all room votes to JSONL
  Future<String> exportVotesToJsonl() async {
    final votes = <Map<String, dynamic>>[];

    // Collect votes from all rooms
    for (final roomId in _consensusEngine.roomAlerts.keys) {
      final roomVotes = _consensusEngine.getRoomVotes(roomId);
      for (final vote in roomVotes) {
        votes.add({
          'roomId': vote.roomId,
          'deviceId': vote.deviceId,
          'probability': vote.probability,
          'decision': vote.decision.name,
          'timestamp': vote.timestamp.toIso8601String(),
          'riskResult': vote.riskResult?.toJson(),
        });
      }
    }

    if (votes.isEmpty) {
      throw Exception('No vote data to export');
    }

    // Convert to JSONL format
    final jsonlLines = votes.map((vote) => json.encode(vote)).toList();
    final jsonlString = jsonlLines.join('\n');

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'mainframe_votes_${DateTime.now().millisecondsSinceEpoch}.jsonl';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonlString);

    return file.path;
  }

  /// Export comprehensive system report
  Future<String> exportSystemReport() async {
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'summary': {
        'totalRooms': _consensusEngine.roomCount,
        'totalVotes': _consensusEngine.totalVoteCount,
      },
      'roomAlerts': _consensusEngine.roomAlerts.map((roomId, alert) => MapEntry(roomId, {
        'level': alert.level.name,
        'dangerVotes': alert.dangerVoteCount,
        'totalVotes': alert.totalVoteCount,
        'averageProbability': alert.averageProbability,
        'timestamp': alert.timestamp.toIso8601String(),
        'message': alert.message,
      })),
      'roomStatistics': _consensusEngine.getAllRoomStatistics(),
    };

    // Convert to JSON
    final jsonString = JsonEncoder.withIndent('  ').convert(report);

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'mainframe_report_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonString);

    return file.path;
  }

  /// Get export summary
  Map<String, dynamic> getExportSummary() {
    return {
      'totalRooms': _consensusEngine.roomCount,
      'totalVotes': _consensusEngine.totalVoteCount,
      'alertsCount': _consensusEngine.roomAlerts.length,
      'lastExportTime': DateTime.now().toIso8601String(),
    };
  }
}