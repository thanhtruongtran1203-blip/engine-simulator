import 'dart:ui';

import 'package:flutter/material.dart';

import '../painters/four_cylinder_engine_painter.dart';

import '../painters/engine_status_painter.dart';

class Engine2DPreview extends StatelessWidget {
  final double crankAngle;
  final Set<int> activeSparkCylinders;
  final int injectorCylinder;
  final bool isRunning;
  final double rpm;
  final Map<int, int> injectorFaultModes;
  final Map<int, int> coilFaultModes;
  final Offset shakeOffset;
  final bool ckpFault;
  final bool cmpFault;

  const Engine2DPreview({
    super.key,
    required this.crankAngle,
    required this.activeSparkCylinders,
    required this.rpm,
    required this.injectorCylinder,
    required this.isRunning,
    required this.injectorFaultModes,
    required this.coilFaultModes,
    required this.shakeOffset,
    required this.ckpFault,
    required this.cmpFault,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 360,
        height: 230,
        child: Stack(
          children: [

            // 🔥 chỉ động cơ rung
            Transform.translate(
              offset: shakeOffset,
              child: CustomPaint(
                size: const Size(360, 230),
                painter: FourCylinderEnginePainter(
                  crankAngle: crankAngle,
                  activeSparkCylinders: activeSparkCylinders,
                  injectorCylinder: injectorCylinder,
                  isRunning: isRunning,
                  injectorFaultModes: injectorFaultModes,
                  coilFaultModes: coilFaultModes,
                  ckpFault: ckpFault,
                  cmpFault: cmpFault,
                  rpm: rpm,
                ),
              ),
            ),

            CustomPaint(
              size: const Size(360, 230),
              painter: EngineStatusPainter(
                rpm: rpm,
                isRunning: isRunning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
