import 'dart:async';
import 'package:biophantom_core/biophantom_core.dart';

/// Consensus engine for aggregating device votes and determining room alerts
class ConsensusEngine {
  final Map<String, List<DeviceVote>> _roomVotes = {};
  final Map<String, RoomAlert> _roomAlerts = {};
  final StreamController<RoomAlert> _alertController = StreamController<RoomAlert>.broadcast();
  
  // Configuration
  static const Duration _voteWindow = Duration(seconds: 30);
  static const int _maxVotesPerRoom = 100;

  /// Stream of room alerts
  Stream<RoomAlert> get alertStream => _alertController.stream;

  /// Get current room alerts
  Map<String, RoomAlert> get roomAlerts => Map.unmodifiable(_roomAlerts);

  /// Add a device vote and update consensus
  void addVote(DeviceVote vote) {
    // Add vote to room
    _roomVotes.putIfAbsent(vote.roomId, () => []);
    _roomVotes[vote.roomId]!.add(vote);
    
    // Clean old votes
    _cleanOldVotes(vote.roomId);
    
    // Update consensus for this room
    _updateRoomConsensus(vote.roomId);
  }

  /// Clean old votes from a room
  void _cleanOldVotes(String roomId) {
    final votes = _roomVotes[roomId];
    if (votes == null) return;

    final cutoffTime = DateTime.now().subtract(_voteWindow);
    votes.removeWhere((vote) => vote.timestamp.isBefore(cutoffTime));
    
    // Keep only the most recent votes
    if (votes.length > _maxVotesPerRoom) {
      votes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      votes.removeRange(_maxVotesPerRoom, votes.length);
    }
  }

  /// Update consensus for a specific room
  void _updateRoomConsensus(String roomId) {
    final votes = _roomVotes[roomId];
    if (votes == null || votes.isEmpty) return;

    // Count votes by decision
    final dangerVotes = votes.where((v) => v.isAlert).length;
    final warningVotes = votes.where((v) => v.isWarning).length;
    final normalVotes = votes.where((v) => v.isSafe).length;
    final totalVotes = votes.length;

    // Determine alert level based on consensus rules
    AlertLevel newLevel;
    String? message;

    if (dangerVotes >= 2) {
      // ≥2 Danger → Outbreak
      newLevel = AlertLevel.outbreak;
      message = 'Outbreak detected: $dangerVotes danger votes from $totalVotes devices';
    } else if (dangerVotes >= 1) {
      // 1 Danger → Watch
      newLevel = AlertLevel.watch;
      message = 'Watch alert: $dangerVotes danger vote(s) from $totalVotes devices';
    } else {
      // 0 Danger → Normal
      newLevel = AlertLevel.normal;
      message = 'Normal: $normalVotes normal votes from $totalVotes devices';
    }

    // Create or update room alert
    final currentAlert = _roomAlerts[roomId];
    final newAlert = RoomAlert(
      roomId: roomId,
      level: newLevel,
      votes: List.from(votes),
      timestamp: DateTime.now(),
      message: message,
    );

    // Only emit if level changed or it's a new room
    if (currentAlert == null || currentAlert.level != newLevel) {
      _roomAlerts[roomId] = newAlert;
      _alertController.add(newAlert);
    } else {
      // Update existing alert with new votes
      _roomAlerts[roomId] = newAlert;
    }
  }

  /// Get votes for a specific room
  List<DeviceVote> getRoomVotes(String roomId) {
    return List.from(_roomVotes[roomId] ?? []);
  }

  /// Get statistics for a room
  Map<String, dynamic> getRoomStatistics(String roomId) {
    final votes = _roomVotes[roomId] ?? [];
    
    if (votes.isEmpty) {
      return {
        'totalVotes': 0,
        'dangerVotes': 0,
        'warningVotes': 0,
        'normalVotes': 0,
        'averageProbability': 0.0,
        'lastVote': null,
      };
    }

    final dangerVotes = votes.where((v) => v.isAlert).length;
    final warningVotes = votes.where((v) => v.isWarning).length;
    final normalVotes = votes.where((v) => v.isSafe).length;
    
    final averageProbability = votes
        .map((v) => v.probability)
        .reduce((a, b) => a + b) / votes.length;

    return {
      'totalVotes': votes.length,
      'dangerVotes': dangerVotes,
      'warningVotes': warningVotes,
      'normalVotes': normalVotes,
      'averageProbability': averageProbability,
      'lastVote': votes.isNotEmpty ? votes.last.timestamp : null,
    };
  }

  /// Get all room statistics
  Map<String, Map<String, dynamic>> getAllRoomStatistics() {
    final stats = <String, Map<String, dynamic>>{};
    
    for (final roomId in _roomVotes.keys) {
      stats[roomId] = getRoomStatistics(roomId);
    }
    
    return stats;
  }

  /// Manually reset a room's alert level
  void resetRoomAlert(String roomId) {
    final votes = _roomVotes[roomId];
    if (votes == null) return;

    // Clear all votes for this room
    votes.clear();
    
    // Create normal alert
    final normalAlert = RoomAlert(
      roomId: roomId,
      level: AlertLevel.normal,
      votes: [],
      timestamp: DateTime.now(),
      message: 'Room manually reset to normal',
    );
    
    _roomAlerts[roomId] = normalAlert;
    _alertController.add(normalAlert);
  }

  /// Clear all data
  void clear() {
    _roomVotes.clear();
    _roomAlerts.clear();
  }

  /// Get room count
  int get roomCount => _roomVotes.length;

  /// Get total vote count across all rooms
  int get totalVoteCount {
    return _roomVotes.values
        .map((votes) => votes.length)
        .fold(0, (a, b) => a + b);
  }

  /// Dispose resources
  void dispose() {
    _alertController.close();
  }
}
