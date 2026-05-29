import 'package:flutter/material.dart';

class CKPWaveformPainter extends CustomPainter {
  final double crankAngle;
  final double rpm;

  CKPWaveformPainter({
    required this.crankAngle,
    required this.rpm,
  });

  //Chỉnh khung xung
  @override
  void paint(Canvas canvas, Size size) {
    const double waveOffset = -300;
    const double cmpOffset = 20;
    final bg = Paint()
      ..color = const Color(0xFF111111);

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        waveOffset,
        size.width,
        size.height + 20,
      ),
      bg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          0,
          waveOffset,
          size.width,
          size.height + 20,
        ),
        const Radius.circular(6),
      ),
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke,
    );

    final grid = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    for (double gx = 0; gx < size.width; gx += 20) {
      canvas.drawLine(
        Offset(gx, waveOffset),
        Offset(gx, size.height + 20 + waveOffset),
        grid,
      );
    }

    final wave = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF00FF66),
          Color(0xFF00CC44),
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height + 20,
        ),
      )
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final cmpPath = Path();

    final toothWidth =
        size.width / 120.0;

    double x = 0;

    bool high = false;
    final time =
        DateTime.now()
            .millisecondsSinceEpoch / 1000.0;

    final speedFactor =
    (rpm / 6000).clamp(0.05, 1.0);

    final phaseShift =
        ((time * 120 * speedFactor) +
            (crankAngle / 6.0)) % 120;

    final yHigh = size.height * 0.28 + waveOffset;
    final yLow = size.height * 0.62 + waveOffset;

    final cmpHigh =
        size.height * 0.70 + waveOffset + cmpOffset;

    final cmpLow =
        size.height * 0.92 + waveOffset + cmpOffset;

    path.moveTo(0, yLow);

    for (int tooth = 0; tooth < 120; tooth++) {

      final realTooth =
          (((tooth - phaseShift).floor()) + 60) % 60;

      final isMissing =
          realTooth == 58 ||
              realTooth == 59;

      final toothX =
          x + tooth * toothWidth;

      if (isMissing) {

        path.moveTo(
          toothX,
          yLow,
        );

        path.lineTo(
          toothX + toothWidth,
          yLow,
        );

        continue;
      }

      path.lineTo(
        toothX,
        yLow,
      );

      path.lineTo(
        toothX,
        yHigh,
      );

      path.lineTo(
        toothX,
        yHigh,
      );

      path.lineTo(
        toothX + toothWidth * 0.1,
        yHigh,
      );

      path.moveTo(
        toothX + toothWidth * 0.1,
        yHigh,
      );

      path.lineTo(
        toothX + toothWidth * 0.1,
        yLow,
      );
    }

    // =========================
    // CMP DIGITAL OSCILLOSCOPE
    // =========================

    final cmpWave = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final cmpSignals = [
      {'rise': 15,  'fall': 21},
      {'rise': 28,  'fall': 50},
      {'rise': 58,  'fall': 80},
      {'rise': 104, 'fall': 110},
    ];

    bool currentHigh = false;

    cmpPath.moveTo(
      0,
      cmpLow,
    );

    for (double t = 0; t <= 120; t++) {

      final shiftedTooth =
      ((t - phaseShift + 120) % 120);

      bool shouldHigh = false;

      for (final sig in cmpSignals) {

        final rise =
        sig['rise']!.toDouble();

        final fall =
        sig['fall']!.toDouble();

        if (shiftedTooth >= rise &&
            shiftedTooth <= fall) {

          shouldHigh = true;
          break;
        }
      }

      final x =
          t * toothWidth;

      // tạo cạnh vuông
      if (shouldHigh != currentHigh) {

        cmpPath.lineTo(
          x,
          currentHigh
              ? cmpHigh
              : cmpLow,
        );

        cmpPath.lineTo(
          x,
          shouldHigh
              ? cmpHigh
              : cmpLow,
        );

        currentHigh = shouldHigh;
      }

      // kéo ngang
      cmpPath.lineTo(
        x,
        currentHigh
            ? cmpHigh
            : cmpLow,
      );
    }

    // kéo tới cuối
    cmpPath.lineTo(
      size.width,
      currentHigh
          ? cmpHigh
          : cmpLow,
    );

    // =========================
    // LABEL CKP / CMP
    // =========================

    final ckpText = TextPainter(
      text: const TextSpan(
        text: 'CKP',
        style: TextStyle(
          color: Colors.greenAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    ckpText.paint(
      canvas,
      Offset(
        8,
        yHigh - 18,
      ),
    );

    final cmpText = TextPainter(
      text: const TextSpan(
        text: 'CMP',
        style: TextStyle(
          color: Colors.orangeAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    cmpText.paint(
      canvas,
      Offset(
        8,
        cmpHigh - 18,
      ),
    );

    canvas.drawPath(
      cmpPath,
      cmpWave,
    );

    canvas.drawPath(path, wave);

    final currentTooth =
    ((crankAngle % 360) / 6).floor();
  }

  @override
  bool shouldRepaint(
      covariant CKPWaveformPainter oldDelegate) {
    return oldDelegate.crankAngle !=
        crankAngle;
  }
}