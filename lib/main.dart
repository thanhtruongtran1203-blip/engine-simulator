import 'package:flutter/material.dart';
import 'brand_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Engine Simulator',
      theme: ThemeData.dark(),
      home: const BrandScreen(),
    );
  }
}