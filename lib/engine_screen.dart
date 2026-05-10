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
import '../audio/engine_sound_controller.dart';


class EngineScreen extends StatefulWidget {
  const EngineScreen({super.key});

  @override
  State<EngineScreen> createState() => _EngineScreenState();
}

class _EngineScreenState extends State<EngineScreen>
    with SingleTickerProviderStateMixin {
  double rpm = 1000;
  double fakeRPM = 1000;
  double crankAngle = 0;
  int spark = 0;
  int injector = 0;
  bool useSTM32 = false;
  bool isRunning = false;
  double simScale = 0.2;
  double prevAngle = 0;
  bool ckpFault = false;
  bool cmpFault = false;
  double targetRPM = 1000;


  final Map<int, bool> injectorFaults = {
    1: false,
    2: false,
    3: false,
    4: false,
  };

  final Map<int, bool> coilFaults = {
    1: false,
    2: false,
    3: false,
    4: false,
  };

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
  late EngineSoundController engineSound;

  final Set<int> activeSparkCylinders = <int>{};

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

  bool hasInjectorFault(int cyl) => injectorFaults[cyl] ?? false;

  bool hasCoilFault(int cyl) => coilFaults[cyl] ?? false;

  String get currentInjectorFaultCode {
    if (hasInjectorFault(1)) return 'P0201';
    if (hasInjectorFault(2)) return 'P0202';
    if (hasInjectorFault(3)) return 'P0203';
    if (hasInjectorFault(4)) return 'P0204';
    return '';
  }

  String get currentInjectorFaultLabel {
    if (hasInjectorFault(1)) return 'Injector 1 Fault';
    if (hasInjectorFault(2)) return 'Injector 2 Fault';
    if (hasInjectorFault(3)) return 'Injector 3 Fault';
    if (hasInjectorFault(4)) return 'Injector 4 Fault';
    return '';
  }

  String get currentCoilFaultCode {
    if (hasCoilFault(1)) return 'P0351';
    if (hasCoilFault(2)) return 'P0352';
    if (hasCoilFault(3)) return 'P0353';
    if (hasCoilFault(4)) return 'P0354';
    return '';
  }

  String get currentCoilFaultLabel {
    if (hasCoilFault(1)) return 'Ignition Coil 1 Fault';
    if (hasCoilFault(2)) return 'Ignition Coil 2 Fault';
    if (hasCoilFault(3)) return 'Ignition Coil 3 Fault';
    if (hasCoilFault(4)) return 'Ignition Coil 4 Fault';
    return '';
  }

  String get currentSensorFaultCode {
    if (ckpFault) return 'P0335';
    if (cmpFault) return 'P0340';
    return '';
  }

  String get currentSensorFaultLabel {
    if (ckpFault) return 'CKP Sensor Fault';
    if (cmpFault) return 'CMP Sensor Fault';
    return '';
  }

  String get currentFaultCode {
    if (currentSensorFaultCode.isNotEmpty) return currentSensorFaultCode;
    if (currentInjectorFaultCode.isNotEmpty) return currentInjectorFaultCode;
    if (currentCoilFaultCode.isNotEmpty) return currentCoilFaultCode;
    return '';
  }

  String get currentFaultLabel {
    if (currentSensorFaultLabel.isNotEmpty) return currentSensorFaultLabel;
    if (currentInjectorFaultLabel.isNotEmpty) return currentInjectorFaultLabel;
    if (currentCoilFaultLabel.isNotEmpty) return currentCoilFaultLabel;
    return '';
  }

  bool get hasAnyFault {
    return ckpFault ||
        cmpFault ||
        injectorFaults.containsValue(true) ||
        coilFaults.containsValue(true);
  }

  bool get cmpGlitchActive {
    if (!cmpFault || !isRunning) return false;
    final t = DateTime.now().millisecondsSinceEpoch ~/ 180;
    return t % 5 == 0;
  }

  Offset get faultShakeOffset {
    if (!isRunning) return Offset.zero;

    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;

    if (cmpFault) {
      return Offset(sin(t * 38) * 1.8, cos(t * 29) * 1.1);
    }

    if (injectorFaults.containsValue(true) || coilFaults.containsValue(true)) {
      return Offset(sin(t * 42) * 2.2, cos(t * 31) * 1.4);
    }

    return Offset.zero;
  }

  double get currentRpm {
    final value = useSTM32 ? rpm : fakeRPM;
    return value.clamp(500, 6000);
  }

  double get eventIntervalMs => 120000 / currentRpm;

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

    stm32Port = await devices.first.create();

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

    stm32Sub = stm32Port!.inputStream?.listen((Uint8List data) {
      final chunk = String.fromCharCodes(data);
      onDataReceived(chunk);
    });

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
    engineSound = EngineSoundController();
    engineSound.init();

    electricController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    engineLoop = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!isRunning || useSTM32) return;

      double diff = targetRPM - fakeRPM;

      if (ckpFault) {
        // giảm chậm + có quán tính
        fakeRPM += diff * 0.012;

        // 🔥 tụt bất thường (giống mất sync CKP)
        if (fakeRPM > 400 && _rand.nextDouble() < 0.1) {
          fakeRPM -= 100 + _rand.nextDouble() * 200;
        }

        // 🔥 dao động nhẹ trước khi chết máy
        fakeRPM += sin(DateTime.now().millisecondsSinceEpoch / 80) * 5;
      } else {
        fakeRPM += diff * 0.05;
      }
      if (ckpFault && fakeRPM > 300) {
        if (_rand.nextDouble() < 0.08) {
          fakeRPM -= _rand.nextDouble() * 150; // tụt bất chợt
        }
      }

      if (ckpFault && fakeRPM < 250) {
        fakeRPM *= 0.9;

        if (ckpFault && fakeRPM < 300) {
          fakeRPM *= 0.92;

          if (fakeRPM < 520) {
            fakeRPM = 500; // 🔥 giữ min hợp lệ
            isRunning = false;
            engineSound.stop();
            electricController.stop();
          }
        }
      }
      if (ckpFault && fakeRPM > 300 && _rand.nextDouble() < 0.2) {
        engineSound.misfireStrong();
      }

      final double step = fakeRPM * 6 * 0.016 * simScale;
      const int subSteps = 50;
      final double subStepAngle = step / subSteps;

      for (int i = 0; i < subSteps; i++) {
        crankAngle += subStepAngle;

        if (crankAngle >= 720) {
          crankAngle -= 720;
        }

        checkFireByAngle();
      }
      engineSound.updateRPM(currentRpm);

      setState(() {});
    });
  }

  @override
  void dispose() {
    stm32TcpSub?.cancel();
    stm32Socket?.close();
    stm32Sub?.cancel();
    stm32Port?.close();

    engineSound.dispose();
    engineLoop?.cancel();
    electricController.dispose();
    super.dispose();
  }

  void toggleCMPFault() {
    setState(() {
      cmpFault = !cmpFault;
    });
  }

  void toggleCKPFault() {
    setState(() {
      ckpFault = !ckpFault;

      if (ckpFault) {
        // 🔻 giảm dần về 0 (KHÔNG tắt máy ngay)
        targetRPM = 0;
      } else {
        // 🔺 chạy lại theo ga hiện tại
        targetRPM = fakeRPM;

        // nếu trước đó rpm đã về 0 thì cho chạy lại
        if (!isRunning) {
          isRunning = true;
          electricController.repeat();
          engineSound.start();
        }
      }
    });
  }

  void toggleCoilFault(int cyl) {
    setState(() {
      coilFaults[cyl] = !(coilFaults[cyl] ?? false);

      if ((coilFaults[cyl] ?? false) && spark == cyl) {
        spark = 0;
          activeSparkCylinders.clear();
      }
    });
  }
  void toggleInjectorFault(int cyl) {
    setState(() {
      injectorFaults[cyl] = !(injectorFaults[cyl] ?? false);

      if ((injectorFaults[cyl] ?? false) && injector == cyl) {
        injector = 0;
      }
    });
  }


  void startEngine() {
    if (ckpFault) return;

    setState(() {
      isRunning = true;
      crankAngle = 0;
      prevAngle = 719.9;
      injector = 0;
      spark = 0;
      activeSparkCylinders.clear();
    });
    engineSound.start();

    electricController.repeat();
  }

  void stopEngine() {
    setState(() {
      isRunning = false;
      injector = 0;
      spark = 0;
      activeSparkCylinders.clear();
    });
    engineSound.stop();

    electricController.stop();
  }

  void onDataReceived(String chunk) {
    buffer += chunk;

    while (buffer.contains('<') && buffer.contains('>')) {
      final int start = buffer.indexOf('<');
      final int end = buffer.indexOf('>', start);

      if (start != -1 && end != -1 && end > start) {
        final String frame = buffer.substring(start, end + 1);
        buffer = buffer.substring(end + 1);

        parseFrame(frame);
      } else {
        break;
      }
    }
  }

  void parseFrame(String data) {
    if (!useSTM32 || ckpFault) return;

    final reg = RegExp(r'<(\d+),(-?\d+),(\d+),(\d+)>');
    final match = reg.firstMatch(data);

    if (match == null) return;

    final int newSpark = int.parse(match.group(3)!);
    final int newInj = int.parse(match.group(4)!);

    rpm = double.parse(match.group(1)!);
    crankAngle = double.parse(match.group(2)!);

    if (newInj != 0) {
      triggerInjector(newInj);
    }

    if (newSpark != 0) {
      triggerSpark(newSpark);
    }

    setState(() {});
    engineSound.updateRPM(currentRpm);
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
    if (ckpFault) return;
    if (hasInjectorFault(cyl)) {
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - _lastMisfireTime > 120 && _rand.nextDouble() < 0.7) {
        engineSound.misfireEffect();
        _lastMisfireTime = now;
      }

      return;
    }

    if (cmpGlitchActive && cyl.isEven) return;

    final pulseId = ++injectorPulseId;

    setState(() {
      injector = cyl;
    });

    final int duration = injectorVisualDurationMs();

    Future.delayed(Duration(milliseconds: duration), () {
      if (!mounted) return;

      if (pulseId == injectorPulseId && injector == cyl) {
        setState(() {
          injector = 0;
        });
      }
    });
  }

  void triggerSpark(int cyl) {
    if (ckpFault) return;
    if (hasCoilFault(cyl)) {
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - _lastMisfireTime > 120 && _rand.nextDouble() < 0.8) {
        engineSound.misfireStrong(); // 🔥 dùng strong
        _lastMisfireTime = now;
      }

      // ❌ không tạo spark cho xy lanh này
      setState(() {
        spark = 0;
      });

      return;
    }
    if (cmpGlitchActive && cyl == 3) return;

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
    if (useSTM32 || !isRunning) return;

    if (ckpFault) {
      // mất đồng bộ nặng hơn theo rpm
      double failRate = (fakeRPM / 6000).clamp(0.2, 0.8);

      if (_rand.nextDouble() < failRate) return;
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
  }

  bool isAnglePassed(double prev, double current, double target) {
    if (prev < current) {
      return target > prev && target <= current;
    }

    return target > prev || target <= current;
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
        onTap: () => toggleCoilFault(cylinder),
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
    final w = MediaQuery.of(context).size.width;
    final double displayRPM =
    (useSTM32 ? rpm : fakeRPM).clamp(500, 6000);

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
                    builder: (_) => const Engine3DScreen(),
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
          const Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'MÔ PHỎNG HOẠT ĐỘNG CỦA ĐỘNG CƠ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
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
                color: const Color(0xFF0B0B0B),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: Colors.white24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
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
                          crankAngle: crankAngle,
                          activeSparkCylinders: activeSparkCylinders,
                          injectorCylinder: injector,
                          isRunning: isRunning,
                          injectorFaults: injectorFaults,
                          coilFaults: coilFaults,
                          shakeOffset: faultShakeOffset,
                          ckpFault: ckpFault,
                          cmpFault: cmpFault,
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
            left: 0,
            right: 650,
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
            top: 258,
            left: 0,
            right: 1030,
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
            top: 145,
            left: 0,
            right: 425,
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
            top: 170,
            left: 0,
            right: 280,
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
            top: 200,
            left: 65,
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
            top: 235,
            left: 0,
            right: 100,
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
            top: 252,
            left: 35,
            right: 700,
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
            top: 300,
            left: 0,
            right: 920,
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
            top: 355,
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
            top: 365,
            left: 0,
            right: 662,
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
            top: 400,
            left: 0,
            right: 760,
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
            top: 506,
            left: 0,
            right: 720,
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
            top: 526,
            left: 0,
            right: 770,
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
            top: 425,
            left: 5,
            right: 518,
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
            top: 425,
            left: 5,
            right: 438,
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
            top: 425,
            left: 5,
            right: 348,
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
            top: 425,
            left: 5,
            right: 258,
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
            top: 425,
            left: 5,
            right: 188,
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
            top: 425,
            left: 5,
            right: 118,
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
            top: 425,
            left: 5,
            right: 46,
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
            top: 460,
            left: 0,
            right: 300,
            child: Center(
              child: Text(
                'A. Cảm biến vị trí/tốc độ trục khuỷu\nB. Cảm biến vị trí trục cam\nC. Cảm biến bàn đạp ga/phanh/tốc độ xe\nD. Cảm biến nhiệt độ khí nạp tăng áp\nE. Cảm biến nhiệt độ khí nạp\nF. Cảm biến nhiệt độ nước làm mát\nG. Cảm biến nhiệt độ dầu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          Positioned(
            left: 705,
            bottom: 52,
            child: SizedBox(
              width: 50,
              height: 50,
              child: RpmGauge(rpm: displayRPM),
            ),
          ),
          if (hasAnyFault)
            Positioned(
              left: 760,
              bottom: 30,
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
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          Positioned(
            left: 845,
            bottom: 50,
            child: Image.asset(
              'assets/images/fuel.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 735,
            bottom: 30,
            child: Image.asset(
              'assets/images/brake.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 782,
            bottom: 30,
            child: Image.asset(
              'assets/images/seatbelt.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 800,
            bottom: 30,
            child: Image.asset(
              'assets/images/cool_water.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 900,
            bottom: 50,
            child: Image.asset(
              'assets/images/obd_device.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 755,
            bottom: 50,
            child: SizedBox(
              width: 100,
              height: 100,
              child: SpeedGauge(speed: displayRPM / 40),
            ),
          ),
          if (hasAnyFault)
            Positioned(
              right: 110,
              bottom: 78,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orangeAccent,
                    size: 16,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      border: Border.all(
                        color: Colors.orangeAccent.withOpacity(0.7),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$currentFaultCode - $currentFaultLabel',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            right: 205,
            bottom: 58,
            child: SizedBox(
              width: 30,
              height: 30,
              child: FittedBox(
                fit: BoxFit.contain,
                child: const FuelGauge(value: 100),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 840,
            child: EngineStartButton(
              isRunning: isRunning,
              onStart: startEngine,
              onStop: stopEngine,
            ),
          ),
          Positioned(
            bottom: 40,
            right: 740,
            child: SizedBox(
              height: 28,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  minimumSize: const Size(60, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  final nextUseSTM32 = !useSTM32;

                  setState(() {
                    useSTM32 = nextUseSTM32;
                  });

                  if (nextUseSTM32) {
                    await connectSTM32();
                  } else {
                    await disconnectSTM32();
                  }
                },
                child: Text(
                  useSTM32 ? 'STM32' : 'FAKE',
                  style: const TextStyle(fontSize: 8),
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
          Positioned(
            left: 0,
            bottom: 100,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      'RPM: ${displayRPM.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        overlayShape: SliderComponentShape.noOverlay,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                      ),
                      child: Slider(
                        min: 500,
                        max: 6000,
                        divisions: 55,
                        value: fakeRPM.clamp(500, 6000),
                        onChanged: useSTM32
                            ? null
                            : (value) {
                          setState(() {
                            targetRPM = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
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
                        left: 235,
                        bottom: 315,
                        child: CustomPaint(
                          size: const Size(100, 135),
                          painter: ElectricPathPainterCustom(
                            electricController.value,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 134,
                        bottom: 310,
                        child: CustomPaint(
                          size: const Size(10, 164),
                          painter: ElectricPathPainterCustom1(
                            electricController.value,
                            useSTM32 ? rpm : fakeRPM,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 168,
                        bottom: 327,
                        child: CustomPaint(
                          size: const Size(10,85),
                          painter: ElectricPathPainterCustom2(
                            electricController.value,
                            useSTM32 ? rpm : fakeRPM,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 203,
                        bottom: 211,
                        child: CustomPaint(
                          size: const Size(67, 85),
                          painter: ElectricPathPainter1(
                            electricController.value,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 263,
                        bottom: 280,
                        child: CustomPaint(
                          size: const Size(100, 50),
                          painter: ElectricPathPainter2(
                            electricController.value,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 302,
                        bottom: 280,
                        child: CustomPaint(
                          size: const Size(100, 50),
                          painter: ElectricPathPainter2(
                            electricController.value,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 333,
                        bottom: 285,
                        child: CustomPaint(
                          size: const Size(100, 45),
                          painter: ElectricPathPainter2(
                            electricController.value,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 385,
                        bottom: 285,
                        child: CustomPaint(
                          size: const Size(100, 45),
                          painter: ElectricPathPainter2(
                            electricController.value,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 409,
                        bottom: 302,
                        child: CustomPaint(
                          size: const Size(100, 25),
                          painter: ElectricPathPainter3(
                            electricController.value,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 442,
                        bottom: 302,
                        child: CustomPaint(
                          size: const Size(100, 25),
                          painter: ElectricPathPainter3(
                            electricController.value,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 479,
                        bottom: 302,
                        child: CustomPaint(
                          size: const Size(100, 25),
                          painter: ElectricPathPainter3(
                            electricController.value,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 272,
                        bottom: 271,
                        child: CustomPaint(
                          size: const Size(267, 100),
                          painter: ElectricPathPainter4(
                            electricController.value,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 305,
                        bottom: 375,
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
                        left: 395,
                        bottom: 375,
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
                        left: 440,
                        bottom: 375,
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
                        left: 350,
                        bottom: 375,
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
            left: 305,
            bottom: 425,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => toggleInjectorFault(1),
              child: Container(
                width: 36,
                height: 46,
                color: Colors.transparent,
              ),
            ),
          ),

          Positioned(
            left: 345,
            bottom: 425,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => toggleInjectorFault(2),
              child: Container(
                width: 36,
                height: 46,
                color: Colors.transparent,
              ),
            ),
          ),

          Positioned(
            left: 385,
            bottom: 425,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => toggleInjectorFault(3),
              child: Container(
                width: 36,
                height: 46,
                color: Colors.transparent,
              ),
            ),
          ),

          Positioned(
            left: 425,
            bottom: 425,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => toggleInjectorFault(4),
              child: Container(
                width: 36,
                height: 46,
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            left: 270,
            top: 390,
            child: GestureDetector(
              onTap: toggleCKPFault,
              child: Container(
                width: 40,
                height: 40,
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            left: 320,
            top: 390,
            child: GestureDetector(
              onTap: toggleCMPFault,
              child: Container(
                width: 40,
                height: 40,
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
