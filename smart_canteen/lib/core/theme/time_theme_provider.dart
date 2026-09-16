import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimeTheme {
  final Color accent;
  final Color accentLight;
  final LinearGradient gradient;
  final String label;
  const TimeTheme({required this.accent, required this.accentLight, required this.gradient, required this.label});

  static TimeTheme forHour(int hour) {
    if (hour >= 6 && hour < 11) {
      return const TimeTheme(
        accent: Color(0xFFFFB703), accentLight: Color(0xFFFFD166),
        gradient: LinearGradient(colors: [Color(0xFFFFB703), Color(0xFFFF8C00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        label: 'morning');
    } else if (hour >= 11 && hour < 17) {
      return const TimeTheme(
        accent: Color(0xFF00B4D8), accentLight: Color(0xFF90E0EF),
        gradient: LinearGradient(colors: [Color(0xFF00B4D8), Color(0xFF0077B6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        label: 'afternoon');
    } else if (hour >= 17 && hour < 20) {
      return const TimeTheme(
        accent: Color(0xFFB5179E), accentLight: Color(0xFFE040FB),
        gradient: LinearGradient(colors: [Color(0xFFB5179E), Color(0xFF7209B7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        label: 'evening');
    } else {
      return const TimeTheme(
        accent: Color(0xFF6C63FF), accentLight: Color(0xFF9D97FF),
        gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3A0CA3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        label: 'night');
    }
  }
}

final timeThemeProvider = StateNotifierProvider<TimeThemeNotifier, TimeTheme>((ref) => TimeThemeNotifier());

class TimeThemeNotifier extends StateNotifier<TimeTheme> {
  TimeThemeNotifier() : super(TimeTheme.forHour(DateTime.now().hour));
  void refresh() => state = TimeTheme.forHour(DateTime.now().hour);
}
