import 'package:flutter/material.dart';

class ProbSparkline extends StatelessWidget {
  final List<double> probabilities;
  final double height;
  final Color color;

  const ProbSparkline({
    super.key,
    required this.probabilities,
    this.height = 40,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    if (probabilities.isEmpty) {
      return Container(
        height: height,
        color: Colors.grey[200],
        child: const Center(
          child: Text(
            'No data',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomPaint(
        painter: _SparklinePainter(probabilities: probabilities, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> probabilities;
  final Color color;

  _SparklinePainter({required this.probabilities, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (probabilities.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    final dx = size.width / (probabilities.length - 1);
    final maxY = probabilities.reduce((a, b) => a > b ? a : b);
    final minY = probabilities.reduce((a, b) => a < b ? a : b);
    final range = maxY - minY > 0 ? maxY - minY : 1;

    for (int i = 0; i < probabilities.length; i++) {
      final x = i * dx;
      final y = size.height - ((probabilities[i] - minY) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
