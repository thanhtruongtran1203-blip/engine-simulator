import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dart:async';
import 'dart:math';
import 'engine_3d_screen.dart';

class EngineScreen extends StatefulWidget {
  const EngineScreen({super.key});

  @override
  State<EngineScreen> createState() => _EngineScreenState();
}

class _EngineScreenState extends State<EngineScreen>
    with SingleTickerProviderStateMixin {
  double rpm = 1000;
  double fakeRPM = 1000; // 🔥 RPM giả lập
  double crankAngle = 0;
  int spark = 0;
  int injector = 0;
  bool useSTM32 = false; // 🔥 false = dùng Timer, true = dùng STM32
  bool isRunning = false;
  double simScale = 0.2; // 👈 chỉnh tốc độ tại đây
  int lastFired = -1;
  double prevAngle = 0;
  // 🔥 firing order
  List<int> firingOrder = [1, 3, 4, 2];

  Timer? injTimer;
  Timer? engineLoop;
  int injectorPulseId = 0;
  int sparkPulseId = 0;
  final fireAngle = {
    1: 0.0,
    3: 180.0,
    4: 360.0,
    2: 540.0,
  };

  late AnimationController electricController;
  double get currentRpm {
    final value = useSTM32 ? rpm : fakeRPM;
    return value.clamp(500, 6000);
  }

  double get eventIntervalMs {
    // 4 xy lanh, 4 kỳ, mỗi lần đánh lửa cách nhau 180 độ
    return 120000 / currentRpm;
  }

  int sparkDurationMs() {
    // Bosch coil spark duration thường chỉ khoảng ~1-2 ms
    return min(2, max(1, (eventIntervalMs * 0.12).round()));
  }

  int injectorDurationMs() {
    // Bosch EV14 có độ trễ mở kim tvub phụ thuộc điện áp.
    // Ở đây giả lập hệ 14V => lấy gần đúng 0.9 ms.
    const double tvubMs = 0.9;

    // Vì bạn chưa có load/MAP/TPS, đây là fake model trực quan:
    // pulse tăng nhẹ theo RPM nhưng vẫn bị giới hạn để không chồng nhịp.
    final double t = ((currentRpm - 500) / (6000 - 500)).clamp(0, 1);
    final double baseFuelMs = 2.2 + (t * 4.8); // 2.2 ms -> 7.0 ms
    final double totalMs = tvubMs + baseFuelMs;

    return min(totalMs, eventIntervalMs * 0.7).round().clamp(3, 12);
  }

  @override
  void initState() {
    super.initState();
    // TEST QUAY TRỤC KHUỶU
    // Animation
    electricController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // 🔥 GIẢ LẬP PHUN 1-3-4-2
    // 🔥 ENGINE LOOP (giả lập ECU theo góc)
    engineLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isRunning) return;

      if (!useSTM32) {
        double currentRPM = fakeRPM;

        double step = currentRPM * 6 * 0.016 * simScale;

        int subSteps = 50;
        double subStepAngle = step / subSteps;

        for (int i = 0; i < subSteps; i++) {
          crankAngle += subStepAngle;

          if (crankAngle >= 720) {
            crankAngle -= 720;
          }

          checkFireByAngle();
        }
        setState(() {});
      }
    });
  }

  void startEngine() {
    setState(() {
      isRunning = true;

      crankAngle = 0;
      prevAngle = 0; // ✅ QUAN TRỌNG
    });

    electricController.repeat();
  }

  void stopEngine() {
    setState(() {
      isRunning = false;
      injector = 0;
      spark = 0;
    });

    electricController.stop();
  }
  @override
  void dispose() {
    engineLoop?.cancel();
    electricController.dispose();
    injTimer?.cancel();
    super.dispose();
  }
  void parseFrame(String data) {
    if (!useSTM32) return;

    RegExp reg = RegExp(r'R=(\d+),A=(\d+),S=(\d+),I=(\d+)');

    final match = reg.firstMatch(data);

    if (match != null) {
      int newSpark = int.parse(match.group(3)!);
      int newInj = int.parse(match.group(4)!);

      if (newInj != 0) triggerInjector(newInj);
      if (newSpark != 0) triggerSpark(newSpark);

      setState(() {
        rpm = double.parse(match.group(1)!);
        crankAngle = double.parse(match.group(2)!);
      });
    }
  }
  void triggerInjector(int cyl) {
    final pulseId = ++injectorPulseId;

    setState(() {
      injector = cyl;
    });

    final int duration = injectorDurationMs();

    Future.delayed(Duration(milliseconds: duration), () {
      if (mounted && pulseId == injectorPulseId && injector == cyl) {
        setState(() {
          injector = 0;
        });
      }
    });
  }
  void triggerSpark(int cyl) {
    final pulseId = ++sparkPulseId;

    setState(() {
      spark = cyl;
    });

    final int duration = sparkDurationMs();

    Future.delayed(Duration(milliseconds: duration), () {
      if (mounted && pulseId == sparkPulseId && spark == cyl) {
        setState(() {
          spark = 0;
        });
      }
    });
  }

  void checkFireByAngle() {
    List<int> order = [1, 3, 4, 2];

    for (int cyl in order) {
      double target = fireAngle[cyl]!;

      if (isAnglePassed(prevAngle, crankAngle, target)) {
        triggerInjector(cyl);
        triggerSpark(cyl);
        print("🔥 FIRE: $cyl | target: $target");

        lastFired = cyl;
      }
    }
    prevAngle = crankAngle; // 🔥 BẮT BUỘC PHẢI CÓ
  }
  bool isAnglePassed(double prev, double current, double target) {
    // case bình thường
    if (prev < current) {
      return target > prev && target <= current;
    }

    // case vượt 720 → 0
    else {
      return target > prev || target <= current;
    }
  }
  void fireIfCrossed(int cyl) {
    double target = fireAngle[cyl]!;

    bool crossed = false;

    // ✅ detect vượt góc
    if (prevAngle <= target && crankAngle > target) {
      crossed = true;
    }

    // ✅ xử lý vòng 720 → 0
    if (prevAngle > crankAngle) {
      if (target >= prevAngle || target <= crankAngle) {
        crossed = true;
      }
    }

    if (crossed) {
      triggerInjector(cyl);

      print("🔥 FIRE: $cyl | Angle: $crankAngle");
    }
  }
  bool isNear(double a, double b) {
    return (a - b).abs() < 10; // 🔥 tolerance
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    double displayRPM = useSTM32 ? rpm : fakeRPM;
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
          /// TITLE TRÊN ĐẦU
          const Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "MÔ PHỎNG HOẠT ĐỘNG CỦA ĐỘNG CƠ",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            top: 250,
            right: 70, // 👈 dính sát bên phải
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4, // 👈 50% ngang
              height: MediaQuery.of(context).size.height * 0.4, // 👈 50% cao
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ), // 👈 bo góc bên trái cho đẹp
                border: Border.all(color: Colors.white24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Engine2DPreview(
                crankAngle: crankAngle,
                sparkCylinder: spark,
                injectorCylinder: injector,
                isRunning: isRunning,
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context); // 👈 quay lại danh sách engine
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.arrow_back, // 👈 mũi tên quay lại
                  color: Colors.white,
                  size: 15, // 👈 cùng size với nút 3D
                ),
              ),
            ),
          ),
          /// Hệ thống phun xăng điện tử
          const Positioned(
            top: 180,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Hệ thống phun xăng điện tử",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800, // đậm mạnh hơn
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// Van điều khiển
          const Positioned(
            top: 458,
            left: 0,
            right: 330,
            child: Center(
              child: Text(
                "Van điều khiển",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// Bộ điều áp nhiên liệu
          const Positioned(
            top: 415,
            left: 75,
            right: 0,
            child: Center(
              child: Text(
                "Bộ điều áp nhiên liệu",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// Ống chân không từ phía sau cổ hút
          const Positioned(
            top: 430,
            left: 220,
            right: 0,
            child: Center(
              child: Text(
                "Ống chân không từ phía sau cổ hút",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// Fuel rail
          const Positioned(
            top: 452,
            left: 335,
            right: 0,
            child: Center(
              child: Text(
                "Fuel rail",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// Injectors
          const Positioned(
            top: 470,
            left: 310,
            right: 0,
            child: Center(
              child: Text(
                "Injectors",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// Fuel filter
          const Positioned(
            top: 490,
            left: 0,
            right: 130,
            child: Center(
              child: Text(
                "Fuel\nfilter",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// Evaporative emissions canister
          const Positioned(
            top: 520,
            left: 0,
            right: 307,
            child: Center(
              child: Text(
                "Evaporative\nemissions\ncanister",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// Fuel tank
          const Positioned(
            top: 557,
            left: 0,
            right: 300,
            child: Center(
              child: Text(
                "Fuel tank",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// ECU
          const Positioned(
            top: 573,
            left: 0,
            right: 110,
            child: Center(
              child: Text(
                "ECU",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// Electric fuel pump
          const Positioned(
            top: 600,
            left: 0,
            right: 170,
            child: Center(
              child: Text(
                "Electric fuel pump",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// High pressure fuel line
          const Positioned(
            top: 680,
            left: 0,
            right: 165,
            child: Center(
              child: Text(
                "High pressure fuel line",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// Fuel return line
          const Positioned(
            top: 692,
            left: 0,
            right: 200,
            child: Center(
              child: Text(
                "Fuel return line",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// A
          const Positioned(
            top: 615,
            left: 5,
            right: 0,
            child: Center(
              child: Text(
                "A",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// B
          const Positioned(
            top: 615,
            left: 63,
            right: 0,
            child: Center(
              child: Text(
                "B",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// C
          const Positioned(
            top: 615,
            left: 140,
            right: 0,
            child: Center(
              child: Text(
                "C",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// D
          const Positioned(
            top: 615,
            left: 200,
            right: 0,
            child: Center(
              child: Text(
                "D",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// E
          const Positioned(
            top: 615,
            left: 253,
            right: 0,
            child: Center(
              child: Text(
                "E",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// F
          const Positioned(
            top: 615,
            left: 303,
            right: 0,
            child: Center(
              child: Text(
                "F",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// G
          const Positioned(
            top: 615,
            left: 357,
            right: 0,
            child: Center(
              child: Text(
                "G",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          /// NOTE
          const Positioned(
            top: 640,
            left: 132,
            right: 0,
            child: Center(
              child: Text(
                "A. Crankshaft speed position\nB. Camshaft speed position\nC. Accelerator pedal brake\nD. Boost temp sensor\nE. Air temp sensor\nF. Coolant temp sensor\nG. Oil temp sensor",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          /// RPM (trái)
          Positioned(
            left: 109,
            top: 762,
            child: SizedBox(
              width: 50,
              height: 50,
              child: _buildRPMGauge(displayRPM),
            ),
          ),

          /// SPEED (giữa)
          Positioned(
            left: 157,
            top: 715,
            child: SizedBox(
              width: 100,
              height: 100,
              child: _buildSpeedGauge(displayRPM / 40),
            ),
          ),

          /// FUEL (phải)
          Positioned(
            right: 125,   // căn theo mép phải (chuẩn hơn left)
            top: 777,    // chỉnh cao xuống 1 chút
            child: SizedBox(
              width: 30,
              height: 30,
              child: FittedBox(
                fit: BoxFit.contain,
                child: _buildFuelGauge(100),
              ),
            ),
          ),
          ///Start/Stop
          Positioned(
            bottom: 55,
            right: 40,
            child: EngineStartButton(
              isRunning: isRunning,
              onStart: startEngine,
              onStop: stopEngine,
            ),
          ),
          /// SMT32MODE/FAKEMODE
          Positioned(
            bottom: 70,
            left: 20,
            child: SizedBox(
              height: 28, // giảm chiều cao
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0), // giảm padding
                  minimumSize: const Size(60, 28), // size nhỏ
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap, // bỏ vùng dư
                ),
                onPressed: () {
                  setState(() {
                    useSTM32 = !useSTM32;
                  });
                },
                child: Text(
                  useSTM32 ? "STM32" : "FAKE", // rút gọn chữ cho đẹp
                  style: const TextStyle(fontSize: 8),
                ),
              ),
            ),
          ),
          /// ẢNH EFI
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

          /// 🔥 SLIDER RPM FAKE
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              children: [
                Text(
                  "RPM: ${fakeRPM.toInt()}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                /// 🔥 ÉP SLIDER SÁT LẠI
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2, // mỏng lại cho đẹp
                    overlayShape: SliderComponentShape.noOverlay, // bỏ vòng tròn to
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6, // nhỏ lại
                    ),
                  ),
                  child: Slider(
                    min: 500,
                    max: 6000,
                    divisions: 55,
                    value: fakeRPM,
                    onChanged: useSTM32
                        ? null
                        : (value) {
                      setState(() {
                        fakeRPM = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          /// LAYER 3: ĐIỆN (TRÊN CÙNG)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: electricController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      /// ⚡ PATH CUSTOM
                      Positioned(
                        left: 153,
                        bottom: 286,
                        child: CustomPaint(
                          size: const Size(100, 100),
                          painter: ElectricPathPainterCustom(
                              electricController.value),
                        ),
                      ),

                      /// FUEL
                      Positioned(
                        left: 110,
                        bottom: 278,
                        child: CustomPaint(
                          size: const Size(10,97),
                          painter: ElectricPathPainterCustom1(
                            electricController.value,
                            useSTM32 ? rpm : fakeRPM,
                          ),
                        ),
                      ),

                      /// FUEL RETURN
                      Positioned(
                        left: 92,
                        bottom: 290,
                        child: CustomPaint(
                          size: const Size(150, 153),
                          painter: ElectricPathPainterCustom2(
                            electricController.value,
                            useSTM32 ? rpm : fakeRPM,
                          ),
                        ),
                      ),

                      /// WIRE CHIA KHOA
                      Positioned(
                        left: 140,
                        bottom: 209,
                        child: CustomPaint(
                          size: const Size(53, 70),
                          painter: ElectricPathPainter1(
                              electricController.value),
                        ),
                      ),

                      /// WIRE KHUYU
                      Positioned(
                        left: 173,
                        bottom: 260,
                        child: CustomPaint(
                          size: const Size(100, 42),
                          painter: ElectricPathPainter2(
                              electricController.value),
                        ),
                      ),

                      /// WIRE CAM
                      Positioned(
                        left: 203,
                        bottom: 260,
                        child: CustomPaint(
                          size: const Size(100, 42),
                          painter: ElectricPathPainter2(
                              electricController.value),
                        ),
                      ),

                      /// WIRE BRAKE
                      Positioned(
                        left: 225,
                        bottom: 267,
                        child: CustomPaint(
                          size: const Size(100, 37),
                          painter: ElectricPathPainter2(
                              electricController.value),
                        ),
                      ),

                      /// WIRE TEMP
                      Positioned(
                        left: 265,
                        bottom: 265,
                        child: CustomPaint(
                          size: const Size(100, 38),
                          painter: ElectricPathPainter2(
                              electricController.value),
                        ),
                      ),

                      /// WIRE TEMP AIR
                      Positioned(
                        left: 282,
                        bottom: 270,
                        child: CustomPaint(
                          size: const Size(100, 32),
                          painter: ElectricPathPainter3(
                              electricController.value),
                        ),
                      ),

                      /// WIRE TEMP COOLANT
                      Positioned(
                        left: 307,
                        bottom: 273,
                        child: CustomPaint(
                          size: const Size(100, 30),
                          painter: ElectricPathPainter3(
                              electricController.value),
                        ),
                      ),

                      /// WIRE TEMP OIL
                      Positioned(
                        left: 335,
                        bottom: 274,
                        child: CustomPaint(
                          size: const Size(100, 28),
                          painter: ElectricPathPainter3(
                              electricController.value),
                        ),
                      ),

                      /// WIRE MAIN
                      Positioned(
                        left: 190,
                        bottom: 245,
                        child: CustomPaint(
                          size: const Size(203, 100),
                          painter: ElectricPathPainter4(
                              electricController.value),
                        ),
                      ),

                      /// INJECTOR 1
                      Positioned(
                        left: 214,
                        bottom: 330,
                        child: CustomPaint(
                          size: const Size(30, 40),
                          painter: StaticInjectorPainter(isActive: injector == 1),
                        ),
                      ),

                      /// INJECTOR 3
                      Positioned(
                        left: 280,
                        bottom: 330,
                        child: CustomPaint(
                          size: const Size(30, 40),
                          painter: StaticInjectorPainter(isActive: injector == 3),
                        ),
                      ),

                      /// INJECTOR 4
                      Positioned(
                        left: 314,
                        bottom: 330,
                        child: CustomPaint(
                          size: const Size(30, 40),
                          painter: StaticInjectorPainter(isActive: injector == 4),
                        ),
                      ),

                      /// INJECTOR 2
                      Positioned(
                        left: 247,
                        bottom: 330,
                        child: CustomPaint(
                          size: const Size(30, 40),
                          painter: StaticInjectorPainter(isActive: injector == 2),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildRPMGauge(double rpm) {
  return SfRadialGauge(
    axes: [
      RadialAxis(
        minimum: 0,
        maximum: 8,
        interval: 1,

        startAngle: 140,
        endAngle: 40,

        showAxisLine: false,

        minorTicksPerInterval: 4,

        majorTickStyle: const MajorTickStyle(
          length: 6,
          thickness: 1.1,
          color: Colors.white,
        ),
        labelOffset: -5, // đẩy số ra ngoài
        minorTickStyle: const MinorTickStyle(
          length: 3,
          thickness: 1,
          color: Colors.white54,
        ),

        axisLabelStyle: const GaugeTextStyle(
          color: Colors.white,
          fontSize: 4,
        ),

        ranges: [
          GaugeRange(
            startValue: 6,
            endValue: 8,
            color: Colors.red,
            startWidth: 5,
            endWidth: 5,
          ),
        ],

        pointers: [
          NeedlePointer(
            value: rpm / 1000, // QUAN TRỌNG
            needleColor: Colors.red,
            needleStartWidth: 0.5,   // đuôi kim nhỏ lại
            needleEndWidth: 2,     // đầu kim vừa phải
            needleLength: 0.6,
            knobStyle: const KnobStyle(
              color: Colors.white,
              knobRadius: 0.1, // 👈 giảm nhỏ lại (mặc định ~0.08)
            ),
          ),
        ],

        annotations: const [
          GaugeAnnotation(
            widget: Text(
              "RPMx1000",
              style: TextStyle(
                color: Colors.white,
                fontSize: 4,
              ),
            ),
            angle: 90,
            positionFactor: 0.9,
          ),
        ],
      ),
    ],
  );
}

Widget _buildSpeedGauge(double speed) {
  return SfRadialGauge(
    axes: [
      RadialAxis(
        minimum: 0,
        maximum: 200,

        startAngle: 135,
        endAngle: 45,
        showAxisLine: false,
        interval: 20,
        minorTicksPerInterval: 4,
        majorTickStyle: const MajorTickStyle(
          length: 7,
          thickness: 1.1,
          color: Colors.white,
        ),
        labelOffset: -1, // đẩy số ra ngoài
        minorTickStyle: const MinorTickStyle(
          length: 3,
          thickness: 1,
          color: Colors.white54,
        ),
        axisLabelStyle: const GaugeTextStyle(
          color: Colors.white,
          fontSize: 6,
        ),
        ranges: [
          GaugeRange(
            startValue: 160,
            endValue: 200,
            color: Colors.red,
            startWidth: 5,
            endWidth: 5,
          ),
        ],

        pointers: [
          NeedlePointer(
            value: speed * 0.98, // FIX LỆCH
            needleColor: Colors.red,
            needleStartWidth: 0.5,   // đuôi kim nhỏ lại
            needleEndWidth: 4,     // đầu kim vừa phải
            needleLength: 0.7,
            knobStyle: const KnobStyle(color: Colors.white),
          ),
        ],

        /// CHỈ GIỮ KM/H
        annotations: const [
          GaugeAnnotation(
            widget: Text(
              "KM/H",
              style: TextStyle(color: Colors.white, fontSize: 8,),
            ),
            angle: 90,
            positionFactor: 0.9,
          ),
        ],
      ),
    ],
  );
}

Widget _buildFuelGauge(double value) {
  int level = (value / 20).round(); // 0 → 5 mức

  return SizedBox(
    width: 70,
    height: 180,
    child: Stack(
      children: [
        /// CỘT XĂNG
        Positioned(
          left: 0,
          top: 0,
          child: Container(
            width: 30,
            height: 170,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                /// LEVEL (đã fix khít)
                Expanded(
                  child: Column(
                    children: List.generate(5, (index) {
                      bool isActive = index < level;

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 1), // KHÍT
                          decoration: BoxDecoration(
                            color: isActive ? Colors.white : Colors.transparent,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        ),
                      );
                    }).reversed.toList(),
                  ),
                ),

                const SizedBox(width: 3),

                /// VẠCH CHIA
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    return Container(
                      width: 8,
                      height: 2,
                      color: Colors.white,
                    );
                  }),
                ),
              ],
            ),
          ),
        ),

        /// F
        Positioned(
          left: 40,
          top: 0,
          child: const Text(
            "F",
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
        ),

        /// E (căn ngang vạch dưới)
        Positioned(
          left: 40,
          bottom: 12,
          child: const Text(
            "E",
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
        ),

        /// ICON xăng (đối diện E)
        Positioned(
          left: 40,
          bottom: 85,
          child: const Icon(
            Icons.local_gas_station,
            color: Colors.white,
            size: 22,
          ),
        ),
      ],
    ),
  );
}


class ElectricPathPainter1 extends CustomPainter {
  final double progress;

  ElectricPathPainter1(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    /// DÂY
    final linePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double startY = size.height - 10;
    double endX = size.width - 10;

    final path = Path()
      ..moveTo(0, startY)
      ..lineTo(endX, startY)
      ..lineTo(endX, 10);

    canvas.drawPath(path, linePaint);

    /// CHIỀU DÀI
    double horizontal = endX;
    double vertical = startY - 10;
    double totalLength = horizontal + vertical;

    int count = 5;
    double spacing = totalLength / count;

    for (int i = 0; i < count; i++) {
      double baseDistance = i * spacing;
      double distance = baseDistance + (progress * totalLength);
      distance %= totalLength;

      double x, y;

      if (distance < horizontal) {
        /// đoạn ngang
        x = distance;
        y = startY;
      } else {
        /// đoạn dọc
        double remain = distance - horizontal;
        x = endX;
        y = startY - remain;
      }

      /// ⚡ ZIGZAG (thay cho chấm)
      Path lightning = Path();
      lightning.moveTo(x, y);
      lightning.lineTo(x + 3, y - 2);
      lightning.lineTo(x - 3, y - 5);

      canvas.drawPath(
        lightning,
        Paint()
          ..color = Colors.yellow
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ElectricPathPainter2 extends CustomPainter {
  final double progress;

  ElectricPathPainter2(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    /// STYLE DÂY
    final linePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    /// VỊ TRÍ
    double startX = size.width / 2;
    double startY = size.height - 10;
    double endY = 10;

    /// VẼ DÂY
    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX, endY),
      linePaint,
    );

    /// CHIỀU DÀI
    double wireLength = (startY - endY).abs();

    /// SỐ TIA
    int count = 1;

    /// KHOẢNG CÁCH ĐỀU
    double spacing = wireLength / count;
    double speed = 1;
    for (int i = 0; i < count; i++) {
      /// ⚡ vị trí gốc (cách đều)
      double base = i * spacing;

      /// ⚡ thêm animation
      double speed = 3.0; // tăng lên = chạy nhanh hơn
      double distance = base + (progress * wireLength * speed);

      /// loop lại
      distance %= wireLength;

      /// ⚡ vị trí Y (dưới → lên)
      double y = startY - distance;

      /// ⚡ TIA ĐIỆN
      Path lightning = Path();
      lightning.moveTo(startX, y);
      lightning.lineTo(startX + 2, y - 3);
      lightning.lineTo(startX - 2, y - 6);

      canvas.drawPath(
        lightning,
        Paint()
          ..color = Colors.yellow
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ElectricPathPainter3 extends CustomPainter {
  final double progress;

  ElectricPathPainter3(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    /// STYLE DÂY
    final linePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    /// VỊ TRÍ
    double startX = size.width / 2;
    double startY = size.height - 10;
    double endY = 10;

    /// VẼ DÂY
    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX, endY),
      linePaint,
    );

    /// CHIỀU DÀI
    double wireLength = (startY - endY).abs();

    /// 🔥 SỐ TIA
    int count = 1;

    /// 🔥 KHOẢNG CÁCH ĐỀU
    double spacing = wireLength / count;
    double speed = 4;
    for (int i = 0; i < count; i++) {
      /// vị trí gốc (cách đều)
      double base = i * spacing;

      /// thêm animation
      double speed = 4; // tăng lên = chạy nhanh hơn
      double distance = base + (progress * wireLength * speed);

      /// loop lại
      distance %= wireLength;

      /// vị trí Y (dưới → lên)
      double y = startY - distance;

      /// TIA ĐIỆN
      Path lightning = Path();
      lightning.moveTo(startX, y);
      lightning.lineTo(startX + 2, y - 3);
      lightning.lineTo(startX - 2, y - 6);

      canvas.drawPath(
        lightning,
        Paint()
          ..color = Colors.yellow
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class ElectricPathPainter4 extends CustomPainter {
  final double progress;

  ElectricPathPainter4(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    double startX = 10;
    double endX = size.width - 10;
    double centerY = size.height / 2;

    canvas.drawLine(
      Offset(startX, centerY),
      Offset(endX, centerY),
      linePaint,
    );

    double wireLength = endX - startX;

    /// SỐ TIA
    int count = 7;

    /// KHOẢNG CÁCH ĐỀU
    double spacing = wireLength / count;

    for (int i = 0; i < count; i++) {
      /// ⚡ vị trí gốc (cách đều)
      double baseX = endX - (i * spacing);

      /// ⚡ thêm animation (dịch chuyển)
      double x = baseX - (progress * wireLength);

      /// loop lại khi ra khỏi màn
      if (x < startX) {
        x += wireLength;
      }

      double y = centerY;

      Path lightning = Path();
      lightning.moveTo(x, y);
      lightning.lineTo(x - 3, y - 2);
      lightning.lineTo(x - 6, y);

      canvas.drawPath(
        lightning,
        Paint()
          ..color = Colors.yellow
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ElectricPathPainterCustom extends CustomPainter {
  final double progress;

  ElectricPathPainterCustom(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double centerX = size.width / 2;
    double topY = -11;
    double bottomY = size.height - 20;

    double horizontalTop = 115;
    double horizontalBottom = 10;

    /// PATH
    Path path = Path()
      ..moveTo(centerX, topY)
      ..lineTo(centerX + horizontalTop, topY)
      ..moveTo(centerX, topY)
      ..lineTo(centerX, bottomY)
      ..lineTo(centerX - horizontalBottom, bottomY);

    canvas.drawPath(path, linePaint);

    double vertical = bottomY - topY;
    double totalLength = horizontalBottom + vertical + horizontalTop;

    int count = 10;
    double spacing = totalLength / count;
    double speed = 1;

    for (int i = 0; i < count; i++) {
      double base = i * spacing;

      double distance =
          (base + progress * totalLength * speed) % totalLength;

      double x, y;

      if (distance < horizontalBottom) {
        x = centerX - horizontalBottom + distance;
        y = bottomY;

      } else if (distance < horizontalBottom + vertical) {
        double d = distance - horizontalBottom;
        x = centerX;
        y = bottomY - d;

      } else {
        double d = distance - (horizontalBottom + vertical);
        x = centerX + d;
        y = topY;
      }

      Path lightning = Path();
      lightning.moveTo(x, y);
      lightning.lineTo(x + 3, y - 2);
      lightning.lineTo(x + 6, y);

      canvas.drawPath(
        lightning,
        Paint()
          ..color = Colors.yellow
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ElectricPathPainterCustom1 extends CustomPainter {
  final double progress;
  final double rpm;

  ElectricPathPainterCustom1(this.progress, this.rpm);

  @override
  void paint(Canvas canvas, Size size) {
    /// VẼ DÂY (GIỮ NGUYÊN)
    final linePaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double centerX = size.width / 2;
    double topY = -34;
    double bottomY = size.height - 20;

    double horizontalTop = 90;
    double horizontalBottom = 0;

    Path path = Path()
      ..moveTo(centerX, topY)
      ..lineTo(centerX + horizontalTop, topY)
      ..moveTo(centerX, topY)
      ..lineTo(centerX, bottomY)
      ..lineTo(centerX - horizontalBottom, bottomY);

    canvas.drawPath(path, linePaint);

    /// TÍNH TOÁN ĐƯỜNG
    double vertical = bottomY - topY;
    double totalLength = horizontalBottom + vertical + horizontalTop;

    int count = 10;
    double spacing = totalLength / count;
    double t = ((rpm - 500) / (6000 - 500)).clamp(0, 1);
    double speed = 0.5 + t * 4; // 🔥 scale theo RPM

    /// STYLE NÉT ĐỨT
    double dash = 8;

    Paint dashPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < count; i++) {
      double base = i * spacing;

      double distance =
          (base + progress * totalLength * speed) % totalLength;

      double x, y;

      if (distance < horizontalBottom) {
        x = centerX - horizontalBottom + distance;
        y = bottomY;

        /// GIỚI HẠN KHÔNG VƯỢT endX
        double endX = (x + dash).clamp(
          centerX - horizontalBottom,
          centerX - horizontalBottom + horizontalBottom,
        );

        canvas.drawLine(
          Offset(x, y),
          Offset(endX, y),
          dashPaint,
        );

      } else if (distance < horizontalBottom + vertical) {
        /// 🔹 ĐOẠN DỌC
        double d = distance - horizontalBottom;
        x = centerX;
        y = bottomY - d;

        /// GIỚI HẠN KHÔNG VƯỢT topY
        double endY = (y - dash).clamp(topY, bottomY);

        canvas.drawLine(
          Offset(x, y),
          Offset(x, endY),
          dashPaint,
        );

      } else {
        /// 🔹 ĐOẠN NGANG TRÊN
        double d = distance - (horizontalBottom + vertical);
        x = centerX + d;
        y = topY;

        /// GIỚI HẠN KHÔNG VƯỢT cuối dây
        double endX = (x + dash).clamp(
          centerX,
          centerX + horizontalTop,
        );

        canvas.drawLine(
          Offset(x, y),
          Offset(endX, y),
          dashPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
class ElectricPathPainterCustom2 extends CustomPainter {
  final double progress;
  final double rpm;

  ElectricPathPainterCustom2(this.progress, this.rpm);

  @override
  void paint(Canvas canvas, Size size) {
    /// STYLE DÂY (nền)
    final linePaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double startX = size.width - 10;
    double startY = 10;

    double leftX = 0;
    double bottomY = size.height - 10;

    /// PATH chữ L
    final path = Path()
      ..moveTo(startX, startY)
      ..lineTo(leftX, startY)   // ←
      ..lineTo(leftX, bottomY); // ↓

    canvas.drawPath(path, linePaint);

    /// TÍNH ĐỘ DÀI
    double horizontal = startX - leftX;
    double vertical = bottomY - startY;
    double totalLength = horizontal + vertical;

    /// STYLE NÉT ĐỨT
    double dashLength = 10;
    double gap = 6;
    double t = ((rpm - 500) / (6000 - 500)).clamp(0, 1);
    double speed = 0.5 + t * 4; // 🔥 scale theo RPM
    final dashPaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    /// OFFSET CHẠY
    double offset = (totalLength + (progress * totalLength)) % totalLength;

    /// VẼ NÉT ĐỨT CHẠY
    for (double d = 0; d < totalLength; d += dashLength + gap) {
      double distance = (d + offset) % totalLength;

      double x1, y1, x2, y2;

      if (distance < horizontal) {
        /// ← đoạn ngang
        x1 = startX - distance;
        y1 = startY;

        double next = (distance + dashLength).clamp(0, horizontal);
        x2 = startX - next;
        y2 = startY;
      } else {
        /// ↓ đoạn dọc
        double remain = distance - horizontal;

        x1 = leftX;
        y1 = startY + remain;

        double next = (remain + dashLength).clamp(0, vertical);
        x2 = leftX;
        y2 = startY + next;
      }

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
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
          Colors.orangeAccent.withOpacity(0.8),
          Colors.orangeAccent.withOpacity(0.5),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    Path cone = Path();
    cone.moveTo(centerX, 0);
    cone.lineTo(centerX - size.width * 0.25, size.height * 0.6);
    cone.lineTo(centerX + size.width * 0.25, size.height * 0.6);
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
class EngineStartButton extends StatefulWidget {
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const EngineStartButton({
    super.key,
    required this.isRunning,
    required this.onStart,
    required this.onStop,
  });

  @override
  State<EngineStartButton> createState() => _EngineStartButtonState();
}

class _EngineStartButtonState extends State<EngineStartButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) {
        setState(() => isPressed = false);

        if (widget.isRunning) {
          widget.onStop();
        } else {
          widget.onStart();
        }
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: widget.isRunning
                ? [Colors.redAccent, Colors.red.shade900]
                : [Colors.greenAccent, Colors.green.shade900],
          ),
          border: Border.all(
            color: widget.isRunning ? Colors.redAccent : Colors.greenAccent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: isPressed ? 4 : 15,
              offset: isPressed ? const Offset(2, 2) : const Offset(6, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.isRunning ? "STOP" : "START",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class Engine2DPreview extends StatelessWidget {
  final double crankAngle;
  final int sparkCylinder;
  final int injectorCylinder;
  final bool isRunning;

  const Engine2DPreview({
    super.key,
    required this.crankAngle,
    required this.sparkCylinder,
    required this.injectorCylinder,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(360, 230),
      painter: FourCylinderEnginePainter(
        crankAngle: crankAngle,
        sparkCylinder: sparkCylinder,
        injectorCylinder: injectorCylinder,
        isRunning: isRunning,
      ),
    );
  }
}

class FourCylinderEnginePainter extends CustomPainter {
  final double crankAngle;
  final int sparkCylinder;
  final int injectorCylinder;
  final bool isRunning;

  FourCylinderEnginePainter({
    required this.crankAngle,
    required this.sparkCylinder,
    required this.injectorCylinder,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF111315),
    );

    final blueWall = Paint()
      ..color = const Color(0xFF2893FF)
      ..style = PaintingStyle.fill;

    final darkMetal = Paint()
      ..color = const Color(0xFF3E434A)
      ..style = PaintingStyle.fill;

    final whiteMetal = Paint()
      ..color = const Color(0xFFF3F3F3)
      ..style = PaintingStyle.fill;

    final crankMetal = Paint()
      ..color = const Color(0xFFD9D9D9)
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

      _drawCylinder(
        canvas,
        size,
        centerX: centers[i],
        phase: (crankAngle + phaseOffsetsByCylinder[cylinder]!) % 720,
        pistonTheta:
        (crankAngle + pistonOffsetsByCylinder[cylinder]!) * pi / 180.0,
        label: '$cylinder',
        sparkOn: sparkCylinder == cylinder,
        injectorOn: injectorCylinder == cylinder,
        outline: outline,
        metal: whiteMetal,
        blueWall: blueWall,
        darkMetal: darkMetal,
        crankMetal: crankMetal,
      );
    }
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
        required Paint outline,
        required Paint metal,
        required Paint blueWall,
        required Paint darkMetal,
        required Paint crankMetal,
      }) {

    const chamberY = 58.0;
    const cylinderTop = 74.0;
    const cylinderBottom = 176.0;
    const crankY = 208.0;
    const crankRadius = 15.0;
    const rodLength = 64.0;
    const pistonWidth = 44.0;
    const pistonHeight = 50.0;

    final leftWall = centerX - 28;
    final rightWall = centerX + 28;

    final crankCenter = Offset(centerX, crankY);
    final crankPin = Offset(
      crankCenter.dx + crankRadius * sin(pistonTheta),
      crankCenter.dy - crankRadius * cos(pistonTheta),
    );

    final dx = crankPin.dx - centerX;
    final pistonPinY =
        crankPin.dy - sqrt(max(rodLength * rodLength - dx * dx, 0));

    final pistonRect = Rect.fromLTWH(
      centerX - pistonWidth / 2,
      pistonPinY - pistonHeight / 2,
      pistonWidth,
      pistonHeight,
    );

    final pistonPin = Offset(centerX, pistonRect.bottom - 9);

    _drawHeadAndValves(
      canvas,
      centerX: centerX,
      sparkOn: sparkOn,
      injectorOn: injectorOn,
      phase: phase,
      blueWall: blueWall,
      outline: outline,
    );

    canvas.drawRect(
      Rect.fromLTWH(centerX - 30, chamberY, 60, 12),
      blueWall,
    );

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

    canvas.drawRect(
      Rect.fromLTWH(
        leftWall + 9,
        cylinderTop,
        rightWall - leftWall - 18,
        cylinderBottom - cylinderTop,
      ),
      Paint()..color = const Color(0xFF1B1E22),
    );

    _drawPiston(canvas, pistonRect, metal, darkMetal, outline);
    _drawConnectingRod(canvas, crankPin, pistonPin, metal, outline);
    _drawCrank(canvas, crankCenter, crankPin, crankMetal, darkMetal, outline);

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

  void _drawHeadAndValves(
      Canvas canvas, {
        required double centerX,
        required bool sparkOn,
        required bool injectorOn,
        required double phase,
        required Paint blueWall,
        required Paint outline,
      }) {
    final intakeOpen = _intakeLift(phase);
    final exhaustOpen = _exhaustLift(phase);

    final intakeX = centerX - 12;
    final exhaustX = centerX + 12;

    const valveTopY = 26.0;
    const seatBaseY = 56.0;

    canvas.drawCircle(
      Offset(intakeX, valveTopY),
      6,
      Paint()..color = const Color(0xFF7FD8E8),
    );
    canvas.drawCircle(
      Offset(exhaustX, valveTopY),
      6,
      Paint()..color = const Color(0xFFFFC13A),
    );

    final stemPaint = Paint()
      ..color = const Color(0xFFCFB04E)
      ..strokeWidth = 2;

    final intakeSeatY = seatBaseY + intakeOpen * 8;
    final exhaustSeatY = seatBaseY + exhaustOpen * 8;

    canvas.drawLine(
      Offset(intakeX, valveTopY + 4),
      Offset(intakeX, intakeSeatY),
      stemPaint,
    );
    canvas.drawLine(
      Offset(exhaustX, valveTopY + 4),
      Offset(exhaustX, exhaustSeatY),
      stemPaint,
    );

    final intakeValve = Path()
      ..moveTo(intakeX - 6, intakeSeatY)
      ..quadraticBezierTo(intakeX, intakeSeatY + 5, intakeX + 6, intakeSeatY)
      ..lineTo(intakeX - 6, intakeSeatY);

    final exhaustValve = Path()
      ..moveTo(exhaustX - 6, exhaustSeatY)
      ..quadraticBezierTo(exhaustX, exhaustSeatY + 5, exhaustX + 6, exhaustSeatY)
      ..lineTo(exhaustX - 6, exhaustSeatY);

    canvas.drawPath(intakeValve, Paint()..color = const Color(0xFF111315));
    canvas.drawPath(exhaustValve, Paint()..color = const Color(0xFF111315));

    canvas.drawLine(
      Offset(centerX, 26),
      Offset(centerX, 58),
      Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = 2,
    );

    canvas.drawCircle(
      Offset(centerX, 58),
      2.5,
      Paint()..color = Colors.black,
    );

    /// Tia lửa màu đỏ
    if (sparkOn) {
      final sparkPath = Path()
        ..moveTo(centerX, 54)
        ..lineTo(centerX - 3, 60)
        ..lineTo(centerX + 2, 65)
        ..lineTo(centerX - 2, 70);

      canvas.drawPath(
        sparkPath,
        Paint()
          ..color = Colors.redAccent
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    /// Hòa khí nạp màu xanh dương
    if (intakeOpen > 0.05) {
      final intakeFlow = Path()
        ..moveTo(intakeX, intakeSeatY + 2)
        ..lineTo(intakeX - 5, intakeSeatY + 14)
        ..lineTo(intakeX + 5, intakeSeatY + 14)
        ..close();

      canvas.drawPath(
        intakeFlow,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xAA38BDF8), Color(0x0038BDF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(intakeX - 6, intakeSeatY + 2, 12, 14)),
      );
    }

    /// Khí xả màu xám trắng
    if (exhaustOpen > 0.05) {
      final exhaustFlow = Path()
        ..moveTo(exhaustX, exhaustSeatY + 2)
        ..lineTo(exhaustX - 5, exhaustSeatY + 14)
        ..lineTo(exhaustX + 5, exhaustSeatY + 14)
        ..close();

      canvas.drawPath(
        exhaustFlow,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xCCECEFF1), Color(0x00ECEFF1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(exhaustX - 6, exhaustSeatY + 2, 12, 14)),
      );
    }

    /// Phun nhiên liệu giữ màu cam
    if (injectorOn) {
      final spray = Path()
        ..moveTo(centerX, 60)
        ..lineTo(centerX - 6, 72)
        ..lineTo(centerX + 6, 72)
        ..close();

      canvas.drawPath(
        spray,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0x88FF8A00), Color(0x00FF8A00)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(centerX - 8, 60, 16, 14)),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - 32, 62, 8, 14),
        const Radius.circular(2),
      ),
      blueWall,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + 24, 62, 8, 14),
        const Radius.circular(2),
      ),
      blueWall,
    );
  }


  void _drawPiston(
      Canvas canvas,
      Rect rect,
      Paint whiteMetal,
      Paint darkMetal,
      Paint outline,
      ) {
    canvas.drawRect(rect, whiteMetal);

    final crownCut = Path()
      ..moveTo(rect.left + 4, rect.top + 12)
      ..lineTo(rect.center.dx - 10, rect.top + 18)
      ..lineTo(rect.center.dx, rect.top + 13)
      ..lineTo(rect.center.dx + 10, rect.top + 18)
      ..lineTo(rect.right - 4, rect.top + 12)
      ..lineTo(rect.right - 4, rect.top + 28)
      ..lineTo(rect.left + 4, rect.top + 28)
      ..close();

    canvas.drawPath(crownCut, darkMetal);

    for (int i = 0; i < 3; i++) {
      final y = rect.top + 6 + i * 4;
      canvas.drawLine(
        Offset(rect.left + 3, y),
        Offset(rect.right - 3, y),
        Paint()
          ..color = Colors.grey.shade700
          ..strokeWidth = 1,
      );
    }

    canvas.drawCircle(
      Offset(rect.center.dx, rect.center.dy + 1),
      3.2,
      Paint()..color = const Color(0xFF202328),
    );

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

    final nx = -dy / len;
    final ny = dx / len;

    const smallEnd = 6.0;
    const bigEnd = 10.0;

    final rodPath = Path()
      ..moveTo(pistonPin.dx + nx * smallEnd, pistonPin.dy + ny * smallEnd)
      ..lineTo(crankPin.dx + nx * bigEnd, crankPin.dy + ny * bigEnd)
      ..lineTo(crankPin.dx - nx * bigEnd, crankPin.dy - ny * bigEnd)
      ..lineTo(pistonPin.dx - nx * smallEnd, pistonPin.dy - ny * smallEnd)
      ..close();

    canvas.drawPath(rodPath, whiteMetal);
    canvas.drawPath(rodPath, outline);

    canvas.drawCircle(pistonPin, 5, Paint()..color = const Color(0xFFF3F3F3));
    canvas.drawCircle(pistonPin, 5, outline);

    canvas.drawCircle(crankPin, 6, Paint()..color = const Color(0xFFF3F3F3));
    canvas.drawCircle(crankPin, 6, outline);
  }

  void _drawCrank(
      Canvas canvas,
      Offset crankCenter,
      Offset crankPin,
      Paint crankMetal,
      Paint darkMetal,
      Paint outline,
      ) {
    canvas.drawCircle(crankCenter, 22, crankMetal);
    canvas.drawCircle(crankCenter, 22, outline);

    canvas.drawCircle(
      crankCenter,
      4,
      Paint()..color = const Color(0xFFA8A8A8),
    );

    final cheek = Path()
      ..moveTo(crankCenter.dx - 10, crankCenter.dy - 12)
      ..lineTo(crankPin.dx - 6, crankPin.dy - 6)
      ..lineTo(crankPin.dx + 6, crankPin.dy + 6)
      ..lineTo(crankCenter.dx + 10, crankCenter.dy + 12)
      ..close();

    canvas.drawPath(cheek, darkMetal);
    canvas.drawPath(cheek, outline);

    canvas.drawCircle(crankPin, 6, crankMetal);
    canvas.drawCircle(crankPin, 6, outline);
  }

  void _drawStatusText(Canvas canvas, Size size) {
    final status = isRunning ? '2D RUNNING' : '2D READY';
    final tp = TextPainter(
      text: TextSpan(
        text: status,
        style: TextStyle(
          color: isRunning ? Colors.greenAccent : Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 8, size.height - tp.height - 6));
  }

  double _intakeLift(double phase) {
    if (phase >= 360 && phase <= 540) {
      return sin(((phase - 360) / 180) * pi).clamp(0, 1);
    }
    return 0;
  }

  double _exhaustLift(double phase) {
    if (phase >= 180 && phase <= 360) {
      return sin(((phase - 180) / 180) * pi).clamp(0, 1);
    }
    return 0;
  }

  Color _gasColor(double phase) {
    // Nổ / cháy: tối hơi đỏ
    if (phase < 180) return const Color(0x554A2B2B);

    // Xả: xám trắng
    if (phase < 360) return const Color(0x66CFD8DC);

    // Nạp: xanh dương
    if (phase < 540) return const Color(0x6638BDF8);

    // Nén: xám tối
    return const Color(0x55323232);
  }


  @override
  bool shouldRepaint(covariant FourCylinderEnginePainter oldDelegate) {
    return oldDelegate.crankAngle != crankAngle ||
        oldDelegate.sparkCylinder != sparkCylinder ||
        oldDelegate.injectorCylinder != injectorCylinder ||
        oldDelegate.isRunning != isRunning;
  }
}
