import 'dart:math';
import 'package:flutter/material.dart';

class FuelInjectorPainter extends CustomPainter {
  final double progress;

  FuelInjectorPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    double intensity = 1;
    int particleCount = 80;

    final rand = Random(1);

    for (int i = 0; i < particleCount; i++) {
      double t = (i / particleCount + progress) % 1;
      double y = t * size.height;

      double spread = (y / size.height) * 60;
      double x = centerX + (rand.nextDouble() - 0.5) * spread;

      double radius = 1.5 + rand.nextDouble() * 2;
      double opacity = (1 - t) * intensity;

      final paint = Paint()
        ..color = Colors.red.withOpacity(opacity);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StaticInjectorPainter extends CustomPainter {
  final bool isActive;

  StaticInjectorPainter({this.isActive = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return; // ❗ không phun nếu không active

    final centerX = size.width / 2;

    final conePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blueAccent.withOpacity(1),
          Colors.blueAccent.withOpacity(0.5),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    Path cone = Path();
    cone.moveTo(centerX, 0);
    cone.lineTo(centerX - size.width * 0.3, size.height * 0.6);
    cone.lineTo(centerX + size.width * 0.6, size.height * 0.6);
    cone.close();

    canvas.drawPath(cone, conePaint);

    // 🌫 mist nhẹ
    final rand = Random(2);
    for (int i = 0; i < 50; i++) {
      double t = rand.nextDouble();
      double y = t * size.height * 0.6;
      double spread = (y / size.height) * size.width * 0.3;

      double x = centerX + (rand.nextDouble() - 0.5) * spread;

      final paint = Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawCircle(Offset(x, y), 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}