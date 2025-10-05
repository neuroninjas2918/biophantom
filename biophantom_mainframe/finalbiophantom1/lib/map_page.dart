import 'package:flutter/material.dart';
// Removed unused import
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Map'),
        backgroundColor: Colors.blue,
        elevation: 8,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 3.0,
          boundaryMargin: const EdgeInsets.all(80),
          child: CustomPaint(
            size: const Size(350, 500),
            painter: IrregularMapPainter(),
            child: MapButtonsOverlay(),
          ),
        ),
      ),
    );
  }
}

class IrregularMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade200
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Draw irregular map shape
    final path = Path();
    path.moveTo(30, 60);
    path.lineTo(80, 40);
    path.quadraticBezierTo(120, 20, 180, 60);
    path.lineTo(320, 80);
    path.quadraticBezierTo(340, 120, 300, 200);
    path.lineTo(250, 400);
    path.quadraticBezierTo(180, 480, 80, 420);
    path.lineTo(40, 300);
    path.quadraticBezierTo(10, 200, 30, 60);
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MapButtonsOverlay extends StatelessWidget {
  const MapButtonsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // Example: 5 animated buttons at custom positions
    return Stack(
      children: [
        AnimatedMapButton(left: 60, top: 80, label: 'Lab'),
        AnimatedMapButton(left: 220, top: 120, label: 'Storage'),
        AnimatedMapButton(left: 180, top: 320, label: 'Control'),
        AnimatedMapButton(left: 90, top: 380, label: 'Exit'),
        AnimatedMapButton(left: 270, top: 220, label: 'Office'),
      ],
    );
  }
}

class AnimatedMapButton extends StatefulWidget {
  final double left;
  final double top;
  final String label;
  const AnimatedMapButton({required this.left, required this.top, required this.label, super.key});

  @override
  State<AnimatedMapButton> createState() => _AnimatedMapButtonState();
}

class _AnimatedMapButtonState extends State<AnimatedMapButton> with TickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _tapScaleAnim;
  late AnimationController _idleController;
  late Animation<double> _idleScaleAnim;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _tapScaleAnim = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOutBack),
    );
    _idleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _idleScaleAnim = Tween<double>(begin: 0.98, end: 1.02).animate(CurvedAnimation(parent: _idleController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tapController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  void _onTap() {
    _tapController.forward(from: 0).then((_) => _tapController.reverse());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected: ${widget.label}')),
    );
  }

  void _onLongPress() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Details about this location. You can add live metrics, capacity, and status here.'),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: () { Navigator.pop(context); _onTap(); }, child: const Text('Mark Visited')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.left,
      top: widget.top,
      child: ScaleTransition(
        scale: _idleScaleAnim,
        child: ScaleTransition(
          scale: _tapScaleAnim,
          child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade400,
            shape: const StadiumBorder(),
            elevation: 8,
            shadowColor: Colors.blueAccent,
          ),
          onPressed: _onTap,
          onLongPress: _onLongPress,
          child: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        ),
      ),
    );
  }
}
