import 'package:flutter/material.dart';

import 'splash_screen.dart';

void main() {
  runApp(const EngineApp());
}

class EngineApp extends StatelessWidget {
  const EngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'K15B Engine Simulator',

      theme: ThemeData.dark().copyWith(
        useMaterial3: false,
      ),

      home: const SplashScreen(),
    );
  }
}