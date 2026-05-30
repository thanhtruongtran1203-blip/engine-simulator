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
  import 'widgets/ckp_waveform.dart';
  import 'faults/engine_faults.dart';
  
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
    int ckpFaultMode = 0;
    int cmpFaultMode = 0;
    double targetRPM = 1000;
    bool appFault = false;
    bool mapFault = false;
    bool iatFault = false;
    bool ectFault = false;
    bool oilTempFault = false;
    bool fuelPumpFault = false;
  
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
  
    bool hasInjectorFault(int cyl) => injectorFaults[cyl] ?? false;
  
    bool hasCoilFault(int cyl) => coilFaults[cyl] ?? false;

    bool get cmpFault => cmpFaultMode != 0;
  
    String get currentSensorFaultCode =>
        EngineFaults.getSensorFaultCode(
          ckpFaultMode: ckpFaultMode,
          cmpFaultMode: cmpFaultMode,
          ckpFault: ckpFault,
          cmpFault: cmpFault,
          appFault: appFault,
          mapFault: mapFault,
          iatFault: iatFault,
          ectFault: ectFault,
          oilTempFault: oilTempFault,
          fuelPumpFault: fuelPumpFault,
        );
  
    String get currentSensorFaultLabel =>
        EngineFaults.getSensorFaultLabel(
          ckpFault: ckpFault,
          cmpFault: cmpFault,
          appFault: appFault,
          mapFault: mapFault,
          iatFault: iatFault,
          ectFault: ectFault,
          oilTempFault: oilTempFault,
          fuelPumpFault: fuelPumpFault,
        );
  
    String get currentInjectorFaultCode =>
        EngineFaults.getInjectorFaultCode(
          injectorFaults,
        );
  
    String get currentInjectorFaultLabel =>
        EngineFaults.getInjectorFaultLabel(
          injectorFaults,
        );
  
    String get currentInjectorFaultDescription =>
        EngineFaults.getInjectorFaultDescription(
          injectorFaults,
        );
  
    String get currentCoilFaultCode =>
        EngineFaults.getCoilFaultCode(
          coilFaults,
        );
  
    String get currentCoilFaultLabel =>
        EngineFaults.getCoilFaultLabel(
          coilFaults,
        );
  
    String get currentCoilFaultDescription =>
        EngineFaults.getCoilFaultDescription(
          coilFaults,
        );
  
  
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
  
    String get currentFaultDescription {
  
      if (currentSensorFaultCode.isNotEmpty) {
        return EngineFaults.getSensorFaultDescription(
          ckpFault: ckpFault,
          cmpFault: cmpFault,
          appFault: appFault,
          mapFault: mapFault,
          iatFault: iatFault,
          ectFault: ectFault,
          oilTempFault: oilTempFault,
          fuelPumpFault: fuelPumpFault,
        );
      }
  
      if (currentInjectorFaultCode.isNotEmpty) {
        return EngineFaults.getInjectorFaultDescription(
          injectorFaults,
        );
      }
  
      if (currentCoilFaultCode.isNotEmpty) {
        return EngineFaults.getCoilFaultDescription(
          coilFaults,
        );
      }
  
      return '';
    }
  
    String get currentFaultSymptom {
  
      if (currentSensorFaultCode.isNotEmpty) {
        return EngineFaults.getFaultSymptom(
          ckpFaultMode: ckpFaultMode,
          ckpFault: ckpFault,
          cmpFaultMode: cmpFaultMode,
          cmpFault: cmpFault,
          appFault: appFault,
          mapFault: mapFault,
          iatFault: iatFault,
          ectFault: ectFault,
          oilTempFault: oilTempFault,
          fuelPumpFault: fuelPumpFault,
        );
      }
  
      if (currentInjectorFaultCode.isNotEmpty) {
        return EngineFaults.getInjectorFaultSymptom(
          injectorFaults,
        );
      }
  
      if (currentCoilFaultCode.isNotEmpty) {
        return EngineFaults.getCoilFaultSymptom(
          coilFaults,
        );
      }
  
      return '';
    }
  
    bool get hasAnyFault {
      return ckpFault ||
          cmpFault ||
          appFault ||
          iatFault ||
          mapFault ||
          ectFault ||
          oilTempFault ||
          fuelPumpFault ||
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

      // CKP fault
      if (ckpFaultMode == 2) {

        return Offset(
          sin(t * 45) * 2.5,
          cos(t * 38) * 1.8,
        );
      }

      if (ckpFaultMode == 3) {

        return Offset(
          sin(t * 55) * 3.2,
          cos(t * 42) * 2.0,
        );
      }

      if (ckpFaultMode == 4) {

        return Offset(
          sin(t * 60) * 4.0,
          cos(t * 50) * 2.5,
        );
      }
  
      if (cmpFault) {
        return Offset(sin(t * 38) * 1.8, cos(t * 29) * 1.1);
      }
  
      if (injectorFaults.containsValue(true) || coilFaults.containsValue(true)) {
        return Offset(sin(t * 42) * 2.2, cos(t * 31) * 1.4);
      }
  
      return Offset.zero;
    }
  
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
  
            if (ckpFaultMode != 1) {
  
              // 🔥 realtime từ STM32
              rpm = targetRPM;
  
              if (appFault) {
  
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
  
              if (mapFault) {
  
                // giới hạn công suất turbo
                if (targetRPM > 3200) {
                  targetRPM = 3200;
                }
  
                // rung nhẹ
                rpm += sin(
                  DateTime.now().millisecondsSinceEpoch / 180,
                ) * 12;
              }
  
              if (iatFault) {
  
                // nóng khí nạp -> ECU giảm hiệu suất
                if (targetRPM > 4000) {
                  targetRPM = 4000;
                }
  
                // máy hơi ì
                rpm += sin(
                  DateTime.now().millisecondsSinceEpoch / 220,
                ) * 8;
              }
              if (oilTempFault) {
  
                // ECU fallback mode
                rpm += sin(
                  DateTime.now().millisecondsSinceEpoch / 220,
                ) * 5;
  
                // phản hồi ga chậm nhẹ
                rpm += (targetRPM - rpm) * 0.02;
              }
              if (fuelPumpFault) {
  
                // hụt ga
                rpm -= _rand.nextDouble() * 20;
  
                // rung máy
                rpm += sin(
                  DateTime.now().millisecondsSinceEpoch / 90,
                ) * 15;
  
                // giới hạn rpm
                if (targetRPM > 3500) {
                  targetRPM = 3500;
                }
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
  
                renderAngle += diff * 0.03;
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
            // P0337
            if (ckpFaultMode == 2) {
  
              rpm += sin(
                DateTime.now().millisecondsSinceEpoch / 120,
              ) * 80;
            }
  
  // P0338
                if (ckpFaultMode == 3) {
  
                  rpm += _rand.nextDouble() * 120;
                }
  
  // P0339
                if (ckpFaultMode == 4) {
  
                  if (_rand.nextDouble() < 0.08) {
                    rpm -= 120;
                  }
                }
  
        if (ckpFaultMode == 1 && rpm < 250) {
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

    void toggleCMPFault() {

      setState(() {

        cmpFaultMode++;

        if (cmpFaultMode > 4) {
          cmpFaultMode = 0;
        }
      });
    }
  
    void toggleAPPFault() {
      setState(() {
        appFault = !appFault;
      });
    }
  
    void toggleIATBoostFault() {
      setState(() {
        mapFault = !mapFault;
      });
    }
  
    void toggleIATFault() {
      setState(() {
        iatFault = !iatFault;
      });
    }
  
    void toggleECTFault() {
      setState(() {
        ectFault = !ectFault;
      });
    }
  
    void toggleOilTempFault() {
      setState(() {
        oilTempFault = !oilTempFault;
      });
    }
  
    void toggleFuelPumpFault() {
      setState(() {
        fuelPumpFault = !fuelPumpFault;
      });
    }
  
    void toggleCKPFault() {
  
      setState(() {
  
        ckpFaultMode++;
  
        if (ckpFaultMode > 4) {
          ckpFaultMode = 0;
        }
      });
    }
    bool get ckpFault => ckpFaultMode != 0;
  
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
  
      if (ckpFaultMode == 1) return;
  
      setState(() {
  
        _lastInjectorTrigger.clear();
        _lastSparkTrigger.clear();
  
        isRunning = true;
        crankAngle = 0;
        renderAngle = 0;
        prevAngle = 719.9;
        injector = 0;
        spark = 0;
        rpm = 500;
        targetRPM = 500;
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
      if (!useSTM32 || ckpFaultMode == 1) return;
  
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

      if (ckpFaultMode == 1) return;
  
      if (hasInjectorFault(cyl)) {
        final now = DateTime.now().millisecondsSinceEpoch;
  
        if (now - _lastMisfireTime > 120 && _rand.nextDouble() < 0.7) {
          _lastMisfireTime = now;
        }
  
        return;
      }
  
      if (cmpGlitchActive && cyl.isEven) return;
  
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
  
      if (ckpFaultMode == 1) return;
  
      if (hasCoilFault(cyl)) {
  
        final now = DateTime.now().millisecondsSinceEpoch;
  
        if (now - _lastMisfireTime > 120 && _rand.nextDouble() < 0.8) {
          _lastMisfireTime = now;
        }
  
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
      if (!isRunning) return;
  
      if (appFault && _rand.nextDouble() < 0.08) {
        return;
      }
  
      if (fuelPumpFault && _rand.nextDouble() < 0.10) {
        return;
      }
  
      if (ckpFaultMode == 4) {
  
        double failRate =
        (rpm / 6000).clamp(0.2, 0.8);
  
        if (_rand.nextDouble() < failRate) {
          return;
        }
      }

      // CMP P0341
      if (cmpFaultMode == 2) {

        rpm += sin(
          DateTime.now().millisecondsSinceEpoch / 150,
        ) * 25;
      }

// CMP P0344
      if (cmpFaultMode == 4) {

        if (_rand.nextDouble() < 0.05) {
          rpm -= 80;
        }
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
                  color: Colors.black,
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
                            crankAngle: renderAngle,
                            activeSparkCylinders: activeSparkCylinders,
                            injectorCylinder: injector,
                            isRunning: isRunning,
                            injectorFaults: injectorFaults,
                            coilFaults: coilFaults,
                            shakeOffset: faultShakeOffset,
                            ckpFault: ckpFault,
                            cmpFault: cmpFault,
                            rpm: currentRpm,
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 0,
                          child: SizedBox(
                            height: 90,
                            child: CustomPaint(
                              painter: CKPWaveformPainter(
                                crankAngle: renderAngle,
                                rpm: currentRpm,
                              ),
                            ),
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
              bottom: -5,
              child: Image.asset(
                'assets/images/obd_device.png',
                width: 190,
                height: 170,
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
                right: 33,
                bottom: 30,
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
                        horizontal: 6,
                        vertical: 3,
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
                            currentFaultCode,
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
  
                          const SizedBox(height: 2),
  
                          Text(
                            currentFaultLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
  
                          const SizedBox(height: 2),
  
                          SizedBox(
                            width: 120,
                            child: Text(
                              currentFaultDescription,
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 7,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
  
                          SizedBox(
                            width: 130,
                            child: Text(
                              currentFaultSymptom,
                              softWrap: true,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 5.8,
                                fontStyle: FontStyle.italic,
                                height: 1.15,
                              ),
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
                width: 30,
                height: 30,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: const FuelGauge(value: 100),
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              right: 880,
              child: EngineStartButton(
                isRunning: isRunning,
                onStart: startEngine,
                onStop: stopEngine,
              ),
            ),
            Positioned(
              bottom: 70,
              right: 800,
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
                          left: 164,
                          bottom: 315,
                          child: CustomPaint(
                            size: const Size(10, 130),
                            painter: ElectricPathPainterCustom1(
                              electricController.value,
                              rpm,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 140,
                          bottom: 320,
                          child: CustomPaint(
                            size: const Size(10,-10),
                            painter: ElectricPathPainterCustom2(
                              electricController.value,
                              rpm,
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
            Positioned(
              left: 360,
              top: 390,
              child: GestureDetector(
                onTap: toggleAPPFault,
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              left: 405,
              top: 390,
              child: GestureDetector(
                onTap: toggleIATBoostFault,
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              left: 450,
              top: 390,
              child: GestureDetector(
                onTap: toggleIATFault,
                child: Container(
                  width: 20,
                  height: 40,
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              left: 485,
              top: 390,
              child: GestureDetector(
                onTap: toggleECTFault,
                child: Container(
                  width: 20,
                  height: 40,
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              left: 520,
              top: 390,
              child: GestureDetector(
                onTap: toggleOilTempFault,
                child: Container(
                  width: 20,
                  height: 40,
  
                  // tạm thời để nhìn hitbox
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              left: 140,
              top: 330,
              child: GestureDetector(
                onTap: toggleFuelPumpFault,
                child: Container(
                  width: 60,
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
