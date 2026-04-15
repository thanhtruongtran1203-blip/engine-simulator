import 'package:flutter/material.dart';
import 'models.dart';
import 'data.dart';
import 'simulator_screen.dart';

class EngineListScreen extends StatelessWidget {
  final Brand brand;

  const EngineListScreen({super.key, required this.brand});

  @override
  Widget build(BuildContext context) {

    // 🔥 FIX Ở ĐÂY
    final brandEngines = engineData[brand.name]!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("${brand.name} Engines")),
      body: ListView.builder(
        itemCount: brandEngines.length,
        itemBuilder: (context, index) {
          final engine = brandEngines[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(engine.name),
              subtitle: Text(engine.type),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SimulatorScreen(engine: engine),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}