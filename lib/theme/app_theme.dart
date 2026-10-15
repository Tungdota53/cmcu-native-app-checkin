
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const seed = Color(0xFF223771);
  static const lightPrimary = Color(0xFF223771);
  static const darkPrimary = Color(0xFFB4C5FF);

  /// Bảng màu dùng để phân biệt lớp học phần.
  static const classColors = <Color>[
    Color(0xFF223771),
    Color(0xFFD49F3A),
    Color(0xFFEC4C00),
    Color(0xFF5A7ADB),
    Color(0xFF3C5398),
  ];

  /// Tương thích với thuật toán hash của Java String,
  /// sử dụng UTF-16 và phép tính Int32.
  static Color forClass(String classSectionId) {
    var hash = 0;

    for (final unit in classSectionId.codeUnits) {
      hash = (31 * hash + unit) & 0xFFFFFFFF;
    }

    if (hash >= 0x80000000) {
      hash -= 0x100000000;
    }

    final n = classColors.length;
    return classColors[((hash % n) + n) % n];
  }
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: brightness,
  ).copyWith(
    primary: dark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary,
    onPrimary: dark
        ? const Color(0xFF1A2C60)
        : Colors.white,
    surface: dark
        ? const Color(0xFF1B1C22)
        : const Color(0xFFF7F8FF),
    onSurface: dark
        ? const Color(0xFFE4E1E9)
        : const Color(0xFF1B1B21),
    onSurfaceVariant: dark
        ? const Color(0xFFC6C5D0)
        : const Color(0xFF46464F),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,

    // Flutter mới yêu cầu CardThemeData cho ThemeData.cardTheme.
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
