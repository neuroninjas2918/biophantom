import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:biophantom_core/biophantom_core.dart';
import '../services/bluetooth_host.dart';
import '../services/consensus_engine.dart';

class RoomDashboardScreen extends StatefulWidget {
  final BluetoothHostService bluetoothService;
  final ConsensusEngine consensusEngine;

  const RoomDashboardScreen({
    super.key,
    required this.bluetoothService,
    required this.consensusEngine,
  });

  @override
  State<RoomDashboardScreen> createState() => _RoomDashboardScreenState();
}

class _RoomDashboardScreenState extends State<RoomDashboardScreen> {
  Map<String, RoomAlert> _roomAlerts = {};
  Map<String, Map<String, dynamic>> _roomStatistics = {};
  bool _isLoading = true;
  // Subscriptions so we can cancel listeners on dispose and avoid leaks
  StreamSubscription<RoomAlert>? _alertSubscription;
  StreamSubscription<DeviceVote>? _voteSubscription;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _loadData();
  }

  void _setupListeners() {
    // Listen to room alerts
    _alertSubscription = widget.consensusEngine.alertStream.listen((alert) {
      if (mounted) {
        setState(() {
          _roomAlerts[alert.roomId] = alert;
        });
      }
    });

    // Listen to device votes
    _voteSubscription = widget.bluetoothService.votesStream.listen((vote) {
      if (mounted) {
        // Update statistics
        _updateStatistics();
      }
    });
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    _voteSubscription?.cancel();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _roomAlerts = widget.consensusEngine.roomAlerts;
      _roomStatistics = widget.consensusEngine.getAllRoomStatistics();
      _isLoading = false;
    });
  }

  void _updateStatistics() {
    setState(() {
      _roomStatistics = widget.consensusEngine.getAllRoomStatistics();
    });
  }

  Future<void> _startAdvertising() async {
    try {
      await widget.bluetoothService.startAdvertising();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Started advertising as Mainframe')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start advertising: $e')),
        );
      }
    }
  }

  Future<void> _stopAdvertising() async {
    try {
      await widget.bluetoothService.stopAdvertising();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stopped advertising')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop advertising: $e')),
        );
      }
    }
  }

  void _resetRoom(String roomId) {
    widget.consensusEngine.resetRoomAlert(roomId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room $roomId reset to normal')),
      );
    }
  }

  void _showRoomDetail(String roomId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailScreen(
          roomId: roomId,
          bluetoothService: widget.bluetoothService,
          consensusEngine: widget.consensusEngine,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Dashboard'),
        actions: [
          // Bluetooth status
          StreamBuilder<BluetoothConnectionState>(
            stream: widget.bluetoothService.connectionStream,
            builder: (context, snapshot) {
              final isConnected = snapshot.data == BluetoothConnectionState.connected;
              return Icon(
                isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: isConnected ? Colors.green : Colors.grey,
              );
            },
          ),
          const SizedBox(width: 8),
          // Advertising status
          Icon(
            widget.bluetoothService.isAdvertising ? Icons.bluetooth : Icons.bluetooth_disabled,
            color: widget.bluetoothService.isAdvertising ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Control panel
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mainframe Control',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: widget.bluetoothService.isAdvertising 
                                    ? _stopAdvertising 
                                    : _startAdvertising,
                                icon: Icon(widget.bluetoothService.isAdvertising 
                                    ? Icons.stop 
                                    : Icons.play_arrow),
                                label: Text(widget.bluetoothService.isAdvertising 
                                    ? 'Stop Advertising' 
                                    : 'Start Advertising'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _updateStatistics,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connected Devices: ${widget.bluetoothService.connectedDevicesCount}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Total Votes: ${widget.consensusEngine.totalVoteCount}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Rooms list
                Expanded(
                  child: _roomAlerts.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.room, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No rooms detected',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start advertising and wait for device connections',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _roomAlerts.length,
                          itemBuilder: (context, index) {
                            final roomId = _roomAlerts.keys.elementAt(index);
                            final alert = _roomAlerts[roomId]!;
                            final stats = _roomStatistics[roomId] ?? {};
                            
                            return _buildRoomCard(roomId, alert, stats);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildRoomCard(String roomId, RoomAlert alert, Map<String, dynamic> stats) {
    Color statusColor;
    IconData statusIcon;
    
    switch (alert.level) {
      case AlertLevel.outbreak:
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
      case AlertLevel.watch:
        statusColor = Colors.orange;
        statusIcon = Icons.info;
        break;
      case AlertLevel.normal:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          'Room $roomId',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${alert.levelText}'),
            Text('Votes: ${stats['totalVotes'] ?? 0} (D: ${stats['dangerVotes'] ?? 0}, W: ${stats['warningVotes'] ?? 0}, N: ${stats['normalVotes'] ?? 0})'),
            if (stats['averageProbability'] != null)
              Text('Avg Probability: ${(stats['averageProbability'] * 100).toStringAsFixed(1)}%'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showRoomDetail(roomId),
              icon: const Icon(Icons.visibility),
              tooltip: 'View Details',
            ),
            if (alert.level != AlertLevel.normal)
              IconButton(
                onPressed: () => _resetRoom(roomId),
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset Room',
              ),
          ],
        ),
        onTap: () => _showRoomDetail(roomId),
      ),
    );
  }
}

class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  final BluetoothHostService bluetoothService;
  final ConsensusEngine consensusEngine;

  const RoomDetailScreen({
    super.key,
    required this.roomId,
    required this.bluetoothService,
    required this.consensusEngine,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  List<DeviceVote> _votes = [];
  RoomAlert? _currentAlert;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadRoomData();
  }

  void _loadRoomData() {
    setState(() {
      _votes = widget.consensusEngine.getRoomVotes(widget.roomId);
      _currentAlert = widget.consensusEngine.roomAlerts[widget.roomId];
      _statistics = widget.consensusEngine.getRoomStatistics(widget.roomId);
    });
  }

  void _resetRoom() {
    widget.consensusEngine.resetRoomAlert(widget.roomId);
    _loadRoomData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room ${widget.roomId} reset to normal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room ${widget.roomId}'),
        actions: [
          IconButton(
            onPressed: _resetRoom,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Room',
          ),
        ],
      ),
      body: Column(
        children: [
          // Current alert status
          if (_currentAlert != null) ...[
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _currentAlert!.isOutbreak ? Icons.warning :
                          _currentAlert!.isWatch ? Icons.info :
                          Icons.check_circle,
                          color: _currentAlert!.isOutbreak ? Colors.red :
                                 _currentAlert!.isWatch ? Colors.orange :
                                 Colors.green,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentAlert!.levelText,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _currentAlert!.isOutbreak ? Colors.red :
                                         _currentAlert!.isWatch ? Colors.orange :
                                         Colors.green,
                                ),
                              ),
                              if (_currentAlert!.message != null)
                                Text(_currentAlert!.message!),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // Statistics
          if (_statistics.isNotEmpty) ...[
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistics',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total',
                            _statistics['totalVotes'].toString(),
                            Icons.analytics,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Danger',
                            _statistics['dangerVotes'].toString(),
                            Icons.warning,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Warning',
                            _statistics['warningVotes'].toString(),
                            Icons.info,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Normal',
                            _statistics['normalVotes'].toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Votes list
          Expanded(
            child: _votes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.poll, size: 64.0, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No votes received',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _votes.length,
                    itemBuilder: (context, index) {
                      final vote = _votes[index];
                      return _buildVoteCard(vote);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteCard(DeviceVote vote) {
    Color decisionColor;
    IconData decisionIcon;
    
    switch (vote.decision) {
      case Decision.danger:
        decisionColor = Colors.red;
        decisionIcon = Icons.warning;
        break;
      case Decision.watch:
        decisionColor = Colors.orange;
        decisionIcon = Icons.info;
        break;
      case Decision.normal:
        decisionColor = Colors.green;
        decisionIcon = Icons.check_circle;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: decisionColor.withOpacity(0.1),
          child: Icon(decisionIcon, color: decisionColor),
        ),
        title: Text(
          'Device ${vote.deviceId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Decision: ${vote.decisionText}'),
            Text('Probability: ${(vote.probability * 100).toStringAsFixed(1)}%'),
            Text('Time: ${_formatTimestamp(vote.timestamp)}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: decisionColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: decisionColor.withOpacity(0.3)),
          ),
          child: Text(
            '${(vote.probability * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: decisionColor,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
