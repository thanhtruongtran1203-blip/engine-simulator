import 'dart:async';

import 'package:flutter/material.dart';

import 'engine_3d_screen.dart';
import 'widgets/ckp_waveform_painter.dart';

class WaveformScreen extends StatefulWidget {

  final double Function() getAngle;
  final double Function() getRPM;
  final bool Function() getRunning;

  final bool Function() getCKPFault;
  final bool Function() getCMPFault;
  final bool Function() getCKPNoSignal;

  final Map<int, int> coilFaultModes;

  const WaveformScreen({
    super.key,
    required this.getAngle,
    required this.getRPM,
    required this.getRunning,

    required this.getCKPFault,
    required this.getCKPNoSignal,
    required this.getCMPFault,

    required this.coilFaultModes,
  });

  @override
  State<WaveformScreen> createState() =>
      _WaveformScreenState();
}

class _WaveformScreenState
    extends State<WaveformScreen> {

  Timer? refreshTimer;
  bool freezeWaveform = false;

  double frozenAngle = 0;
  double frozenRPM = 0;

  @override
  void initState() {
    super.initState();

    refreshTimer = Timer.periodic(
      const Duration(milliseconds: 16),
          (_) {

            if (!freezeWaveform) {

              frozenAngle =
                  widget.getAngle();

              frozenRPM =
                  widget.getRPM();
            }

            if (mounted) {
              setState(() {});
            }
      },
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,

        title: const Text(
          "CKP / CMP Waveform",
        ),

        actions: [

          IconButton(

            icon: Icon(

              freezeWaveform
                  ? Icons.play_arrow
                  : Icons.pause,

              color: Colors.red,
            ),

            onPressed: () {

              setState(() {

                freezeWaveform =
                !freezeWaveform;
              });
            },
          ),

          IconButton(

            icon: const Icon(
              Icons.arrow_forward_ios,
            ),

            onPressed: () {

              Navigator.push(
                context,

                MaterialPageRoute(
                  builder: (_) =>
                  const Engine3DScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: Padding(

        padding: const EdgeInsets.all(16),

        child: Container(

          decoration: BoxDecoration(
            color: const Color(0xFF111111),

            borderRadius:
            BorderRadius.circular(20),

            border: Border.all(
              color: Colors.white12,
            ),
          ),

          child: CustomPaint(

            painter: CKPWaveformPainter(

              crankAngle:
              freezeWaveform
                  ? frozenAngle
                  : widget.getAngle(),

              rpm:
              freezeWaveform
                  ? frozenRPM
                  : widget.getRPM(),

              isRunning:
              widget.getRunning(),

              ckpFault:
              widget.getCKPFault(),

              ckpNoSignal:
              widget.getCKPNoSignal(),

              cmpFault:
              widget.getCMPFault(),

              coilFaultModes:
              widget.coilFaultModes,
            ),

            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}