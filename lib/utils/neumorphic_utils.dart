import 'package:flutter/material.dart';

class NeumorphicUtils {
  static List<BoxShadow> boxShadow({
    Color? backgroundColor,
    double intensity = 1.0,
    Offset? distance,
  }) {
    final Color baseColor = backgroundColor ?? const Color(0xFFE0E5EC);
    final offset = distance ?? const Offset(5, 5);
    
    return [
      BoxShadow(
        color: Color.fromARGB(
          (20 * intensity).round(),
          0,
          0,
          0,
        ),
        offset: offset,
        blurRadius: 15,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.8 * intensity),
        offset: -offset,
        blurRadius: 15,
        spreadRadius: 1,
      ),
    ];
  }

  static List<BoxShadow> pressedShadow({
    Color? backgroundColor,
    double intensity = 1.0,
  }) {
    return [
      BoxShadow(
        color: Colors.white.withOpacity(0.5 * intensity),
        offset: const Offset(-2, -2),
        blurRadius: 5,
      ),
      BoxShadow(
        color: const Color(0xFF000000).withOpacity(0.1 * intensity),
        offset: const Offset(2, 2),
        blurRadius: 5,
      ),
    ];
  }

  static Gradient pressedGradient({
    Color? backgroundColor,
    double intensity = 1.0,
  }) {
    final Color baseColor = backgroundColor ?? const Color(0xFFE0E5EC);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(0.5),
        baseColor,
      ],
    );
  }
}
