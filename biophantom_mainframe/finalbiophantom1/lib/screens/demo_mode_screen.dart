import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:biophantom_core/biophantom_core.dart';
import '../services/consensus_engine.dart';
import '../services/bluetooth_host.dart';

class MainframeDemoModeScreen extends StatefulWidget {
  final ConsensusEngine consensusEngine;
  final BluetoothHostService bluetoothService;

  const MainframeDemoModeScreen({
    super.key,
    required this.consensusEngine,
    required this.bluetoothService,
  });

  @override
  State<MainframeDemoModeScreen> createState() => _MainframeDemoModeScreenState();
}

class _MainframeDemoModeScreenState extends State<MainframeDemoModeScreen> {
  bool _isDemoRunning = false;
  Timer? _demoTimer;

  // Demo data
  final Map<String, List<DeviceVote>> _demoVotes = {};
  RoomAlert? _lastAlert;

  // Demo configuration
  double _demoDangerRate = 0.1;
  int _demoDeviceCount = 3;
  bool _demoSpikeMode = false;
  int _spikeCounter = 0;

  @override
  void initState() {
    super.initState();
    // Listen to consensus engine alerts
    widget.consensusEngine.alertStream.listen((alert) {
      if (mounted) {
        setState(() {
          _lastAlert = alert;
        });
      }
    });
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    super.dispose();
  }

  void _startDemo() {
    if (_isDemoRunning) return;

    setState(() {
      _isDemoRunning = true;
    });

    _demoTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _generateDemoVotes();
    });
  }

  void _stopDemo() {
    _demoTimer?.cancel();
    setState(() {
      _isDemoRunning = false;
    });
  }

  void _generateDemoVotes() {
    final random = Random();
    final timestamp = DateTime.now();

    // Generate votes from simulated devices
    for (int deviceId = 1; deviceId <= _demoDeviceCount; deviceId++) {
      final deviceName = 'demo_device_$deviceId';
      final roomId = 'demo_room_001';

      // Determine probability based on demo settings
      double probability;
      Decision decision;

      if (_demoSpikeMode && _spikeCounter > 0) {
        // Generate high danger probabilities during spike
        probability = 0.8 + random.nextDouble() * 0.2;
        decision = Decision.danger;
        _spikeCounter--;
        if (_spikeCounter == 0) {
          _demoSpikeMode = false;
        }
      } else {
        // Normal operation with occasional danger
        if (random.nextDouble() < _demoDangerRate) {
          probability = 0.7 + random.nextDouble() * 0.3;
          decision = probability > 0.8 ? Decision.danger : Decision.watch;
        } else {
          probability = random.nextDouble() * 0.6;
          decision = Decision.normal;
        }

        // Occasionally trigger spike mode
        if (random.nextDouble() < 0.05) {
          _demoSpikeMode = true;
          _spikeCounter = 5; // 5 high danger readings
        }
      }

      // Create vote
      final vote = DeviceVote(
        deviceId: deviceName,
        roomId: roomId,
        probability: probability,
        decision: decision,
        timestamp: timestamp,
      );

      // Add to consensus engine
      widget.consensusEngine.addVote(vote);

      // Store for display
      _demoVotes.putIfAbsent(roomId, () => []);
      _demoVotes[roomId]!.add(vote);

      // Keep only recent votes
      if (_demoVotes[roomId]!.length > 20) {
        _demoVotes[roomId]!.removeAt(0);
      }
    }
  }

  void _resetDemo() {
    _stopDemo();
    widget.consensusEngine.clear();
    setState(() {
      _demoVotes.clear();
      _lastAlert = null;
      _demoSpikeMode = false;
      _spikeCounter = 0;
    });
  }

  void _triggerSpike() {
    setState(() {
      _demoSpikeMode = true;
      _spikeCounter = 8; // 8 high danger readings
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mainframe Demo Mode'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Demo info card
            Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science, color: Colors.indigo.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Mainframe Demo Mode',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This mode simulates multiple devices sending votes to demonstrate consensus-based room alerts. No real BLE communication is used.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Control buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDemoRunning ? _stopDemo : _startDemo,
                    icon: Icon(_isDemoRunning ? Icons.stop : Icons.play_arrow),
                    label: Text(_isDemoRunning ? 'Stop Demo' : 'Start Demo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _triggerSpike,
                  icon: const Icon(Icons.warning),
                  label: const Text('Trigger Outbreak'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _resetDemo,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Demo configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Configuration',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Danger Rate'),
                      subtitle: Slider(
                        value: _demoDangerRate,
                        min: 0.0,
                        max: 0.5,
                        divisions: 50,
                        label: '${(_demoDangerRate * 100).toStringAsFixed(1)}%',
                        onChanged: (value) {
                          setState(() {
                            _demoDangerRate = value;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Device Count'),
                      subtitle: Slider(
                        value: _demoDeviceCount.toDouble(),
                        min: 1.0,
                        max: 10.0,
                        divisions: 9,
                        label: _demoDeviceCount.toString(),
                        onChanged: (value) {
                          setState(() {
                            _demoDeviceCount = value.toInt();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Current room alert
            if (_lastAlert != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Room Alert',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAlertCard(
                              'Room',
                              _lastAlert!.roomId,
                              Icons.room,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildAlertCard(
                              'Level',
                              _lastAlert!.levelText,
                              _lastAlert!.isOutbreak ? Icons.warning :
                              _lastAlert!.isWatch ? Icons.info : Icons.check_circle,
                              _lastAlert!.isOutbreak ? Colors.red :
                              _lastAlert!.isWatch ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Danger Votes: ${_lastAlert!.dangerVoteCount}'),
                      Text('Total Votes: ${_lastAlert!.totalVoteCount}'),
                      if (_lastAlert!.message != null) ...[
                        const SizedBox(height: 8),
                        Text(_lastAlert!.message!),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],

            // Recent votes
            if (_demoVotes.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Demo Votes',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      ..._demoVotes.entries.expand((entry) {
                        final roomId = entry.key;
                        final votes = entry.value;
                        return [
                          Text('Room: $roomId', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...votes.take(5).map((vote) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Expanded(child: Text(vote.deviceId)),
                                Text('${(vote.probability * 100).toStringAsFixed(1)}%'),
                                const SizedBox(width: 8),
                                Text(vote.decision.name),
                              ],
                            ),
                          )),
                          const SizedBox(height: 12),
                        ];
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],

            // Demo statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Statistics',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Votes',
                            widget.consensusEngine.totalVoteCount.toString(),
                            Icons.analytics,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Rooms',
                            widget.consensusEngine.roomCount.toString(),
                            Icons.room,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Spike Mode',
                            _demoSpikeMode ? 'Active' : 'Inactive',
                            Icons.warning,
                            _demoSpikeMode ? Colors.orange : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'BLE Status',
                            widget.bluetoothService.isAdvertising ? 'Advertising' : 'Not Advertising',
                            Icons.bluetooth,
                            widget.bluetoothService.isAdvertising ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(String label, String value, IconData icon, Color color) {
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
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
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
              fontSize: 16,
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
}