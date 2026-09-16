import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Palette
  static const Color darkBackground = Color(0xFF0D0D10);
  static const Color darkCard = Color(0xFF1E1E24);
  static const Color darkSurface = Color(0xFF151518);
  static const Color darkBorder = Color(0xFF2C2C35);

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF1F2F6);
  static const Color lightBorder = Color(0xFFE2E4EB);

  // Brand / Theme Colors
  static const Color primaryNeon = Color(0xFF00B4D8);
  static const Color secondary = Color(0xFFFFFFFF);
  static const Color accentCyan = Color(0xFF90E0EF);
  
  // Status Colors
  static const Color success = Color(0xFF00F5D4);
  static const Color warning = Color(0xFFFFB703);
  static const Color error = Color(0xFFFF006E);
  static const Color info = Color(0xFF3A86C8);
  
  // Text Colors
  static const Color textDarkPrimary = Color(0xFFF8F9FA);
  static const Color textDarkSecondary = Color(0xFFADB5BD);
  static const Color textLightPrimary = Color(0xFF212529);
  static const Color textLightSecondary = Color(0xFF495057);

  // Gradient Colors
  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGlassGradient = LinearGradient(
    colors: [
      Color(0x1F00B4D8),
      Color(0x0A0077B6),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
