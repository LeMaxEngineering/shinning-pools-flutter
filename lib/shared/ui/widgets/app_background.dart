import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final bool showGradient; // Kept for compatibility, but not used

  const AppBackground({
    super.key,
    required this.child,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/img/splash01.png',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: const Color.fromRGBO(255, 255, 255, 0.80),
          ),
        ),
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
} 