import 'package:flutter/material.dart';

class CKPWaveformPainter extends CustomPainter {
  final double crankAngle;
  final double rpm;
  final bool isRunning;

  final bool ckpFault;
  final bool cmpFault;

  final bool ckpNoSignal;

  final Map<int, int> coilFaultModes;

  double getSparkAdvance(double rpm) {
    if (rpm < 900) return 7.5;
    if (rpm < 1500) return 10;
    if (rpm < 2200) return 22;
    if (rpm < 3000) return 28;
    if (rpm < 4000) return 32;
    return 40;
  }

  CKPWaveformPainter({
    required this.crankAngle,
    required this.rpm,
    required this.isRunning,

    required this.ckpFault,
    required this.ckpNoSignal,
    required this.cmpFault,

    required this.coilFaultModes,
  });

  //Chỉnh khung xung
  @override
  void paint(Canvas canvas, Size size) {
    const double waveOffset = 0;
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
    final ign1Path = Path();
    final ign2Path = Path();
    final ign3Path = Path();
    final ign4Path = Path();

    final toothWidth =
        size.width / 120.0;

    double x = 0;

    bool high = false;
    final time = isRunning
        ? DateTime.now()
        .millisecondsSinceEpoch / 1000.0
        : 0.0;

    final speedFactor =
    (rpm / 6000).clamp(0.05, 1.0);

    final phaseShift =
        ((time * 120 * speedFactor) +
            (crankAngle / 6.0)) % 120;

    final sparkAdvance =
    getSparkAdvance(rpm);

    final advanceTeeth =
        sparkAdvance / 6.0;

    final yHigh = size.height * 0.84 + waveOffset;
    final yLow  = size.height * 0.94 + waveOffset;

    final cmpHigh =
        size.height * 0.66 + waveOffset;

    final cmpLow =
        size.height * 0.76 + waveOffset;

    final ignHigh =
        size.height * 0.08 + waveOffset;

    final ignLow =
        size.height * 0.18 + waveOffset;

    final ign1High = size.height * 0.06;
    final ign1Low  = size.height * 0.16;

    final ign2High = size.height * 0.18;
    final ign2Low  = size.height * 0.28;

    final ign3High = size.height * 0.30;
    final ign3Low  = size.height * 0.40;

    final ign4High = size.height * 0.42;
    final ign4Low  = size.height * 0.52;

    path.moveTo(0, yLow);

    for (int tooth = 0; tooth < 120; tooth++) {

      final toothX =
          x + tooth * toothWidth;

      if (ckpNoSignal) {

        path.lineTo(
          toothX,
          yLow,
        );

        path.lineTo(
          toothX + toothWidth,
          yLow,
        );

        continue;
      }

      final realTooth =
          (((tooth - phaseShift).floor()) + 60) % 60;

      final isMissing =
          realTooth == 58 ||
              realTooth == 59;

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



    void drawIgnition(
        Path ignPath,
        double triggerTooth,
        double highY,
        double lowY,
        ) {

      final shiftedTooth =
      ((triggerTooth + phaseShift) % 120);

      final startX =
          shiftedTooth * toothWidth;

      final endX =
          (shiftedTooth + 1) * toothWidth;

      // LOW trước xung
      ignPath.moveTo(0, lowY);

      ignPath.lineTo(
        startX,
        lowY,
      );

      // cạnh lên
      ignPath.lineTo(
        startX,
        highY,
      );

      // HIGH ngang
      ignPath.lineTo(
        endX,
        highY,
      );

      // cạnh xuống
      ignPath.lineTo(
        endX,
        lowY,
      );

      // LOW sau xung
      ignPath.lineTo(
        size.width,
        lowY,
      );
    }
    drawIgnition(
      ign1Path,
      23 - advanceTeeth,
      ign1High,
      ign1Low,
    );

    drawIgnition(
      ign3Path,
      53 - advanceTeeth,
      ign3High,
      ign3Low,
    );

    drawIgnition(
      ign4Path,
      83 - advanceTeeth,
      ign4High,
      ign4Low,
    );

    drawIgnition(
      ign2Path,
      113 - advanceTeeth,
      ign2High,
      ign2Low,
    );

    // =========================
    // CMP DIGITAL OSCILLOSCOPE
    // =========================

    final cmpWave = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final ignWave = Paint()
      ..color = Colors.cyanAccent
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

  void drawIgnLabel(
  String text,
  double y,
  ) {

  final tp = TextPainter(

  text: TextSpan(
  text: text,

  style: const TextStyle(
  color: Colors.cyanAccent,
  fontSize: 10,
  fontWeight: FontWeight.bold,
  ),
  ),

  textDirection: TextDirection.ltr,
  )..layout();

  tp.paint(
  canvas,
  Offset(8, y -2),
  );
  }

  drawIgnLabel('IGN1', ign1High);
  drawIgnLabel('IGN2', ign2High);
  drawIgnLabel('IGN3', ign3High);
  drawIgnLabel('IGN4', ign4High);

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

    // IGN1
    if (ckpNoSignal) {

      final flatIgn1 = Path();

      flatIgn1.moveTo(
        0,
        ign1Low,
      );

      flatIgn1.lineTo(
        size.width,
        ign1Low,
      );

      canvas.drawPath(
        flatIgn1,
        ignWave,
      );

    } else if ((coilFaultModes[1] ?? 0) == 0) {

      canvas.drawPath(
        ign1Path,
        ignWave,
      );
    }

// IGN2
    if (ckpNoSignal) {

      final flatIgn2 = Path();

      flatIgn2.moveTo(
        0,
        ign2Low,
      );

      flatIgn2.lineTo(
        size.width,
        ign2Low,
      );

      canvas.drawPath(
        flatIgn2,
        ignWave,
      );

    } else if ((coilFaultModes[2] ?? 0) == 0) {

      canvas.drawPath(
        ign2Path,
        ignWave,
      );
    }

// IGN3
    if (ckpNoSignal) {

      final flatIgn3 = Path();

      flatIgn3.moveTo(
        0,
        ign3Low,
      );

      flatIgn3.lineTo(
        size.width,
        ign3Low,
      );

      canvas.drawPath(
        flatIgn3,
        ignWave,
      );

    } else if ((coilFaultModes[3] ?? 0) == 0) {

      canvas.drawPath(
        ign3Path,
        ignWave,
      );
    }

// IGN4
    if (ckpNoSignal) {

      final flatIgn4 = Path();

      flatIgn4.moveTo(
        0,
        ign4Low,
      );

      flatIgn4.lineTo(
        size.width,
        ign4Low,
      );

      canvas.drawPath(
        flatIgn4,
        ignWave,
      );

    } else if ((coilFaultModes[4] ?? 0) == 0) {

      canvas.drawPath(
        ign4Path,
        ignWave,
      );
    }

    if (ckpNoSignal || cmpFault) {

      final flatCmp = Path();

      flatCmp.moveTo(
        0,
        cmpLow,
      );

      flatCmp.lineTo(
        size.width,
        cmpLow,
      );

      canvas.drawPath(
        flatCmp,
        cmpWave,
      );

    } else {

      canvas.drawPath(
        cmpPath,
        cmpWave,
      );
    }

    canvas.drawPath(path, wave);

    final currentTooth =
    ((crankAngle % 360) / 6).floor();
  }

  @override
  bool shouldRepaint(
      covariant CKPWaveformPainter oldDelegate) {
    return oldDelegate.crankAngle != crankAngle ||
        oldDelegate.rpm != rpm ||
        oldDelegate.isRunning != isRunning;
  }
}