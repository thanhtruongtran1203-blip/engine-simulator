import 'package:flutter/material.dart';
import 'data.dart';
import 'engine_screen.dart';

class SimulatorScreen extends StatelessWidget {
  final EngineConfig engine;

  const SimulatorScreen({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {

    // 🔥 NẾU LÀ K15B → MỞ SIMULATOR THẬT
    if (engine.name == "K15B") {
      return const EngineScreen();
    }

    // 👉 CÒN LẠI GIỮ UI CŨ
    return Scaffold(
      appBar: AppBar(
        title: Text("Simulator - ${engine.name}"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              engine.name,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 10),
            Text(engine.type),

            const SizedBox(height: 30),

            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text("ENGINE SIMULATOR"),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 THÔNG BÁO CHƯA HỖ TRỢ
            const Text(
              "Chưa hỗ trợ simulator cho engine này",
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}