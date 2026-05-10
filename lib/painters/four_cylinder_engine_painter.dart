import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class FourCylinderEnginePainter extends CustomPainter {
  final double crankAngle;
  final Set<int> activeSparkCylinders;
  final int injectorCylinder;
  final bool isRunning;
  final Map<int, bool> injectorFaults;
  final Map<int, bool> coilFaults;
  final bool ckpFault;
  final bool cmpFault;

  double get flowOffset =>
      (DateTime.now().millisecondsSinceEpoch % 1000) / 1000;
  bool get blinkOn =>
      (DateTime.now().millisecondsSinceEpoch ~/ 400) % 2 == 0;

  FourCylinderEnginePainter({
    required this.crankAngle,
    required this.activeSparkCylinders,
    required this.injectorCylinder,
    required this.isRunning,
    required this.injectorFaults,
    required this.coilFaults,
    required this.ckpFault,
    required this.cmpFault,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black,
    );

    final blueWall = Paint()
      ..color = const Color(0xFF757575)
      ..style = PaintingStyle.fill;

    final darkMetal = Paint()
      ..color = const Color(0xFF3E434A)
      ..style = PaintingStyle.fill;

    final whiteMetal = Paint()
      ..color = const Color(0xFFF3F3F3)
      ..style = PaintingStyle.fill;

    final outline = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final centers = [
      size.width * 0.12,
      size.width * 0.37,
      size.width * 0.62,
      size.width * 0.87,
    ];

    final cylinders = [1, 2, 3, 4];

    final phaseOffsetsByCylinder = {
      1: 0.0,
      2: 180.0,
      3: 540.0,
      4: 360.0,
    };

    final pistonOffsetsByCylinder = {
      1: 0.0,
      2: 180.0,
      3: 180.0,
      4: 0.0,
    };

    for (int i = 0; i < 4; i++) {
      final cylinder = cylinders[i];
      final bool hasInjectorFault = injectorFaults[cylinder] ?? false;
      final bool hasCoilFault = coilFaults[cylinder] ?? false;
      final bool effectiveInjectorOn =
          injectorCylinder == cylinder && !hasInjectorFault;
      final bool hasMixture = !hasInjectorFault;

      _drawCylinder(
        canvas,
        size,
        centerX: centers[i],
        phase: (crankAngle + phaseOffsetsByCylinder[cylinder]!) % 720,
        pistonTheta:
        (crankAngle + pistonOffsetsByCylinder[cylinder]!) * pi / 180.0,
        label: '$cylinder',
        sparkOn: activeSparkCylinders.contains(cylinder) && hasMixture,
        injectorOn: effectiveInjectorOn,
        hasMixture: hasMixture,
        coilFault: hasCoilFault,
        outline: outline,
        metal: whiteMetal,
        blueWall: blueWall,
        darkMetal: darkMetal,
      );

      if (ckpFault ||
          cmpFault ||
          (injectorFaults[cylinder] ?? false) ||
          (coilFaults[cylinder] ?? false)) {
        _drawCheckEngineWarning(
          canvas,
          centerX: centers[i],
          visible: blinkOn,
        );
      }
    }

    _drawStatusText(canvas, size);
  }
  void _drawCheckEngineWarning(
      Canvas canvas, {
        required double centerX,
        required bool visible,
      }) {
    if (!visible) return;

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'CHECK\nENGINE',
        style: TextStyle(
          color: Color(0xFFFF9800),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 0.95,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, 235),
        width: 44,
        height: 24,
      ),
      const Radius.circular(4),
    );

    canvas.drawRRect(
      rect,
      Paint()..color = const Color(0xCC1A1A1A),
    );

    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFFFF9800)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, 225),
    );
  }

  void drawUnifiedFlow(
      Canvas canvas,
      double centerX,
      double phase,
      double flowOffset,
      ) {
    const manifoldY = 70.0;
    const chamberY = 90.0;

    double t = phase / 720;

    // 🔁 PATH LIỀN MẠCH
    final path = Path()
      ..moveTo(centerX - 35, manifoldY)

    // hút vào
      ..quadraticBezierTo(centerX , manifoldY - 8, centerX - 10, manifoldY)

    // qua valve
      ..quadraticBezierTo(centerX - 5, manifoldY + 18, centerX, manifoldY + 35)

    // xuống buồng đốt
      ..quadraticBezierTo(centerX + 20, manifoldY + 65, centerX, chamberY)

    // xoáy trong buồng
      ..quadraticBezierTo(centerX - 20, chamberY + 10, centerX, chamberY + 20)
      ..quadraticBezierTo(centerX + 20, chamberY + 10, centerX, chamberY)

    // đi ra xả
      ..quadraticBezierTo(centerX + 20, manifoldY + 10, centerX + 40, manifoldY)
      ..lineTo(centerX + 70, manifoldY);

    // 🎨 MÀU THEO CHU KỲ
    final colors = _flowColorsForPhase(phase);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1 + flowOffset * 2, 0),
        end: Alignment(1 + flowOffset * 2, 0),
        colors: colors,
      ).createShader(
        Rect.fromLTWH(centerX - 60, manifoldY - 10, 140, 60),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 // 👈 độ dày
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(path, paint);
  }
  void _drawGasState(
      Canvas canvas, {
        required Rect boreRect,
        required Rect pistonRect,
        required double phase,
      }) {
    final chamberBottom = pistonRect.top;
    if (chamberBottom <= boreRect.top + 2) return;

    final chamberRect = Rect.fromLTRB(
      boreRect.left,
      boreRect.top,
      boreRect.right,
      chamberBottom,
    );

    if (phase >= 0 && phase < 180) {
      final burnT = (phase / 180).clamp(0.0, 1.0);
      final flameHeight = chamberRect.height * (0.35 + burnT * 0.6);

      final flameRect = Rect.fromLTRB(
        chamberRect.left + 2,
        chamberRect.top + 2,
        chamberRect.right - 2,
        min(chamberRect.bottom - 1, chamberRect.top + flameHeight),
      );

      canvas.drawRect(
        flameRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF176),
              Color(0xFFFF9800),
              Color(0xFFE53935),
            ],
          ).createShader(flameRect),
      );
      return;
    }

    if (phase >= 180 && phase < 360) {
      canvas.drawRect(
        chamberRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xAA424242),
              Color(0xCC212121),
              Color(0xDD000000),
            ],
          ).createShader(chamberRect),
      );
      return;
    }

    if (phase >= 360 && phase < 540) {
      canvas.drawRect(
        chamberRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x6638BDF8),
              Color(0x884FC3F7),
              Color(0x5538BDF8),
            ],
          ).createShader(chamberRect),
      );
      return;
    }

    canvas.drawRect(
      chamberRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x66B0BEC5),
            Color(0x668D99AE),
            Color(0x55737474),
          ],
        ).createShader(chamberRect),
    );
  }

  double _phaseLiftWindow(double phase, double startDeg, double endDeg) {
    if (phase < startDeg || phase > endDeg) return 0.0;

    final t = (phase - startDeg) / (endDeg - startDeg);
    return sin(t * pi).clamp(0.0, 1.0);
  }

  void _drawCamLobe(
      Canvas canvas, {
        required Offset center,
        required double angleDeg,
        required Color color,
        required Paint outline,
      }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleDeg * pi / 180.0);

    final camPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: 10,
      height: 18,
    );

    canvas.drawOval(rect, camPaint);
    canvas.drawOval(rect, outline);

    canvas.restore();
  }

  List<Color> _flowColorsForPhase(double phase) {
    if (phase >= 0 && phase < 180) {
      // 🔥 COMBUSTION (cháy)
      return const [
        Color(0xFFFFFF66),
        Color(0xFFFF9800),
        Color(0xFFFF3D00),
        Color(0xFFB71C1C),
      ];
    }

    if (phase >= 180 && phase < 360) {
      // 💨 EXHAUST (khí xả)
      return const [
        Color(0xFF757575),
        Color(0xFF424242),
        Color(0xFF212121),
        Color(0xCC000000),
      ];
    }

    if (phase >= 360 && phase < 540) {
      // 🌬 INTAKE (khí nạp)
      return const [
        Color(0xFF00F0FF),
        Color(0xFF00B0FF),
        Color(0xFF0077CC),
        Color(0x88004488),
      ];
    }

    return const [
      Color(0xFF90CAF9),
      Color(0xFF42A5F5),
      Color(0x8842A5F5),
    ];
  }


  void _drawHeadAndValves(
      Canvas canvas, {
        required double centerX,
        required bool sparkOn,
        required bool injectorOn,
        required bool hasMixture,
        required bool coilFault,
        required double phase,
        required double pistonTopY,
        required Paint blueWall,
        required Paint outline,
      }) {
    final intakeX = centerX - 13;
    final exhaustX = centerX + 13;

    final intakeCamAngle = ((phase - 360) * 0.5) % 360;
    final exhaustCamAngle = ((phase - 180) * 0.5) % 360;

    final intakeOpen = _phaseLiftWindow(phase, 360, 540);
    final exhaustOpen = _phaseLiftWindow(phase, 180, 360);
    double wobble = sin(flowOffset * 2 * pi) * 2;
    const valveTopY = 40.0;
    const seatBaseY = 74.0;
    const intakeColor = Color(0xFF38BDF8); // 🔵 xanh nạp
    const exhaustColor = Color(0xFFFFC107); // 🟡 vàng xả
    double camOffsetY = 10; // 👈 chỉnh tại đây (10–15 là đẹp)
    _drawCamLobe(
      canvas,
      center: Offset(intakeX, 25+ camOffsetY),
      angleDeg: intakeCamAngle,
      color: intakeColor,
      outline: outline,
    );

    _drawCamLobe(
      canvas,
      center: Offset(exhaustX, 25+ camOffsetY),
      angleDeg: exhaustCamAngle,
      color: exhaustColor,
      outline: outline,
    );

    final intakeStemPaint = Paint()
      ..color = intakeColor
      ..strokeWidth = 3;

    final exhaustStemPaint = Paint()
      ..color = exhaustColor
      ..strokeWidth = 3;

    final headPaint = Paint()
      ..color = const Color(0xFF757575)
      ..style = PaintingStyle.fill;

    final headPath = Path()
      ..moveTo(centerX - 40, 48)
      ..lineTo(centerX + 40, 48)
      ..lineTo(centerX + 40, 60)
      ..lineTo(centerX + 20, 60)
      ..quadraticBezierTo(centerX + 10, 60, centerX + 6, 72)
      ..quadraticBezierTo(centerX, 82, centerX - 6, 72)
      ..quadraticBezierTo(centerX - 10, 60, centerX - 20, 60)
      ..lineTo(centerX - 40, 60)
      ..close();

    canvas.drawPath(headPath, headPaint);
    canvas.drawPath(headPath, outline);

    final intakeSeatY = seatBaseY + intakeOpen * 10;
    final exhaustSeatY = seatBaseY + exhaustOpen * 10;

    canvas.drawLine(
      Offset(intakeX, valveTopY + 2),
      Offset(intakeX, intakeSeatY),
      intakeStemPaint, // 🔵 nạp
    );

    canvas.drawLine(
      Offset(exhaustX, valveTopY + 2),
      Offset(exhaustX, exhaustSeatY),
      exhaustStemPaint, // 🟡 xả
    );

    final intakeValve = Path()
      ..moveTo(intakeX - 8, intakeSeatY)
      ..quadraticBezierTo(intakeX, intakeSeatY + 6, intakeX + 8, intakeSeatY)
      ..close();

    final exhaustValve = Path()
      ..moveTo(exhaustX - 8, exhaustSeatY)
      ..quadraticBezierTo(exhaustX, exhaustSeatY + 6, exhaustX + 8, exhaustSeatY)
      ..close();

    canvas.drawPath(
      intakeValve,
      Paint()..color = const Color(0xFF38BDF8), // xanh đẹp
    );
    canvas.drawPath(
      exhaustValve,
      Paint()..color = const Color(0xFFFFC107), // vàng
    );

    canvas.drawCircle(
      Offset(intakeX, 42 + intakeOpen * 2),
      2.5,
      Paint()..color = const Color(0xFFBFC5CC),
    );
    canvas.drawCircle(
      Offset(exhaustX, 42 + exhaustOpen * 2),
      2.5,
      Paint()..color = const Color(0xFFBFC5CC),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 33, 71, 12, 9),
        const Radius.circular(2),
      ),
      blueWall,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 21, 71, 12, 9),
        const Radius.circular(2),
      ),
      blueWall,
    );

    final flowColors = _flowColorsForPhase(phase);

    Paint buildFlowPaint(Rect rect) {
      double speed = 1.2 + (phase / 720) * 2.0;

      return Paint()
        ..shader = LinearGradient(
          begin: Alignment(-1 + flowOffset * speed, -0.3),
          end: Alignment(1 + flowOffset * speed, 0.3),
          colors: flowColors,
          stops: [0.0, 0.1, 0.4, 1.0],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6); // 👈 dày hơn
    }

    const manifoldY = 60.0;
    const flowBaseY = manifoldY + 10;
    const flowThickness = 6.0;
    const chamberTipY = 80.0;
    const chamberBottomY = 88.0;

    double dynamicBottom = pistonTopY +6;
    if (hasMixture && phase >= 360 && phase < 540 && intakeOpen > 0.01) {
      final t = ((phase - 360) / 180).clamp(0.0, 1.0);

      final neckY = manifoldY + 8 + intakeOpen * 2.0;

      final intakeFlow = Path()
      // bắt đầu NGAY ngoài valve (KHÔNG xa)
        ..moveTo(intakeX - 18, chamberBottomY +5)

      // đi thẳng vào valve
        ..quadraticBezierTo(
          intakeX - 20,
          chamberBottomY - 10,
          intakeX,
          chamberBottomY - 6,
        )

      // chui xuống buồng đốt (QUAN TRỌNG)
        ..quadraticBezierTo(
          centerX - 4,
          chamberBottomY - 2,
          centerX,
          dynamicBottom,
        )

      // xoáy nhẹ trong buồng
        ..quadraticBezierTo(
          centerX + 6,
          dynamicBottom + 6,
          centerX,
          dynamicBottom + 10,
        )
        ..quadraticBezierTo(
          centerX - 6,
          dynamicBottom + 6,
          centerX,
          dynamicBottom,
        )
        ..close();

      canvas.drawPath(
        intakeFlow,
        buildFlowPaint(Rect.fromLTWH(centerX - 64, manifoldY - 2, 68, 22)),
      );

      final chamberTop = 82.0;
      final chamberBottom = pistonTopY;
      final chamberLeft = centerX - 20;
      final chamberRight = centerX + 20;

      if (chamberBottom > chamberTop + 2) {
        final intakeRect = Rect.fromLTRB(
          chamberLeft,
          chamberTop,
          chamberRight,
          chamberBottom,
        );

        final intakePaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(
                const Color(0xFFBFE8F7),
                const Color(0xFF8DD8F8),
                t,
              )!,
              Color.lerp(
                const Color(0xFF6CCAF3),
                const Color(0xFF37B8EE),
                t,
              )!,
              Color.lerp(
                const Color(0xFF1FA2E0),
                const Color(0xFF0277BD),
                t,
              )!,
              Color.lerp(
                const Color(0x5500B8D4),
                const Color(0x770055AA),
                t,
              )!,
            ],
            stops: const [0.0, 0.2, 0.58, 1.0],
          ).createShader(intakeRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);


        canvas.drawRRect(
          RRect.fromRectAndRadius(intakeRect, const Radius.circular(8)),
          intakePaint,
        );

        final coreRect = Rect.fromLTRB(
          centerX - 10,
          chamberTop + 2,
          centerX + 10,
          chamberBottom - 2,
        );

        final corePaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFB9E3F3).withOpacity(0.72),
              const Color(0xFF7CCCF0).withOpacity(0.78),
              const Color(0xFF1FA2E0).withOpacity(0.68),
            ],
          ).createShader(coreRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawRRect(
          RRect.fromRectAndRadius(coreRect, const Radius.circular(6)),
          corePaint,
        );

        for (int i = 0; i < 24; i++) {
          final p = i / 24;
          final x = chamberLeft + 3 + (chamberRight - chamberLeft - 6) * ((p + flowOffset) % 1);
          final y = chamberTop + (chamberBottom - chamberTop) * (0.08 + p * 0.82);

          final mistPaint = Paint()
            ..color = Color.lerp(
              const Color(0xFF9ED8EE),
              const Color(0xFF0277BD),
              p,
            )!.withOpacity(0.72)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

          canvas.drawCircle(
            Offset(x, y),
            1.6 + (1 - p) * 1.4,
            mistPaint,
          );
        }
      }

      drawFlowParticles(
        canvas,
        Rect.fromLTWH(centerX - 40, manifoldY - 2, 35, 22),
        phase: phase,
      );
    }

    if (hasMixture && phase >= 540 && phase < 720) {
      final t = ((phase - 540) / 180).clamp(0.0, 1.0);

      final chamberTop = 82.0;
      final chamberBottom = pistonTopY;
      final chamberLeft = centerX - 20;
      final chamberRight = centerX + 20;

      if (chamberBottom > chamberTop + 2) {
        final compressionRect = Rect.fromLTRB(
          chamberLeft,
          chamberTop,
          chamberRight,
          chamberBottom,
        );

        final compressionPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(
                const Color(0xFFE1F5FE),
                const Color(0xFFB3E5FC),
                t * 0.5,
              )!,
              Color.lerp(
                const Color(0xFF81D4FA),
                const Color(0xFF4FC3F7),
                t,
              )!,
              Color.lerp(
                const Color(0xFF29B6F6),
                const Color(0xFF0277BD),
                t,
              )!,
              Color.lerp(
                const Color(0x6600B8D4),
                const Color(0x88003388),
                t,
              )!,
            ],
            stops: const [0.0, 0.2, 0.58, 1.0],
          ).createShader(compressionRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

        canvas.drawRRect(
          RRect.fromRectAndRadius(compressionRect, const Radius.circular(8)),
          compressionPaint,
        );

        final coreWidth = lerpDouble(16, 8, t)!;
        final coreRect = Rect.fromLTRB(
          centerX - coreWidth,
          chamberTop + 2,
          centerX + coreWidth,
          chamberBottom - 2,
        );

        final corePaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF7FDFF).withOpacity(0.92),
              const Color(0xFFB3E5FC).withOpacity(0.88),
              const Color(0xFF0288D1).withOpacity(0.72),
            ],
          ).createShader(coreRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

        canvas.drawRRect(
          RRect.fromRectAndRadius(coreRect, const Radius.circular(6)),
          corePaint,
        );

        for (int i = 0; i < 22; i++) {
          final p = i / 22;
          final widthFactor = lerpDouble(0.95, 0.35, t)!;

          final x = centerX +
              ((p - 0.5) * (chamberRight - chamberLeft) * widthFactor);

          final y = chamberTop +
              (chamberBottom - chamberTop) * (0.08 + p * 0.82);

          final dotPaint = Paint()
            ..color = Color.lerp(
              const Color(0xFFE1F5FE),
              const Color(0xFF01579B),
              t * 0.8,
            )!.withOpacity(0.82)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

          canvas.drawCircle(
            Offset(x, y),
            lerpDouble(2.2, 1.2, t)!,
            dotPaint,
          );
        }
      }
    }


    if (hasMixture && !coilFault && phase >= 0 && phase < 180) {
      final t = (phase / 180).clamp(0.0, 1.0);

      final chamberTop = 82.0;
      final chamberBottom = pistonTopY;
      final chamberLeft = centerX - 20;
      final chamberRight = centerX + 20;

      if (chamberBottom > chamberTop + 2) {
        final flameRect = Rect.fromLTRB(
          chamberLeft,
          chamberTop,
          chamberRight,
          chamberBottom,
        );

        final flamePaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(
                const Color(0xFFFFFFFF),
                const Color(0xFFFFF176),
                t * 0.6,
              )!,
              Color.lerp(
                const Color(0xFFFFF176),
                const Color(0xFFFFC107),
                t,
              )!,
              Color.lerp(
                const Color(0xFFFF9800),
                const Color(0xFFFF5722),
                t,
              )!,
              Color.lerp(
                const Color(0xFFE53935),
                const Color(0xFFB71C1C),
                t,
              )!,
            ],
            stops: const [0.0, 0.2, 0.58, 1.0],
          ).createShader(flameRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

        canvas.drawRRect(
          RRect.fromRectAndRadius(flameRect, const Radius.circular(8)),
          flamePaint,
        );

        final coreRect = Rect.fromLTRB(
          centerX - 10,
          chamberTop + 2,
          centerX + 10,
          chamberBottom - 2,
        );

        final corePaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFFFFF).withOpacity(0.95),
              const Color(0xFFFFF59D).withOpacity(0.9),
              const Color(0xFFFFB300).withOpacity(0.75),
            ],
          ).createShader(coreRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        canvas.drawRRect(
          RRect.fromRectAndRadius(coreRect, const Radius.circular(6)),
          corePaint,
        );

        for (int i = 0; i < 24; i++) {
          final p = i / 24;
          final x = chamberLeft + 3 + (chamberRight - chamberLeft - 6) * ((p + flowOffset) % 1);
          final y = chamberBottom - (chamberBottom - chamberTop) * (0.12 + p * 0.82);

          final emberPaint = Paint()
            ..color = Color.lerp(
              const Color(0xFFFFF176),
              const Color(0xFFFF3D00),
              p,
            )!.withOpacity(0.85)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

          canvas.drawCircle(
            Offset(x, y),
            1.6 + (1 - p) * 1.4,
            emberPaint,
          );
        }
      }
    }

    if (phase >= 180 && phase < 360 && exhaustOpen > 0.01) {
      final t = ((phase - 180) / 180).clamp(0.0, 1.0);
      final neckY = manifoldY + 3 + exhaustOpen * 2.0;

      final exhaustFlow = Path()
        ..moveTo(centerX + 2, flowBaseY)
        ..quadraticBezierTo(centerX + wobble + 1, chamberBottomY - 1, centerX + wobble + 6, neckY)
        ..quadraticBezierTo(centerX + wobble + 10, manifoldY + 2, exhaustX + 7, manifoldY + 1)
        ..quadraticBezierTo(centerX + wobble + 24, manifoldY, centerX + wobble + 36, manifoldY)
        ..lineTo(centerX + wobble + 64, manifoldY)
        ..lineTo(centerX + wobble + 64, manifoldY + flowThickness)
        ..lineTo(centerX + wobble + 36, manifoldY + flowThickness)
        ..quadraticBezierTo(
          centerX + wobble + 24,
          manifoldY + flowThickness,
          exhaustX + 10,
          manifoldY + flowThickness,
        )
        ..quadraticBezierTo(
          centerX + wobble + 12,
          manifoldY + flowThickness + 2,
          centerX + wobble + 8,
          chamberTipY,
        )
        ..quadraticBezierTo(centerX + 2, chamberBottomY + 1, centerX + wobble - 2, chamberBottomY)
        ..close();

      canvas.drawPath(
        exhaustFlow,
        buildFlowPaint(Rect.fromLTWH(centerX + wobble - 2, manifoldY - 2, 66, 22)),
      );

      final chamberTop = 82.0;
      final chamberBottom = pistonTopY;
      final chamberLeft = centerX - 20;
      final chamberRight = centerX + 20;

      if (chamberBottom > chamberTop + 2) {
        final exhaustRect = Rect.fromLTRB(
          chamberLeft,
          chamberTop,
          chamberRight,
          chamberBottom,
        );

        final exhaustPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(
                const Color(0xFFBDBDBD),
                const Color(0xFF9E9E9E),
                t * 0.4,
              )!,
              Color.lerp(
                const Color(0xFF757575),
                const Color(0xFF616161),
                t,
              )!,
              Color.lerp(
                const Color(0xFF424242),
                const Color(0xFF212121),
                t,
              )!,
              Color.lerp(
                const Color(0x99000000),
                const Color(0xCC000000),
                t,
              )!,
            ],
            stops: const [0.0, 0.25, 0.62, 1.0],
          ).createShader(exhaustRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

        canvas.drawRRect(
          RRect.fromRectAndRadius(exhaustRect, const Radius.circular(8)),
          exhaustPaint,
        );

        final coreRect = Rect.fromLTRB(
          centerX - 9,
          chamberTop + 2,
          centerX + 9,
          chamberBottom - 2,
        );

        final corePaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE0E0E0).withOpacity(0.55),
              const Color(0xFF757575).withOpacity(0.65),
              const Color(0xFF212121).withOpacity(0.75),
            ],
          ).createShader(coreRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawRRect(
          RRect.fromRectAndRadius(coreRect, const Radius.circular(6)),
          corePaint,
        );

        for (int i = 0; i < 22; i++) {
          final p = i / 22;
          final x = chamberLeft + 3 + (chamberRight - chamberLeft - 6) * (1 - ((p + flowOffset) % 1));
          final y = chamberTop + (chamberBottom - chamberTop) * (0.08 + p * 0.82);

          final smokePaint = Paint()
            ..color = Color.lerp(
              const Color(0xFFB0BEC5),
              const Color(0xFF212121),
              p,
            )!.withOpacity(0.72)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

          canvas.drawCircle(
            Offset(x, y),
            1.5 + (1 - p) * 1.2,
            smokePaint,
          );
        }
      }

      drawFlowParticles(
        canvas,
        Rect.fromLTWH(centerX + wobble - 10, manifoldY - 2, 66, 22),
        phase: phase,
      );
    }

    final coilBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - 6, 39, 12, 16),
      const Radius.circular(4),
    );

    final coilNeck = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - 4, 54, 8, 10),
      const Radius.circular(3),
    );

    final boot = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - 3, 61, 6, 16),
      const Radius.circular(3),
    );

    final coilPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF4B535D),
          Color(0xFF23282E),
        ],
      ).createShader(Rect.fromLTWH(centerX - 6, 31, 12, 16));

    final neckPaint = Paint()..color = const Color(0xFF5F6872);
    final bootPaint = Paint()..color = const Color(0xFF0E1013);

    final metalPaint = Paint()
      ..color = const Color(0xFFD8DADF)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(coilBody, coilPaint);
    canvas.drawRRect(coilBody, outline);
    canvas.drawRRect(coilNeck, neckPaint);
    canvas.drawRRect(coilNeck, outline);
    canvas.drawRRect(boot, bootPaint);
    canvas.drawRRect(boot, outline);

    if (coilFault) {
      final tp = TextPainter(
        text: const TextSpan(
          text: 'OFF',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(centerX - tp.width / 2, 20));
    }


    canvas.drawLine(
      Offset(centerX, 70),
      Offset(centerX, 73),
      metalPaint,
    );

    final connector = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - 4, 35, 8, 5),
      const Radius.circular(2),
    );
    canvas.drawRRect(connector, neckPaint);
    canvas.drawRRect(connector, outline);


    if (injectorOn) {
      final spray = Path()
        ..moveTo(centerX, 60)
        ..lineTo(centerX - 4, 60)
        ..lineTo(centerX + 4, 60)
        ..close();

      canvas.drawPath(
        spray,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0x8838BDF8), Color(0x0038BDF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(centerX - 8, 60, 16, 14)),
      );
    }
  }
  void drawFlowParticles(
      Canvas canvas,
      Rect bounds, {
        required double phase,
      }) {
    Color particleColor;
    double baseRadius;
    double opacity;

    if (phase >= 360 && phase < 540) {
      particleColor = const Color(0xFF4FC3F7);
      baseRadius = 2.4;
      opacity = 0.9;
    } else if (phase >= 180 && phase < 360) {
      particleColor = const Color(0xFF9E9E9E);
      baseRadius = 2.0;
      opacity = 0.65;
    } else if (phase >= 0 && phase < 180) {
      particleColor = const Color(0xFFFFC107);
      baseRadius = 2.8;
      opacity = 0.95;
    } else {
      particleColor = const Color(0xFF29B6F6);
      baseRadius = 2.2;
      opacity = 0.75;
    }

    for (int i = 0; i < 25; i++) {
      final t = (i / 25 + flowOffset) % 1;

      double x;
      double y;

      if (phase >= 360 && phase < 540) {
        x = bounds.left + bounds.width * t;
        y = bounds.top + bounds.height * (0.6 - 0.3 * sin(t * pi));
      } else if (phase >= 180 && phase < 360) {
        x = bounds.right - bounds.width * t;
        y = bounds.top + bounds.height * (0.4 + 0.3 * sin(t * pi));
      } else if (phase >= 0 && phase < 180) {
        x = bounds.center.dx + (t - 0.5) * bounds.width * 0.75;
        y = bounds.center.dy + (t - 0.5) * bounds.height * 0.75;
      } else {
        x = bounds.left + bounds.width * t;
        y = bounds.center.dy + (0.5 - t) * bounds.height * 0.5;
      }

      final paint = Paint()
        ..color = particleColor.withOpacity(opacity * (0.55 + 0.45 * (1 - t)))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

      canvas.drawCircle(
        Offset(x, y),
        baseRadius * (0.7 + 0.5 * (1 - t)),
        paint,
      );
    }
  }
  void _drawPiston(
      Canvas canvas,
      Rect rect,
      Paint whiteMetal,
      Paint darkMetal,
      Paint outline,
      ) {
    final pistonPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF), // highlight mạnh
          Color(0xFFEAEAEA),
          Color(0xFFCFCFCF),
          Color(0xFF9E9E9E), // shadow sâu
        ],
        stops: [0.0, 0.25, 0.6, 1.0],
      ).createShader(rect);


    canvas.drawRect(rect, pistonPaint);

    canvas.drawLine(
      Offset(rect.left + 4, rect.top + 3),
      Offset(rect.right - 4, rect.top + 6),
      Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..strokeWidth = 1.2,
    );
    for (int i = 0; i < 6; i++) {
      final y = rect.top + i * 5;

      canvas.drawLine(
        Offset(rect.left + 2, y),
        Offset(rect.right - 2, y),
        Paint()
          ..color = Colors.white.withOpacity(0.05)
          ..strokeWidth = 0.5,
      );
    }

    void drawRingGroove(double y, double h, {double inset = 1.4}) {
      final grooveRect = Rect.fromLTWH(
        rect.left + inset,
        y,
        rect.width - inset * 2,
        h,
      );

      canvas.drawRect(
        grooveRect,
        Paint()..color = const Color(0xFF5E5E5E),
      );

      canvas.drawLine(
        Offset(grooveRect.left, grooveRect.top),
        Offset(grooveRect.right, grooveRect.top),
        Paint()
          ..color = const Color(0xFF9A9A9A)
          ..strokeWidth = 0.5,
      );

      canvas.drawLine(
        Offset(grooveRect.left, grooveRect.bottom),
        Offset(grooveRect.right, grooveRect.bottom),
        Paint()
          ..color = const Color(0xFF3F3F3F)
          ..strokeWidth = 0.5,
      );
    }

    // xéc măng ôm hết piston
    drawRingGroove(rect.top + 3.2, 0.9);
    drawRingGroove(rect.top + 5.5, 0.9);
    drawRingGroove(rect.top + 8.4, 1.5);

    final pinCenter = Offset(rect.center.dx, rect.top + rect.height * 0.59);

    canvas.drawCircle(
      pinCenter,
      8,
      Paint()..color = const Color(0xFF4F545A),
    );
    canvas.drawCircle(
      pinCenter,
      4.4,
      Paint()..color = const Color(0xFFD7DBE0),
    );
    canvas.drawCircle(pinCenter, 8, outline);

    canvas.drawRect(rect, outline);
  }

  void _drawConnectingRod(
      Canvas canvas,
      Offset crankPin,
      Offset pistonPin,
      Paint whiteMetal,
      Paint outline,
      ) {
    final dx = pistonPin.dx - crankPin.dx;
    final dy = pistonPin.dy - crankPin.dy;
    final len = sqrt(dx * dx + dy * dy);

    final ux = dx / len;
    final uy = dy / len;
    final nx = -uy;
    final ny = ux;

    const smallEndHalf = 5.4;
    const shankHalfTop = 6.0;
    const shankHalfMid = 8.2;
    const shankHalfBottom = 11.5;
    const bigEndRadius = 15.5;

    final upperShoulder = Offset(
      crankPin.dx + ux * 34.0,
      crankPin.dy + uy * 34.0,
    );

    final lowerShoulder = Offset(
      crankPin.dx + ux * 16.0,
      crankPin.dy + uy * 16.0,
    );

    final rodPath = Path()
      ..moveTo(pistonPin.dx + nx * smallEndHalf, pistonPin.dy + ny * smallEndHalf)
      ..lineTo(upperShoulder.dx + nx * shankHalfTop, upperShoulder.dy + ny * shankHalfTop)
      ..lineTo(lowerShoulder.dx + nx * shankHalfMid, lowerShoulder.dy + ny * shankHalfMid)
      ..lineTo(crankPin.dx + nx * shankHalfBottom, crankPin.dy + ny * shankHalfBottom)
      ..arcToPoint(
        Offset(crankPin.dx - nx * shankHalfBottom, crankPin.dy - ny * shankHalfBottom),
        radius: const Radius.circular(bigEndRadius),
        clockwise: false,
      )
      ..lineTo(lowerShoulder.dx - nx * shankHalfMid, lowerShoulder.dy - ny * shankHalfMid)
      ..lineTo(upperShoulder.dx - nx * shankHalfTop, upperShoulder.dy - ny * shankHalfTop)
      ..lineTo(pistonPin.dx - nx * smallEndHalf, pistonPin.dy - ny * smallEndHalf)
      ..close();

    final rodBounds = Rect.fromPoints(pistonPin, crankPin).inflate(20);
    final rodPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFFFFFFFF),
          Color(0xFFECECEC),
          Color(0xFFD6D6D6),
          Color(0xFF9A9A9A),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
        transform: GradientRotation(atan2(dy, dx) - pi / 2),
      ).createShader(rodBounds);

    canvas.drawPath(rodPath, rodPaint);
    canvas.drawPath(rodPath, outline);
    canvas.drawLine(
      pistonPin,
      crankPin,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..strokeWidth = 1.2,
    );

    // Rãnh giữa giống ảnh: dài, tối, thuôn nhọn xuống đầu to
    final ribTop = Offset(
      pistonPin.dx + ux * 8.0,
      pistonPin.dy + uy * 8.0,
    );

    final ribMid = Offset(
      crankPin.dx + ux * 28.0,
      crankPin.dy + uy * 28.0,
    );

    final ribBottom = Offset(
      crankPin.dx + ux * 6.0,
      crankPin.dy + uy * 6.0,
    );

    final ribPath = Path()
      ..moveTo(ribTop.dx + nx * 1.2, ribTop.dy + ny * 1.2)
      ..lineTo(ribMid.dx + nx * 2.4, ribMid.dy + ny * 2.4)
      ..lineTo(ribBottom.dx + nx * 4.0, ribBottom.dy + ny * 4.0)
      ..quadraticBezierTo(
        crankPin.dx,
        crankPin.dy - 1.0,
        ribBottom.dx - nx * 4.0,
        ribBottom.dy - ny * 4.0,
      )
      ..lineTo(ribMid.dx - nx * 2.4, ribMid.dy - ny * 2.4)
      ..lineTo(ribTop.dx - nx * 1.2, ribTop.dy - ny * 1.2)
      ..close();


    canvas.drawPath(
      ribPath,
      Paint()..color = const Color(0xFF5B5D62),
    );

    // đầu to thanh truyền
    canvas.drawCircle(
      crankPin,
      13,
      Paint()..color = const Color(0xFFE8E8E8),
    );
    canvas.drawCircle(crankPin, 13, outline);

    // lỗ đầu to
    canvas.drawCircle(
      crankPin,
      5.6,
      Paint()..color = const Color(0xFFBDBDBD),
    );
    canvas.drawCircle(
      crankPin,
      2.4,
      Paint()..color = const Color(0xFF8E8E8E),
    );
  }

  void _drawCrank(
      Canvas canvas,
      Offset crankCenter,
      Offset crankPin,
      Paint darkMetal,
      Paint outline,
      ) {
    final crankMetal = Paint()
      ..shader = RadialGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFD6D6D6),
          Color(0xFF9E9E9E),
          Color(0xFF5A5A5A),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: crankCenter, // 👈 đúng vị trí
          radius: 22,
        ),
      );

    canvas.drawCircle(crankCenter, 22, crankMetal);
    canvas.drawCircle(crankCenter, 22, outline);

    canvas.drawCircle(
      Offset(crankCenter.dx - 6, crankCenter.dy - 6),
      3,
      Paint()..color = Colors.white.withOpacity(0.7),
    );

    canvas.drawCircle(
      crankCenter,
      4,
      Paint()..color = const Color(0xFFA8A8A8),
    );
  }

  void _drawCylinder(
      Canvas canvas,
      Size size, {
        required double centerX,
        required double phase,
        required double pistonTheta,
        required String label,
        required bool sparkOn,
        required bool injectorOn,
        required bool hasMixture,
        required bool coilFault,
        required Paint outline,
        required Paint metal,
        required Paint blueWall,
        required Paint darkMetal,
      }) {
    const cylinderTop = 74.0;
    const cylinderBottom = 150.0;
    const crankY = 190.0;
    const crankRadius = 20.0;
    const rodLength = 35.0;
    const pistonWidth = 42.0;
    const pistonHeight = 35.0;
    const double pistonTdcOffset = 34.0;

    final leftWall = centerX - 30;
    final rightWall = centerX + 30;

    final crankCenter = Offset(centerX, crankY);
    final crankPin = Offset(
      crankCenter.dx + crankRadius * sin(pistonTheta),
      crankCenter.dy - crankRadius * cos(pistonTheta),
    );

    final dx = crankPin.dx - centerX;
    final pistonPinY =
        crankPin.dy - sqrt(max(rodLength * rodLength - dx * dx, 0)) - pistonTdcOffset;

    final pistonRect = Rect.fromLTWH(
      centerX - pistonWidth / 2,
      pistonPinY - pistonHeight / 2,
      pistonWidth,
      pistonHeight,
    );

    final pistonPin = Offset(centerX, pistonRect.top + pistonRect.height * 0.55);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(leftWall + 3, cylinderTop, 6, cylinderBottom - cylinderTop),
        const Radius.circular(2),
      ),
      blueWall,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rightWall - 9, cylinderTop, 6, cylinderBottom - cylinderTop),
        const Radius.circular(2),
      ),
      blueWall,
    );


    final boreRect = Rect.fromLTWH(
      leftWall + 9,
      cylinderTop,
      rightWall - leftWall - 18,
      cylinderBottom - cylinderTop,
    );

    canvas.drawRect(
      boreRect,
      Paint()..color = const Color(0xFF1B1E22),
    );

    //_drawGasState(
    //canvas,
    //boreRect: boreRect,
    //pistonRect: pistonRect,
    //phase: phase,
    //);

    _drawHeadAndValves(
      canvas,
      centerX: centerX,
      sparkOn: sparkOn,
      injectorOn: injectorOn,
      hasMixture: hasMixture,
      coilFault: coilFault,
      phase: phase,
      pistonTopY: pistonRect.top,
      blueWall: blueWall,
      outline: outline,
    );

    _drawConnectingRod(canvas, crankPin, pistonPin, metal, outline);
    _drawPiston(canvas, pistonRect, metal, darkMetal, outline);
    _drawCrank(canvas, crankCenter, crankPin, darkMetal, outline);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, 2));
  }

  void _drawStatusText(Canvas canvas, Size size) {
    final status = isRunning ? '2D RUNNING' : '2D READY';
    final tp = TextPainter(
      text: TextSpan(
        text: status,
        style: TextStyle(
          color: isRunning ? Colors.greenAccent : Colors.white70,
          fontSize: 0,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(size.width - tp.width - 8, size.height - tp.height - 6));
  }

  @override
  bool shouldRepaint(covariant FourCylinderEnginePainter oldDelegate) {
    return oldDelegate.crankAngle != crankAngle ||
        oldDelegate.activeSparkCylinders.length != activeSparkCylinders.length ||
        !oldDelegate.activeSparkCylinders.containsAll(activeSparkCylinders) ||
        oldDelegate.injectorCylinder != injectorCylinder ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.ckpFault != ckpFault ||
        oldDelegate.cmpFault != cmpFault ||
        oldDelegate.injectorFaults.toString() != injectorFaults.toString() ||
        oldDelegate.coilFaults.toString() != coilFaults.toString();
  }
}