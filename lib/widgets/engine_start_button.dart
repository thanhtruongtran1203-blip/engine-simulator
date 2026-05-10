import 'package:flutter/material.dart';

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
            widget.isRunning ? 'STOP' : 'START',
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
