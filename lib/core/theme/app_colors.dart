import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F0F13);
  static const Color surface = Color(0xFF1E1E2E);
  static const Color surfaceTransparent = Color(0x991C1C23);

  static const Color primary = Color(0xFF8A5BFF); // Electric Purple
  static const Color secondary = Color(0xFF42ACFF); // Vibrant Blue

  static const Color accentBlue = Color(0xFF0A84FF);
  static const Color accentPink = Color(0xFFFF5BA1);
  static const Color accentGreen = Color(0xFF32D74B);

  static const Color backgroundStart = Color(0xFF0F0C29);
  static const Color backgroundMid = Color(0xFF302B63);
  static const Color backgroundEnd = Color(0xFF24243E);

  static const Color cardBg = Color(0x33FFFFFF);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);

  static const List<Color> meshGradient = [
    Color(0xFF1C1C23),
    Color(0xFF0F0F13),
    Color(0xFF121217),
  ];

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x33FFFFFF), Color(0x11FFFFFF)],
  );
}
