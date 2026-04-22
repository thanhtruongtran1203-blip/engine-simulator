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
        double fakeRPM = 1000;
        double crankAngle = 0;
        int spark = 0;
        int injector = 0;
        bool useSTM32 = false;
        bool isRunning = false;
        double simScale = 0.2;
        double prevAngle = 0;
    
        Timer? engineLoop;
        String buffer = "";
    
        void onDataReceived(String chunk) {
          buffer += chunk;
  
          while (buffer.contains('<') && buffer.contains('>')) {
            int start = buffer.indexOf('<');
            int end = buffer.indexOf('>', start);
  
            if (start != -1 && end != -1 && end > start) {
              String frame = buffer.substring(start, end + 1);
              buffer = buffer.substring(end + 1);
  
              parseFrame(frame);
            } else {
              break;
            }
          }
        }
        int injectorPulseId = 0;
        final Map<int, int> sparkPulseIds = {1: 0, 2: 0, 3: 0, 4: 0};
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
    
        late AnimationController electricController;
    
        double get currentRpm {
          final value = useSTM32 ? rpm : fakeRPM;
          return value.clamp(500, 6000);
        }
    
        double get eventIntervalMs => 120000 / currentRpm;
    
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
    
        @override
        void initState() {
          super.initState();
    
          electricController = AnimationController(
            vsync: this,
            duration: const Duration(seconds: 2),
          );
    
          engineLoop = Timer.periodic(const Duration(milliseconds: 16), (_) {
            if (!isRunning || useSTM32) return;
    
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
    
            setState(() {});
          });
        }
    
        void startEngine() {
          setState(() {
            isRunning = true;
            crankAngle = 0;
            prevAngle = 719.9;
            injector = 0;
            spark = 0;
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
    
        @override
        void dispose() {
          engineLoop?.cancel();
          electricController.dispose();
          super.dispose();
        }
  
        void parseFrame(String data) {
          if (!useSTM32) return;
  
          final reg = RegExp(r'<(\d+),(\d+),(\d+),(\d+)>');
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
        }
    
        void triggerInjector(int cyl) {
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
  
        int sparkPulseId = 0;
  
        void triggerSpark(int cyl) {
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
          if (useSTM32) return;
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
                    child: Engine2DPreview(
                      crankAngle: crankAngle,
                      activeSparkCylinders: activeSparkCylinders,
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
                  top: 100,
                  left: 0,
                  right: 650,
                  child: Center(
                    child: Text(
                      "Hệ thống phun xăng điện tử",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                  top: 153,
                  left: 0,
                  right: 485,
                  child: Center(
                    child: Text(
                      "Bộ điều áp\nnhiên liệu",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// Ống chân không từ phía sau cổ hút
                const Positioned(
                  top: 190,
                  left: 0,
                  right: 350,
                  child: Center(
                    child: Text(
                      "Ống chân không từ\n  phía sau cổ hút",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// Fuel rail
                const Positioned(
                  top: 225,
                  left: 65,
                  right: 130,
                  child: Center(
                    child: Text(
                      "Ống phân \n phối nhiên liệu",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// Injectors
                const Positioned(
                  top: 265,
                  left: 0,
                  right: 130,
                  child: Center(
                    child: Text(
                      "Kim phun",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// Fuel filter
                const Positioned(
                  top: 290,
                  left: 35,
                  right: 830,
                  child: Center(
                    child: Text(
                      "Lọc\nxăng",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// Evaporative emissions canister
                const Positioned(
                  top: 290,
                  left: 0,
                  right: 1200,
                  child: Center(
                    child: Text(
                      "Bình than\nhoạt tính",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// Fuel tank
                const Positioned(
                  top: 388,
                  left: 0,
                  right: 1067,
                  child: Center(
                    child: Text(
                      "Bình nhiên liệu",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// ECU
                const Positioned(
                  top: 410,
                  left: 0,
                  right: 770,
                  child: Center(
                    child: Text(
                      "ECU",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// Electric fuel pump
                const Positioned(
                  top: 460,
                  left: 0,
                  right: 880,
                  child: Center(
                    child: Text(
                      "Bơm xăng điện",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// High pressure fuel line
                const Positioned(
                  top: 578,
                  left: 0,
                  right: 860,
                  child: Center(
                    child: Text(
                      "Đường nhiên liệu áp suất cao",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// Fuel return line
                const Positioned(
                  top: 598,
                  left: 0,
                  right: 905,
                  child: Center(
                    child: Text(
                      "Đường hồi nhiên liệu",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// A
                const Positioned(
                  top: 485,
                  left: 5,
                  right: 605,
                  child: Center(
                    child: Text(
                      "A",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// B
                const Positioned(
                  top: 485,
                  left: 5,
                  right: 510,
                  child: Center(
                    child: Text(
                      "B",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// C
                const Positioned(
                  top: 485,
                  left: 5,
                  right: 410,
                  child: Center(
                    child: Text(
                      "C",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// D
                const Positioned(
                  top: 485,
                  left: 5,
                  right: 300,
                  child: Center(
                    child: Text(
                      "D",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// E
                const Positioned(
                  top: 485,
                  left: 5,
                  right: 215,
                  child: Center(
                    child: Text(
                      "E",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// F
                const Positioned(
                  top: 485,
                  left: 5,
                  right: 135,
                  child: Center(
                    child: Text(
                      "F",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// G
                const Positioned(
                  top: 485,
                  left: 5,
                  right: 55,
                  child: Center(
                    child: Text(
                      "G",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                /// NOTE
                const Positioned(
                  top: 530,
                  left: 0,
                  right: 390,
                  child: Center(
                    child: Text(
                      "A. Cảm biến vị trí/tốc độ trục khuỷu\nB. Cảm biến vị trí trục cam\nC. Cảm biến bàn đạp ga/phanh/tốc độ xe\nD. Cảm biến nhiệt độ khí nạp tăng áp\nE. Cảm biến nhiệt độ khí nạp\nF. Cảm biến nhiệt độ nước làm mát\nG. Cảm biến nhiệt độ dầu",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
      
                /// RPM (trái)
                Positioned(
                  left: 855,
                  bottom: 100,
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: _buildRPMGauge(displayRPM),
                  ),
                ),
      
                /// SPEED (giữa)
                Positioned(
                  left: 905,
                  bottom: 100,
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: _buildSpeedGauge(displayRPM / 40),
                  ),
                ),
      
                /// FUEL (phải)
                Positioned(
                  right: 245,   // căn theo mép phải (chuẩn hơn left)
                  bottom: 110,   // chỉnh cao xuống 1 chút
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
                  bottom: 110,
                  right: 150,
                  child: EngineStartButton(
                    isRunning: isRunning,
                    onStart: startEngine,
                    onStop: stopEngine,
                  ),
                ),
                /// SMT32MODE/FAKEMODE
                Positioned(
                  bottom: 100,
                  left: 750,
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
                  left: 0,
                  bottom: 100,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5, // 👈 50% màn hình
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              left: 285,
                              bottom: 386,
                              child: CustomPaint(
                                size: const Size(100, 153),
                                painter: ElectricPathPainterCustom(
                                    electricController.value),
                              ),
                            ),
      
                            /// FUEL
                            Positioned(
                              left: 192,
                              bottom: 396,
                              child: CustomPaint(
                                size: const Size(10,137),
                                painter: ElectricPathPainterCustom1(
                                  electricController.value,
                                  useSTM32 ? rpm : fakeRPM,
                                ),
                              ),
                            ),
      
                            /// FUEL RETURN
                            Positioned(
                              left: 162,
                              bottom: 389,
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
                              left: 235,
                              bottom: 262,
                              child: CustomPaint(
                                size: const Size(79, 95),
                                painter: ElectricPathPainter1(
                                    electricController.value),
                              ),
                            ),
      
                            /// WIRE KHUYU
                            Positioned(
                              left: 315,
                              bottom: 340,
                              child: CustomPaint(
                                size: const Size(100, 55),
                                painter: ElectricPathPainter2(
                                    electricController.value),
                              ),
                            ),
      
                            /// WIRE CAM
                            Positioned(
                              left: 362,
                              bottom: 340,
                              child: CustomPaint(
                                size: const Size(100, 55),
                                painter: ElectricPathPainter2(
                                    electricController.value),
                              ),
                            ),
      
                            /// WIRE BRAKE
                            Positioned(
                              left: 396,
                              bottom: 345,
                              child: CustomPaint(
                                size: const Size(100, 50),
                                painter: ElectricPathPainter2(
                                    electricController.value),
                              ),
                            ),
      
                            /// WIRE TEMP
                            Positioned(
                              left: 458,
                              bottom: 346,
                              child: CustomPaint(
                                size: const Size(100, 50),
                                painter: ElectricPathPainter2(
                                    electricController.value),
                              ),
                            ),
      
                            /// WIRE TEMP AIR
                            Positioned(
                              left: 485,
                              bottom: 366,
                              child: CustomPaint(
                                size: const Size(100, 30),
                                painter: ElectricPathPainter3(
                                    electricController.value),
                              ),
                            ),
      
                            /// WIRE TEMP COOLANT
                            Positioned(
                              left: 525,
                              bottom: 366,
                              child: CustomPaint(
                                size: const Size(100, 30),
                                painter: ElectricPathPainter3(
                                    electricController.value),
                              ),
                            ),
      
                            /// WIRE TEMP OIL
                            Positioned(
                              left: 566,
                              bottom: 366,
                              child: CustomPaint(
                                size: const Size(100, 30),
                                painter: ElectricPathPainter3(
                                    electricController.value),
                              ),
                            ),
      
                            /// WIRE MAIN
                            Positioned(
                              left: 317,
                              bottom: 338,
                              child: CustomPaint(
                                size: const Size(309, 100),
                                painter: ElectricPathPainter4(
                                    electricController.value),
                              ),
                            ),
      
                            /// INJECTOR 1
                            Positioned(
                              left: 360,
                              bottom: 460,
                              child: CustomPaint(
                                size: const Size(30, 40),
                                painter: StaticInjectorPainter(isActive: injector == 1),
                              ),
                            ),
      
                            /// INJECTOR 3
                            Positioned(
                              left: 463,
                              bottom: 460,
                              child: CustomPaint(
                                size: const Size(30, 40),
                                painter: StaticInjectorPainter(isActive: injector == 3),
                              ),
                            ),
      
                            /// INJECTOR 4
                            Positioned(
                              left: 515,
                              bottom: 460,
                              child: CustomPaint(
                                size: const Size(30, 40),
                                painter: StaticInjectorPainter(isActive: injector == 4),
                              ),
                            ),
      
                            /// INJECTOR 2
                            Positioned(
                              left: 410,
                              bottom: 460,
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
      
          double horizontalTop = 172;
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
      
          double horizontalTop = 130;
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
      
          double startX = 220;
          double startY = -63;
      
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
                Colors.blueAccent.withOpacity(1),
                Colors.blueAccent.withOpacity(0.5),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromLTWH(0, 0, size.width, size.height),
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      
          Path cone = Path();
          cone.moveTo(centerX, 0);
          cone.lineTo(centerX - size.width * 0.3, size.height * 0.6);
          cone.lineTo(centerX + size.width * 0.6, size.height * 0.6);
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
        final Set<int> activeSparkCylinders;
        final int injectorCylinder;
        final bool isRunning;
      
        const Engine2DPreview({
          super.key,
          required this.crankAngle,
          required this.activeSparkCylinders,
          required this.injectorCylinder,
          required this.isRunning,
        });
      
        @override
        Widget build(BuildContext context) {
          return Center(
            child: CustomPaint(
              size: const Size(360, 230),
              painter: FourCylinderEnginePainter(
                crankAngle: crankAngle,
                activeSparkCylinders: activeSparkCylinders,
                injectorCylinder: injectorCylinder,
                isRunning: isRunning,
              ),
            ),
          );
        }
      }
    
      class FourCylinderEnginePainter extends CustomPainter {
        final double crankAngle;
        final Set<int> activeSparkCylinders;
        final int injectorCylinder;
        final bool isRunning;
        double get flowOffset =>
            (DateTime.now().millisecondsSinceEpoch % 1000) / 1000;

        FourCylinderEnginePainter({
          required this.crankAngle,
          required this.activeSparkCylinders,
          required this.injectorCylinder,
          required this.isRunning,
        });
    
        @override
        void paint(Canvas canvas, Size size) {
          canvas.drawRect(
            Offset.zero & size,
            Paint()..color = Colors.black,
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
              sparkOn: activeSparkCylinders.contains(cylinder),
              injectorOn: injectorCylinder == cylinder,
              outline: outline,
              metal: whiteMetal,
              blueWall: blueWall,
              darkMetal: darkMetal,
              crankMetal: crankMetal,
            );
          }
    
          _drawStatusText(canvas, size);
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
              Color(0xFFFFEB3B), // vàng sáng
              Color(0xFFFF9800), // cam
              Color(0xFFF44336), // đỏ
              Color(0xCCB71C1C), // đỏ đậm (tăng độ sâu)
            ];
          }

          if (phase >= 180 && phase < 360) {
            // 💨 EXHAUST (khí xả)
            return const [
              Color(0xFF616161), // xám sáng hơn
              Color(0xFF424242),
              Color(0xFF212121),
              Color(0xCC000000), // đậm hơn (khói rõ hơn)
            ];
          }

          if (phase >= 360 && phase < 540) {
            // 🌬 INTAKE (khí nạp)
            return const [
              Color(0xFF38BDF8), // xanh sáng (rất rõ)
              Color(0xFF0EA5E9), // xanh đậm hơn
              Color(0xCC0284C7), // xanh sâu
              Color(0x880284C7), // fade nhẹ
            ];
          }

          return const [
            Color(0x66B0BEC5),
            Color(0x668D99AE),
            Color(0x55737474),
            Color(0x33737474),
          ];
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
          final intakeX = centerX - 14;
          final exhaustX = centerX + 14;
    
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
            ..color = const Color(0xFF2893FF)
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
            ..moveTo(intakeX - 6, intakeSeatY)
            ..quadraticBezierTo(intakeX, intakeSeatY + 5, intakeX + 6, intakeSeatY)
            ..close();
    
          final exhaustValve = Path()
            ..moveTo(exhaustX - 6, exhaustSeatY)
            ..quadraticBezierTo(exhaustX, exhaustSeatY + 5, exhaustX + 6, exhaustSeatY)
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
            double speed = 0.5 + (phase / 720) * 1.5;

            return Paint()
              ..shader = LinearGradient(
                begin: Alignment(-1 + flowOffset * speed, 0),
                end: Alignment(1 + flowOffset * speed, 0),
                colors: flowColors,
                stops: [0.0, 0.15, 0.5, 1.0]
              ).createShader(rect)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          }
    
          const manifoldY = 64.0;
          const flowThickness = 10.0;
          const chamberTipY = 80.0;
          const chamberBottomY = 88.0;

          if (phase >= 360 && phase < 540 && intakeOpen > 0.01) {
            final neckY = manifoldY + 3 + intakeOpen * 2.0;

            final intakeFlow = Path()
              ..moveTo(centerX - 40, manifoldY)
              ..quadraticBezierTo(centerX - 30, manifoldY - 2, centerX - 20, manifoldY)
              ..lineTo(centerX - 10, manifoldY)

              ..quadraticBezierTo(centerX - 18, manifoldY, intakeX - 5, manifoldY + 1)
              ..quadraticBezierTo(centerX - 8, manifoldY + 2, centerX - 5, neckY)

              ..quadraticBezierTo(centerX - 4, manifoldY + 12, centerX - 1, manifoldY + 16)
              ..quadraticBezierTo(centerX + 2, manifoldY + 22, centerX + 6, manifoldY + 28)
              ..quadraticBezierTo(centerX + 6, chamberBottomY - 6, centerX + 2, chamberBottomY)
              ..quadraticBezierTo(centerX - 2, chamberBottomY + 2, centerX - 8, chamberBottomY - 2)
              ..quadraticBezierTo(centerX, chamberBottomY + 1, centerX - 7, chamberTipY)

              ..quadraticBezierTo(
                centerX - 8,
                manifoldY + flowThickness,
                intakeX - 6,
                manifoldY + flowThickness,
              )

              ..quadraticBezierTo(
                centerX - 18,
                manifoldY + flowThickness,
                centerX - 10,
                manifoldY + flowThickness,
              )

              ..lineTo(centerX - 20, manifoldY + flowThickness)
              ..close();

            canvas.drawPath(
              intakeFlow,
              buildFlowPaint(Rect.fromLTWH(centerX - 64, manifoldY - 2, 68, 22)),
            );
            drawFlowParticles(
              canvas,
              Rect.fromLTWH(centerX - 40, manifoldY - 5, 68, 22),
              phase: phase,
            );
          }

          if (phase >= 540 && phase < 720) {

            double t = (phase - 540) / 180;

            double compress = 1 - t * 0.4;
            double w = 22 * compress;

            final chamberFlow = Path()
              ..moveTo(centerX - w, 86)
              ..quadraticBezierTo(centerX + wobble - 10, 78, centerX+ wobble , 80)
              ..quadraticBezierTo(centerX + wobble + 10, 78, centerX + wobble + w, 86)
              ..quadraticBezierTo(centerX + wobble + w * 0.6, 96, centerX+ wobble , 100)
              ..quadraticBezierTo(centerX + wobble - w * 0.6, 96, centerX + wobble - w, 86)
              ..close();

            final rect = Rect.fromLTWH(centerX + wobble - 22, 78, 44, 26);

            canvas.drawPath(
              chamberFlow,
              Paint()
                ..shader = RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: flowColors,
                ).createShader(rect)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
            );

            drawFlowParticles(canvas, rect, phase: phase);
          }

          if (phase >= 0 && phase < 180) {

            double t = phase / 180;

            final burnFlow = Path()
              ..moveTo(centerX, 78)
              ..quadraticBezierTo(centerX + wobble + 14, 82, centerX + wobble + 10, 92)
              ..quadraticBezierTo(centerX + wobble + 4, 100, centerX + wobble , 96)
              ..quadraticBezierTo(centerX + wobble - 4, 100, centerX + wobble - 10, 92)
              ..quadraticBezierTo(centerX + wobble - 14, 82, centerX + wobble , 78)
              ..close();

            final rect = Rect.fromLTWH(centerX - 18, 76, 36, 24);

            canvas.drawPath(
              burnFlow,
              Paint()
                ..shader = RadialGradient(
                  colors: flowColors,
                ).createShader(rect)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
            );

            drawFlowParticles(canvas, rect, phase: phase);
          }

          if (phase >= 180 && phase < 360 && exhaustOpen > 0.01) {
            final neckY = manifoldY + 3 + exhaustOpen * 2.0;

            final exhaustFlow = Path()
              ..moveTo(centerX - 2, chamberBottomY)
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
          for (int i = 0; i < 25; i++) {
            double t = (i / 25 + flowOffset) % 1;

            double x, y;

            // 🔵 INTAKE (360–540)
            if (phase >= 360 && phase < 540) {
              x = bounds.left + bounds.width * t;
              y = bounds.top + bounds.height * (0.6 - 0.3 * sin(t * pi));
            }

            // 💨 EXHAUST (180–360)
            else if (phase >= 180 && phase < 360) {
              x = bounds.right - bounds.width * t;
              y = bounds.top + bounds.height * (0.4 + 0.3 * sin(t * pi));
            }

            // 🔥 COMBUSTION (0–180)
            else if (phase >= 0 && phase < 180) {
              x = bounds.center.dx + (t - 0.5) * bounds.width;
              y = bounds.center.dy + (t - 0.5) * bounds.height;
            }

            // 🧊 COMPRESSION (540–720)
            else {
              x = bounds.left + bounds.width * t;
              y = bounds.center.dy + (0.5 - t) * bounds.height * 0.5;
            }
          }
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
          const cylinderTop = 74.0;
          const cylinderBottom = 150.0;
          const crankY = 190.0;
          const crankRadius = 20.0;
          const rodLength = 35.0;
          const pistonWidth = 42.0;
          const pistonHeight = 45.0;
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
    
          final pistonPin = Offset(centerX, pistonRect.center.dy);
    
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
            phase: phase,
            blueWall: blueWall,
            outline: outline,
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
              oldDelegate.isRunning != isRunning;
        }
      }
    
