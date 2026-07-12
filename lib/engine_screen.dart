  import 'dart:async';
  import 'dart:io';
  import 'dart:math';
  import 'dart:typed_data';
  import 'package:flutter/material.dart';
  import 'package:usb_serial/usb_serial.dart';
  import 'engine_3d_screen.dart';
  import 'painters/electric_path_painters.dart';
  import 'painters/injector_painters.dart';
  import 'widgets/engine_2d_preview.dart';
  import 'widgets/engine_gauges.dart';
  import 'widgets/engine_start_button.dart';
  import 'widgets/ckp_waveform_painter.dart';
  import 'faults/engine_faults.dart';
  import 'waveform_screen.dart';
  import 'controllers/fault_controller.dart';
  
  class EngineScreen extends StatefulWidget {
    const EngineScreen({super.key});
  
    @override
    State<EngineScreen> createState() => _EngineScreenState();
  }
  
  class _EngineScreenState extends State<EngineScreen>
      with SingleTickerProviderStateMixin {
    double rpm = 1000;
    double crankAngle = 0;
    double renderAngle = 0;
    DateTime lastRenderTime = DateTime.now();
    int spark = 0;
    int injector = 0;
    bool useSTM32 = false;
    bool isRunning = false;
    double simScale = 0.12;
    double prevAngle = 0;
    double targetRPM = 1000;
    final faultController = FaultController();
  
    Timer? engineLoop;
    String buffer = '';
    bool useTcpBridge = false;
    UsbPort? stm32Port;
    StreamSubscription<Uint8List>? stm32Sub;
    Socket? stm32Socket;
    StreamSubscription<List<int>>? stm32TcpSub;
    final Random _rand = Random();
    int _lastMisfireTime = 0;
    int injectorPulseId = 0;
    int sparkPulseId = 0;
    late AnimationController electricController;
  
    final Set<int> activeSparkCylinders = <int>{};
  
    final Map<int, int> _lastInjectorTrigger = {};
    final Map<int, int> _lastSparkTrigger = {};
  
    final Map<int, double> fireAngle = {
      1: 0.0,
      3: 180.0,
      4: 360.0,
      2: 540.0,
    };
  
    final Map<int, double> injectorStartAngle = {
      4: 0.0,
      2: 180.0,
      1: 360.0,
      3: 540.0,
    };
  
    bool hasInjectorFault(int cyl) =>
        (faultController.injectorFaultModes[cyl] ?? 0) != 0;
  
    bool hasCoilFault(int cyl) =>
        (faultController.coilFaultModes[cyl] ?? 0) != 0;
  
    bool get cmpFault => faultController.cmpFaultMode != 0;
  
    double get currentRpm {
      return rpm.clamp(500, 6000);
    }
  
    double get eventIntervalMs => 120000 / currentRpm;
  
    double getInjectionAdvance(double rpm) {
  
      if (rpm < 1000) {
        return 320;
      }
  
      if (rpm < 2000) {
        return 300;
      }
  
      if (rpm < 3000) {
        return 280;
      }
  
      if (rpm < 4500) {
        return 250;
      }
  
      return 220;
    }
  
    Future<void> connectSTM32() async {
      if (useTcpBridge) {
        await connectSTM32Tcp();
      } else {
        await connectSTM32Usb();
      }
    }
  
    Future<void> connectSTM32Tcp() async {
      await disconnectSTM32();
  
      try {
        stm32Socket = await Socket.connect(
          '10.0.2.2',
          5000,
          timeout: const Duration(seconds: 3),
        );
  
        stm32TcpSub = stm32Socket!.listen(
              (data) {
            final chunk = String.fromCharCodes(data);
            onDataReceived(chunk);
          },
          onDone: () {
            debugPrint('TCP bridge da ngat ket noi');
          },
          onError: (error) {
            debugPrint('Loi TCP bridge: $error');
          },
        );
  
        debugPrint('Da ket noi STM32 qua TCP bridge');
      } catch (error) {
        debugPrint('Khong ket noi duoc TCP bridge: $error');
      }
    }
  
    Future<void> connectSTM32Usb() async {
  
      await disconnectSTM32();
  
      final devices = await UsbSerial.listDevices();
  
      if (devices.isEmpty) {
        debugPrint('Khong thay USB UART');
        return;
      }
  
      for(final d in devices)
      {
        debugPrint(
            '${d.productName} '
                '${d.vid}:${d.pid}'
        );
      }
  
      final device = devices.first;
  
      stm32Port = await device.create();
  
      final opened = await stm32Port!.open();
  
      if (!opened) {
        debugPrint('Khong mo duoc USB UART');
        return;
      }
  
      await stm32Port!.setDTR(true);
      await stm32Port!.setRTS(true);
  
      await stm32Port!.setPortParameters(
        115200,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
  
      stm32Sub = stm32Port!.inputStream?.listen(
            (Uint8List data) {
  
          final chunk =
          String.fromCharCodes(data);
  
          onDataReceived(chunk);
        },
      );
  
      debugPrint('Da ket noi STM32 UART');
    }
  
    Future<void> disconnectSTM32() async {
      await stm32TcpSub?.cancel();
      stm32TcpSub = null;
  
      await stm32Socket?.close();
      stm32Socket = null;
  
      await stm32Sub?.cancel();
      stm32Sub = null;
  
      await stm32Port?.close();
      stm32Port = null;
  
      debugPrint('Da ngat STM32 UART');
    }
    @override
    void initState() {
      super.initState();
      Future.delayed(
        const Duration(milliseconds: 500),
            () async {
          await connectSTM32();
  
          setState(() {
            useSTM32 = false;
          });
        },
      );
  
      electricController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      );
  
      engineLoop = Timer.periodic(
          const Duration(milliseconds: 16),
              (_) {
  
            if (!isRunning) return;
  
            final now = DateTime.now();
  
            final dt =
                now.difference(lastRenderTime)
                    .inMicroseconds / 1000000.0;
  
            lastRenderTime = now;
  
            if (faultController.ckpFaultMode != 1) {
  
              // 🔥 realtime từ STM32
              rpm = targetRPM;
  
              if (faultController.appFault) {
  
                // giới hạn ga kiểu limp mode
                if (targetRPM > 1800) {
                  targetRPM = 1800;
                }
  
                // rung ga
                rpm += sin(
                  DateTime.now().millisecondsSinceEpoch / 120,
                ) * 35;
  
                // delay phản hồi ga
                rpm += (targetRPM - rpm) * 0.03;
              }

              if (faultController.mapFaultMode != 0) {
  
                // giới hạn công suất turbo
                if (targetRPM > 3200) {
                  targetRPM = 3200;
                }
  
                // rung nhẹ
                rpm += sin(
                  DateTime.now().millisecondsSinceEpoch / 180,
                ) * 12;
              }

              if (faultController.mapFault) {

                if (targetRPM > 4000) {
                  targetRPM = 4000;
                }
  
                // máy hơi ì
                rpm += sin(
                  DateTime.now().millisecondsSinceEpoch / 220,
                ) * 8;
              }

              final visualRpm =
                  currentRpm * 0.08;
  
              final degPerSecond =
                  (visualRpm * 720.0) / 60.0;
  
              renderAngle += degPerSecond * dt;
  
              while (renderAngle >= 720) {
                renderAngle -= 720;
              }
  
              if (useSTM32) {
  
                double diff = crankAngle - renderAngle;
  
                if (diff > 360) diff -= 720;
                if (diff < -360) diff += 720;
  
                renderAngle += diff * 0.015;
              }
  
            } else {
  
              double diff = targetRPM - rpm;
  
              rpm += diff * 0.2;
  
              if (rpm > 400 && _rand.nextDouble() < 0.1) {
                rpm -= 100 + _rand.nextDouble() * 200;
              }
  
              rpm += sin(
                DateTime.now().millisecondsSinceEpoch / 80,
              ) * 5;
            }
  
            // P0336
            if (faultController.ckpFaultMode == 2) {
  
              rpm += sin(
                DateTime.now().millisecondsSinceEpoch / 120,
              ) * 80;
            }
  
            if (faultController.ckpFaultMode == 1 && rpm < 250) {
              rpm *= 0.9;
  
              if (ckpFault && rpm < 300) {
                rpm *= 0.92;
  
                if (rpm < 520) {
                  rpm = 500; // 🔥 giữ min hợp lệ
                  isRunning = false;
                  electricController.stop();
                }
              }
            }
            if (ckpFault && rpm > 300 && _rand.nextDouble() < 0.2) {
            }
            checkFireByAngle();
  
            setState(() {});
          });
    }
  
  
    @override
    void dispose() {
      stm32TcpSub?.cancel();
      stm32Socket?.close();
      stm32Sub?.cancel();
      stm32Port?.close();
  
      engineLoop?.cancel();
      electricController.dispose();
      super.dispose();
    }
  
    bool get ckpFault => faultController.ckpFaultMode != 0;
  
  
    void startEngine() {
  
      if (faultController.ckpFaultMode == 1) return;
  
      setState(() {
  
        _lastInjectorTrigger.clear();
        _lastSparkTrigger.clear();
  
        isRunning = true;
        crankAngle = 0;
        renderAngle = 0;
        prevAngle = 719.9;
        injector = 0;
        spark = 0;
        rpm = 1000;
        targetRPM = 1000;
        activeSparkCylinders.clear();
      });
  
      electricController.repeat();
    }
  
    void stopEngine() {
      setState(() {
        isRunning = false;
        injector = 0;
        spark = 0;
        activeSparkCylinders.clear();
      });
  
      electricController.stop();
    }
  
    void onDataReceived(String chunk) {
  
      buffer += chunk;
  
      final matches =
      RegExp(r'<\d+,-?\d+>')
          .allMatches(buffer)
          .toList();
  
      if (matches.isNotEmpty) {
  
        // 🔥 lấy frame mới nhất
        final latest =
        matches.last.group(0)!;
  
        parseFrame(latest);
  
        // 🔥 clear buffer tránh delay
        buffer = '';
      }
    }
  
    void parseFrame(String data)
    {
      if (!useSTM32 || faultController.ckpFaultMode == 1) return;
  
      final reg =
      RegExp(r'<(\d+),(-?\d+)>');
  
      final match =
      reg.firstMatch(data);
  
      if (match == null) return;
  
      if (!isRunning) return;
  
      final newRPM =
      double.parse(match.group(1)!);
  
      targetRPM = newRPM;
      rpm = newRPM;
  
      prevAngle = crankAngle;
  
      crankAngle =
          double.parse(match.group(2)!);
  
      checkFireByAngle();
  
    }
  
    int sparkVisualDurationMs() {
      final double rpmRatio = ((currentRpm - 500) / (6000 - 500)).clamp(0, 1);
      final int visualMs = (120 - (rpmRatio * 35)).round();
      return visualMs.clamp(70, 120);
    }
  
    int injectorVisualDurationMs() {
      final double rpmRatio = ((currentRpm - 500) / (6000 - 500)).clamp(0, 1);
      final int visualMs = (120 - (rpmRatio * 40)).round();
      return visualMs.clamp(70, 120);
    }
  
    void triggerInjector(int cyl) {
  
      final now = DateTime.now().millisecondsSinceEpoch;
  
      if ((now - (_lastInjectorTrigger[cyl] ?? 0)) < 40) {
        return;
      }
  
      _lastInjectorTrigger[cyl] = now;
  
      if (faultController.ckpFaultMode == 1) return;

      if (faultController.cmpFaultMode == 1) {

        if (_rand.nextDouble() < 0.15) {
          return;
        }
      }
  
      final mode =
          faultController.injectorFaultModes[cyl] ?? 0;
  
      // P020x
      if (mode == 1) {
  
        rpm -= 25 + _rand.nextDouble() * 20;
  
        return;
      }
  
      // P0261
      if (mode == 2) {
  
        if (_rand.nextDouble() < 0.5) {
  
          rpm -= 10 + _rand.nextDouble() * 10;
  
          return;
        }
      }
  
      // P0262
      if (mode == 3) {
  
        rpm += _rand.nextDouble() * 25;
      }

  
      setState(() {
        injector = cyl;
      });
  
    }
  
    void triggerSpark(int cyl) {
  
      final now = DateTime.now().millisecondsSinceEpoch;
  
      if ((now - (_lastSparkTrigger[cyl] ?? 0)) < 40) {
        return;
      }
  
      _lastSparkTrigger[cyl] = now;
  
      if (faultController.ckpFaultMode == 1) return;

      // P0340 - mất CMP
      if (faultController.cmpFaultMode == 1) {

        if (_rand.nextDouble() < 0.15) {
          return;
        }
      }
  
      final mode =
          faultController.coilFaultModes[cyl] ?? 0;
  
      // P035x
      if (mode == 1) {
  
        rpm -= 30 + _rand.nextDouble() * 20;
  
        setState(() {
          spark = 0;
        });
  
        return;
      }
  
      // P2300
      if (mode == 2) {
  
        rpm -= _rand.nextDouble() * 10;
  
        if (_rand.nextDouble() < 0.5) {
  
          setState(() {
            spark = 0;
          });
  
          return;
        }
      }
  
      // P2301
      if (mode == 3) {
  
        rpm += _rand.nextDouble() * 40;
      }
  
      final id = ++sparkPulseId;
  
      setState(() {
        spark = cyl;
  
        activeSparkCylinders
          ..clear()
          ..add(cyl);
      });
  
      final int duration = sparkVisualDurationMs();
  
      Future.delayed(Duration(milliseconds: duration), () {
  
        if (!mounted) return;
  
        if (id == sparkPulseId) {
  
          setState(() {
            activeSparkCylinders.clear();
            spark = 0;
          });
        }
      });
    }
  
    void checkFireByAngle() {
      if (!isRunning) return;
  
      if (faultController.appFault && _rand.nextDouble() < 0.08) {
        return;
      }
  
      for (final entry in injectorStartAngle.entries) {
        if (isAnglePassed(prevAngle, crankAngle, entry.value)) {
          triggerInjector(entry.key);
        }
      }
  
      for (final entry in fireAngle.entries) {
        if (isAnglePassed(prevAngle, crankAngle, entry.value)) {
          triggerSpark(entry.key);
        }
      }
  
      prevAngle = crankAngle;
  
      bool injectorStillActive = false;
  
      for (final cyl in [1, 2, 3, 4]) {
  
        final start =
            (360 - getInjectionAdvance(currentRpm)) % 720;
  
        final duration =
        currentRpm < 2500 ? 70.0 : 100.0;
  
        final phase =
            (renderAngle + {
              1: 0.0,
              2: 180.0,
              3: 540.0,
              4: 360.0,
            }[cyl]!) % 720;
  
        final end =
            (start + duration) % 720;
  
        bool active;
  
        if (start < end) {
          active =
              phase >= start &&
                  phase <= end;
        } else {
          active =
              phase >= start ||
                  phase <= end;
        }
  
        if (active && !hasInjectorFault(cyl)) {
          injectorStillActive = true;
          injector = cyl;
        }
      }
  
      if (!injectorStillActive) {
        injector = 0;
      }
    }
  
    bool isAnglePassed(double prev, double current, double target) {
  
      // wrap 720 -> 0
      if (prev > 650 && current < 100) {
        return target > prev || target <= current;
      }
  
      return target > prev && target <= current;
    }
  
    Widget buildCoilHitArea({
      required double previewLeft,
      required double previewTop,
      required double centerX,
      required int cylinder,
    }) {
      return Positioned(
        left: previewLeft + centerX - 18,
        top: previewTop + 26,
        child: GestureDetector(
          onTap: () {
            setState(() {
              faultController.toggleCoilFault(cylinder);
            });
          },
          child: Container(
            width: 36,
            height: 50,
            color: Colors.transparent,
          ),
        ),
      );
    }
  
    @override
    Widget build(BuildContext context) {
      final faults = faultController.allFaults;
      final w = MediaQuery.of(context).size.width;
      final double displayRPM =
      rpm.clamp(500, 6000);
  
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Stack(
          children: [
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
  
                    MaterialPageRoute(
                      builder: (_) => WaveformScreen(
  
                        getAngle: () => renderAngle,
  
                        getRPM: () => currentRpm,
  
                        getRunning: () => isRunning,
  
                        getCKPFault: () => ckpFault,
  
                        getCMPFault: () => cmpFault,
  
                        getCKPNoSignal: () => faultController.ckpFaultMode == 1,
  
                        coilFaultModes: faultController.coilFaultModes,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 250,
              right: 70,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.4,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const previewWidth = 360.0;
                    const previewHeight = 230.0;
  
                    final previewLeft = (constraints.maxWidth - previewWidth) / 2;
                    final previewTop = (constraints.maxHeight - previewHeight) / 2;
  
                    return Stack(
                      children: [
                        Center(
                          child: Engine2DPreview(
                            crankAngle: renderAngle,
                            activeSparkCylinders: activeSparkCylinders,
                            injectorCylinder: injector,
                            isRunning: isRunning,
                            injectorFaultModes: faultController.injectorFaultModes,
                            coilFaultModes: faultController.coilFaultModes,
                            shakeOffset:
                            faultController.faultShakeOffset(isRunning),
                            ckpFault: ckpFault,
                            cmpFault: cmpFault,
                            rpm: currentRpm,
                          ),
                        ),
                        buildCoilHitArea(
                          previewLeft: previewLeft,
                          previewTop: previewTop,
                          centerX: 43.2,
                          cylinder: 1,
                        ),
                        buildCoilHitArea(
                          previewLeft: previewLeft,
                          previewTop: previewTop,
                          centerX: 133.2,
                          cylinder: 2,
                        ),
                        buildCoilHitArea(
                          previewLeft: previewLeft,
                          previewTop: previewTop,
                          centerX: 223.2,
                          cylinder: 3,
                        ),
                        buildCoilHitArea(
                          previewLeft: previewLeft,
                          previewTop: previewTop,
                          centerX: 313.2,
                          cylinder: 4,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 100,
              right: 800,
              child: Center(
                child: Text(
                  'Hệ thống phun xăng điện tử',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 298,
              left: 0,
              right: 1245,
              child: Center(
                child: Text(
                  'Van \nđiều khiển',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 155,
              left: 5,
              right: 515,
              child: Center(
                child: Text(
                  'Bộ điều áp\nnhiên liệu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 200,
              left: 0,
              right: 360,
              child: Center(
                child: Text(
                  'Ống chân không từ\n  phía sau cổ hút',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 230,
              left: 45,
              right: 90,
              child: Center(
                child: Text(
                  'Ống phân \n phối nhiên liệu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 275,
              left: 0,
              right: 130,
              child: Center(
                child: Text(
                  'Kim phun',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 302,
              right: 1080,
              child: Center(
                child: Text(
                  'Lọc\nxăng',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 350,
              left: 0,
              right: 1130,
              child: Center(
                child: Text(
                  'Bình than\nhoạt tính',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 475,
              left: 0,
              right: 1040,
              child: Center(
                child: Text(
                  '   Bình \nnhiên liệu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 425,
              left: 0,
              right: 792,
              child: Center(
                child: Text(
                  'ECU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 360,
              left: 0,
              right: 870,
              child: Center(
                child: Text(
                  '    Bơm \nxăng điện',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 604,
              right: 1040,
              child: Center(
                child: Text(
                  'Đường nhiên liệu áp suất cao',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 625,
              right: 1085,
              child: Center(
                child: Text(
                  'Đường hồi nhiên liệu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 505,
              left: 5,
              right: 633,
              child: Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 505,
              left: 5,
              right: 536,
              child: Center(
                child: Text(
                  'B',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 505,
              left: 5,
              right: 420,
              child: Center(
                child: Text(
                  'C',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 505,
              left: 5,
              right: 318,
              child: Center(
                child: Text(
                  'D',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 505,
              left: 5,
              right: 230,
              child: Center(
                child: Text(
                  'E',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 505,
              left: 5,
              right: 140,
              child: Center(
                child: Text(
                  'F',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 505,
              left: 0,
              right: 50,
              child: Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 540,
              left: 0,
              right: 410,
              child: Center(
                child: Text(
                  'A. Cảm biến vị trí/tốc độ trục khuỷu\nB. Cảm biến vị trí trục cam\nC. Cảm biến bàn đạp ga/phanh/tốc độ xe\nD. Cảm biến áp suất đường ống nạp (MAP)\nE. Cảm biến nhiệt độ khí nạp\nF. Cảm biến nhiệt độ nước làm mát\nG. Cảm biến nhiệt độ dầu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 895,
              bottom: 52,
              child: SizedBox(
                width: 70,
                height: 70,
                child: RpmGauge(rpm: displayRPM),
              ),
            ),
            if (faultController.hasAnyFault)
              Positioned(
                left: 942,
                bottom: 22,
                child: AnimatedBuilder(
                  animation: electricController,
                  builder: (context, child) {
                    final blinkOn = electricController.value < 0.5;
  
                    return Opacity(
                      opacity: blinkOn ? 1.0 : 0.0,
                      child: child,
                    );
                  },
                  child: Image.asset(
                    'assets/images/engine_fault.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            Positioned(
              left: 915,
              bottom: 23,
              child: Image.asset(
                'assets/images/brake.png',
                width: 38,
                height: 38,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 965,
              bottom: 18,
              child: Image.asset(
                'assets/images/seatbelt.png',
                width: 43,
                height: 43,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 990,
              bottom: 20,
              child: Image.asset(
                'assets/images/cool_water.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left:900,
              bottom: 490,
              child: Image.asset(
                'assets/images/obd_device.png',
                width: 250,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 600,
              bottom: 640,
              child: Image.asset(
                'assets/images/FAST.png',
                width: 400,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 965,
              bottom: 50,
              child: SizedBox(
                width: 120,
                height: 120,
                child: SpeedGauge(speed: displayRPM / 40),
              ),
            ),
            if (faultController.hasAnyFault)
              Positioned(
                right: 251,
                bottom: 532,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        border: Border.all(
                          color: Colors.orangeAccent.withOpacity(0.7),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          Text(
                            'DTC: ${faultController.allFaults.length}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          SizedBox(
                            width: 112,
                            height: 50,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(top: 10),
                              itemCount:
                              faultController.allFaults.length,

                              itemBuilder: (context, index) {

                                final fault =
                                faultController.allFaults[index];

                                return InkWell(

                                  onTap: () {

                                    showDialog(
                                      context: context,
                                      builder: (_) {

                                        return AlertDialog(

                                          backgroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: BorderSide(
                                              color: Colors.white.withOpacity(0.3), // bạc nhẹ
                                              width: 1.2,
                                            ),
                                          ),

                                          title: Text(
                                            fault.code,
                                            style: const TextStyle(
                                              color: Colors.orangeAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,

                                            children: [

                                              Text(
                                                fault.label,
                                                style: const TextStyle(
                                                  color: Colors.orangeAccent,
                                                ),
                                              ),

                                              const SizedBox(height: 8),

                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'Mô tả:\n',
                                                      style: const TextStyle(color: Colors.redAccent),
                                                    ),
                                                    TextSpan(
                                                      text: fault.description,
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 8),

                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'Nguyên nhân:\n',
                                                      style: const TextStyle(color: Colors.redAccent),
                                                    ),
                                                    TextSpan(
                                                      text: fault.cause,
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 8),

                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'Triệu chứng:\n',
                                                      style: const TextStyle(color: Colors.redAccent),
                                                    ),
                                                    TextSpan(
                                                      text: fault.symptom,
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },

                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 4,
                                    ),

                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,

                                      children: [

                                        Text(
                                          fault.code,
                                          style: const TextStyle(
                                            color: Colors.orangeAccent,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        Text(
                                          fault.label,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 7,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              right: 205,
              bottom: 58,
              child: SizedBox(
                width: 50,
                height: 50,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: const FuelGauge(value: 100),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              right: 900,
              child: Transform.scale(
                scale: 1.2, // Phóng to 1.5 lần
                child: EngineStartButton(
                  isRunning: isRunning,
                  onStart: startEngine,
                  onStop: stopEngine,
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              right: 800,
              child: SizedBox(
                height: 30,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: const Size(80, 35),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    if (stm32Port == null) {
                      await connectSTM32();
  
                      setState(() {
                        useSTM32 = true;
                      });
                    } else {
                      await disconnectSTM32();
  
                      setState(() {
                        useSTM32 = false;
                      });
                    }
                  },
                  child: Text(
                    stm32Port != null ? 'CONNECTED' : 'CONNECT',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 80,
              left: 0,
              child: SizedBox(
                width: w * 0.5,
                child: Image.asset(
                  'assets/images/gasoline.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: electricController,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Positioned(
                          left: 300,
                          bottom: 345,
                          child: CustomPaint(
                            size: const Size(100, 165),
                            painter: ElectricPathPainterCustom(
                              electricController.value,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 202,
                          bottom: 318,
                          child: CustomPaint(
                            size: const Size(10, 170),
                            painter: ElectricPathPainterCustom1(
                              electricController.value,
                              rpm,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 190,
                          bottom: 320,
                          child: CustomPaint(
                            size: const Size(30,52),
                            painter: ElectricPathPainterCustom2(
                              electricController.value,
                              rpm,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 250,
                          bottom: 197,
                          child: CustomPaint(
                            size: const Size(79, 100),
                            painter: ElectricPathPainter1(
                              electricController.value,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 334,
                          bottom: 285,
                          child: CustomPaint(
                            size: const Size(100, 55),
                            painter: ElectricPathPainter2(
                              electricController.value,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 382,
                          bottom: 285,
                          child: CustomPaint(
                            size: const Size(100, 55),
                            painter: ElectricPathPainter2(
                              electricController.value,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 418,
                          bottom: 285,
                          child: CustomPaint(
                            size: const Size(100, 55),
                            painter: ElectricPathPainter2(
                              electricController.value,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 482,
                          bottom: 285,
                          child: CustomPaint(
                            size: const Size(100, 55),
                            painter: ElectricPathPainter2(
                              electricController.value,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 512,
                          bottom: 308,
                          child: CustomPaint(
                            size: const Size(100, 30),
                            painter: ElectricPathPainter3(
                              electricController.value,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 554,
                          bottom: 308,
                          child: CustomPaint(
                            size: const Size(100, 30),
                            painter: ElectricPathPainter3(
                              electricController.value,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 597,
                          bottom: 308,
                          child: CustomPaint(
                            size: const Size(100, 30),
                            painter: ElectricPathPainter3(
                              electricController.value,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 337,
                          bottom: 280,
                          child: CustomPaint(
                            size: const Size(320, 100),
                            painter: ElectricPathPainter4(
                              electricController.value,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 378,
                          bottom: 405,
                          child: SizedBox(
                            width: 36,
                            height: 46,
                            child: Stack(
                              children: [
                                CustomPaint(
                                  size: const Size(30, 40),
                                  painter: StaticInjectorPainter(
                                    isActive: injector == 1 && !hasInjectorFault(1),
                                  ),
                                ),
                                if (hasInjectorFault(1))
                                  const Center(
                                    child: Text(
                                      'OFF',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 488,
                          bottom: 405,
                          child: SizedBox(
                            width: 36,
                            height: 46,
                            child: Stack(
                              children: [
                                CustomPaint(
                                  size: const Size(30, 40),
                                  painter: StaticInjectorPainter(
                                    isActive: injector == 3 && !hasInjectorFault(3),
                                  ),
                                ),
                                if (hasInjectorFault(3))
                                  const Center(
                                    child: Text(
                                      'OFF',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 543,
                          bottom: 405,
                          child: SizedBox(
                            width: 36,
                            height: 46,
                            child: Stack(
                              children: [
                                CustomPaint(
                                  size: const Size(30, 40),
                                  painter: StaticInjectorPainter(
                                    isActive: injector == 4 && !hasInjectorFault(4),
                                  ),
                                ),
                                if (hasInjectorFault(4))
                                  const Center(
                                    child: Text(
                                      'OFF',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 433,
                          bottom: 405,
                          child: SizedBox(
                            width: 36,
                            height: 46,
                            child: Stack(
                              children: [
                                CustomPaint(
                                  size: const Size(30, 40),
                                  painter: StaticInjectorPainter(
                                    isActive: injector == 2 && !hasInjectorFault(2),
                                  ),
                                ),
                                if (hasInjectorFault(2))
                                  const Center(
                                    child: Text(
                                      'OFF',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Positioned(
              left: 365,
              bottom: 465,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    faultController.toggleInjectorFault(1);
                  });
                },
                child: Container(
                  width: 40,
                  height: 50,
                  color: Colors.transparent,
                ),
              ),
            ),
  
            Positioned(
              left: 425,
              bottom: 465,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    faultController.toggleInjectorFault(2);
                  });
                },
                child: Container(
                  width: 40,
                  height: 50,
                  color: Colors.transparent,
                ),
              ),
            ),
  
            Positioned(
              left: 480,
              bottom: 465,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    faultController.toggleInjectorFault(3);
                  });
                },
                child: Container(
                  width: 40,
                  height: 50,
                  color: Colors.transparent,
                ),
              ),
            ),
  
            Positioned(
              left: 535,
              bottom: 465,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    faultController.toggleInjectorFault(4);
                  });
                },
                child: Container(
                  width: 40,
                  height: 50,
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              left: 345,
              top: 450,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    faultController.toggleCKPFault();
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              left: 390,
              top: 450,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    faultController.toggleCMPFault();
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              left: 445,
              top: 450,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    faultController.toggleAPPFault();
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              left: 495,
              top: 450,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    faultController.toggleMAPFault();
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              left: 552,
              top: 440,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    faultController.toggleIATFault();
                  });
                },
                child: Container(
                  width: 20,
                  height: 60,
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              left: 594,
              top: 440,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    faultController.toggleECTFault();
                  });
                },
                child: Container(
                  width: 20,
                  height: 60,
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
