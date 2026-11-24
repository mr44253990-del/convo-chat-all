import 'package:flutter/material.dart';

/// Dart port of com.example.ui.theme.Color.kt (Convo Chat Aurora palette).
class Aurora {
  static const violet = Color(0xFF7C5CFC);
  static const blue = Color(0xFF3D8BFF);
  static const cyan = Color(0xFF35D6C7);
  static const pink = Color(0xFFFF6FAE);
  static const amber = Color(0xFFFFC857);
  static const success = Color(0xFF45D483);

  static const ink950 = Color(0xFF06070B);
  static const ink900 = Color(0xFF0C0E15);
  static const ink800 = Color(0xFF171A24);
  static const mist50 = Color(0xFFF8F9FF);
  static const mist100 = Color(0xFFF0F2FA);
  static const mist700 = Color(0xFF555C70);
}

ThemeData buildConvoTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Aurora.violet,
      onPrimary: Colors.white,
      secondary: Aurora.cyan,
      onSecondary: Colors.black,
      tertiary: Aurora.pink,
      surface: Aurora.ink900,
      onSurface: Aurora.mist50,
      error: Color(0xFFFF5C5C),
    ),
    scaffoldBackgroundColor: Aurora.ink950,
    fontFamily: 'Roboto',
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Aurora.mist50,
      displayColor: Aurora.mist50,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Aurora.ink800,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Aurora.violet.withOpacity(.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Aurora.violet),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Aurora.violet,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
