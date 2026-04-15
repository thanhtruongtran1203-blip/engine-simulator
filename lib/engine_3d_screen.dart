import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Engine3DScreen extends StatelessWidget {
  const Engine3DScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("3D Engine"),
        backgroundColor: Colors.black,
      ),
      body: const ModelViewer(
        src: 'assets/models/engine3.glb',
        autoRotate: true,
        cameraControls: true,
      ),
    );
  }
}