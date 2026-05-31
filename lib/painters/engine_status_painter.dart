import 'package:flutter/material.dart';

class EngineStatusPainter extends CustomPainter {
  final double rpm;
  final bool isRunning;

  EngineStatusPainter({
    required this.rpm,
    required this.isRunning,
  });

  double getSparkAdvance(double rpm) {
    if (rpm < 900) return 7.5;
    if (rpm < 1500) return 15;
    if (rpm < 2200) return 22;
    if (rpm < 3000) return 28;
    if (rpm < 4000) return 35;
    return 40;
  }

  double getInjectionAdvance(double rpm) {
    if (rpm < 900) return 10;
    if (rpm < 1500) return 18;
    if (rpm < 2200) return 22;
    if (rpm < 3000) return 30;
    if (rpm < 4000) return 38;
    return 42;
  }

  double getInjectionPulseWidth(double rpm) {
    if (rpm < 900) return 2.7;
    if (rpm < 1500) return 2.8;
    if (rpm < 2200) return 3.2;
    if (rpm < 3000) return 3.8;
    if (rpm < 4000) return 4.5;
    return 5;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sparkAdv = getSparkAdvance(rpm);
    final injAdv = getInjectionAdvance(rpm);
    final injPw = getInjectionPulseWidth(rpm);

    final spark1 = (720 - sparkAdv) % 720;
    final spark2 = (spark1 + 180) % 720;
    final spark3 = (spark1 + 540) % 720;
    final spark4 = (spark1 + 360) % 720;

    final inj1 = (360 - injAdv) % 720;
    final inj2 = (inj1 + 180) % 720;
    final inj3 = (inj1 + 540) % 720;
    final inj4 = (inj1 + 360) % 720;

    final lines = [
      'RPM ${rpm.toInt()}  CYL   SPK   INJ   PW',

      'ADV        1    '
          '${spark1.toStringAsFixed(0)}°  '
          '${inj1.toStringAsFixed(0)}°  '
          '${injPw.toStringAsFixed(1)}',

      'SPK ${sparkAdv.toStringAsFixed(0)}°    2    '
          '${spark2.toStringAsFixed(0)}°  '
          '${inj2.toStringAsFixed(0)}°  '
          '${injPw.toStringAsFixed(1)}',

      'INJ ${injAdv.toStringAsFixed(0)}°    3    '
          '${spark3.toStringAsFixed(0)}°  '
          '${inj3.toStringAsFixed(0)}°  '
          '${injPw.toStringAsFixed(1)}',

      '           4    '
          '${spark4.toStringAsFixed(0)}°  '
          '${inj4.toStringAsFixed(0)}°  '
          '${injPw.toStringAsFixed(1)}',
    ];

    final tp = TextPainter(
      text: TextSpan(
        text: lines.join('\n'),
        style: TextStyle(
          color: isRunning
              ? Colors.white70
              : Colors.white70,
          fontSize: 12,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width - tp.width - 440,
        size.height - tp.height + 130,
        tp.width + 12,
        tp.height + 10,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(
      bgRect,
      Paint()..color = Colors.black,
    );

    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = Colors.grey.withOpacity(0.4)
        ..style = PaintingStyle.stroke,
    );

    tp.paint(
      canvas,
      Offset(
        size.width - tp.width - 436,
        size.height - tp.height + 134,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant EngineStatusPainter oldDelegate) {
    return oldDelegate.rpm != rpm ||
        oldDelegate.isRunning != isRunning;
  }
}