import 'package:flutter/material.dart';
import 'services/community_alert.dart';

class OrganizationDashboardScreen extends StatefulWidget {
  const OrganizationDashboardScreen({super.key});

  @override
  State<OrganizationDashboardScreen> createState() => _OrganizationDashboardScreenState();
}

class _AnimatedCounter extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color backgroundColor;

  const _AnimatedCounter({
    required this.label,
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w600)),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 600),
            builder: (context, val, _) => Text('$val', style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool safe;
  const _StatusChip({required this.safe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = safe ? theme.colorScheme.secondary : theme.colorScheme.error;
    final onColor = safe ? theme.colorScheme.onSecondary : theme.colorScheme.onError;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(safe ? Icons.check_circle : Icons.error, color: onColor, size: 16),
          const SizedBox(width: 6),
          Text(safe ? 'Safe' : 'Risk', style: TextStyle(color: onColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class Room {
  String name;
  bool isSafe;
  double threatLevel; // 0.0 to 1.0

  Room({required this.name, this.isSafe = true, this.threatLevel = 0.0});
}

class _OrganizationDashboardScreenState extends State<OrganizationDashboardScreen> {
  final List<Room> _rooms = [
    Room(name: 'Lab A-1', threatLevel: 0.1),
    Room(name: 'Lab A-2', threatLevel: 0.2),
    Room(name: 'Storage B-1', isSafe: false, threatLevel: 0.8),
    Room(name: 'Lab B-2', threatLevel: 0.0),
    Room(name: 'Common Area', threatLevel: 0.3),
    Room(name: 'Server Room', isSafe: false, threatLevel: 0.9),
    Room(name: 'Office 1', threatLevel: 0.1),
    Room(name: 'Office 2', threatLevel: 0.0),
  ];

  bool get _hasAlert => CommunityAlertService.instance.hasAlert;

  int get totalSafe => _hasAlert ? 0 : _rooms.where((r) => r.isSafe).length;
  int get totalRisk => _hasAlert ? _rooms.length : _rooms.where((r) => !r.isSafe).length;
  int get totalRooms => _rooms.length;

  void sealArea(int index) {
    setState(() {
      _rooms[index].isSafe = true;
      _rooms[index].threatLevel = 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_rooms[index].name} has been secured.'), backgroundColor: Colors.green),
    );
  }

  @override
  void initState() {
    super.initState();
    // Listen for community alerts and refresh UI on change
    CommunityAlertService.instance.addListener(_onAlertChanged);
  }

  void _onAlertChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    CommunityAlertService.instance.removeListener(_onAlertChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AnimatedCounter(label: 'Total', value: totalRooms, color: theme.colorScheme.onPrimaryContainer, backgroundColor: theme.colorScheme.primaryContainer),
                const SizedBox(width: 12),
                _AnimatedCounter(label: 'Safe', value: totalSafe, color: theme.colorScheme.onSecondaryContainer, backgroundColor: theme.colorScheme.secondaryContainer),
                const SizedBox(width: 12),
                _AnimatedCounter(label: 'Risk', value: totalRisk, color: theme.colorScheme.onErrorContainer, backgroundColor: theme.colorScheme.errorContainer),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Room Status:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxis = (width / 200).floor().clamp(2, 6);
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxis,
                      childAspectRatio: 3 / 2.5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _rooms.length,
                    itemBuilder: (context, index) {
                      final room = _rooms[index];
                      final isAtRisk = _hasAlert || !room.isSafe;
                      final threatLevel = _hasAlert ? 1.0 : room.threatLevel;

                      return Card(
                        elevation: isAtRisk ? 8 : 2,
                        shadowColor: isAtRisk ? theme.colorScheme.error : theme.shadowColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: isAtRisk ? () => sealArea(index) : null,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.room, color: isAtRisk ? Colors.red : Colors.green),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    _StatusChip(safe: !isAtRisk),
                                  ],
                                ),
                                const Spacer(),
                                Text('Threat Level', style: theme.textTheme.bodySmall),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: threatLevel,
                                  backgroundColor: theme.colorScheme.surfaceVariant,
                                  color: Color.lerp(Colors.green, theme.colorScheme.error, threatLevel),
                                  minHeight: 6,
                                ),
                                if (isAtRisk)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Center(
                                      child: TextButton.icon(
                                        icon: const Icon(Icons.security, size: 16),
                                        label: const Text('Seal Area'),
                                        onPressed: () => sealArea(index),
                                        style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.call),
                  onPressed: () {
                    // Simulate emergency call
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency help called!')));
                  },
                  label: const Text('Call Help'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.security),
                  onPressed: () {
                    // Simulate sealing all risky areas
                    setState(() {
                      for (var room in _rooms) {
                        if (!room.isSafe) {
                          room.isSafe = true;
                          room.threatLevel = 0.0;
                        }
                      }
                    });
                  },
                  label: const Text('Seal All Risky Areas'),
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
