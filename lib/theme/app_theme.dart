import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const seed = Color(0xFF315DC4);
  static const lightPrimary = Color(0xFF315DC4);
  static const darkPrimary = Color(0xFFB9CEFF);

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

  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.seed,
        brightness: brightness,
      ).copyWith(
        primary: dark ? AppColors.darkPrimary : AppColors.lightPrimary,
        onPrimary: dark ? const Color(0xFF1A2C60) : Colors.white,
        surface: dark ? const Color(0xFF111722) : const Color(0xFFF5F7FB),
        onSurface: dark ? const Color(0xFFE8EDF6) : const Color(0xFF18273F),
        onSurfaceVariant: dark
            ? const Color(0xFFADBBD0)
            : const Color(0xFF5A6A80),
        outlineVariant: dark
            ? const Color(0xFF425168)
            : const Color(0xFFD6DFEC),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,

    // Flutter mới yêu cầu CardThemeData cho ThemeData.cardTheme.
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: dark ? const Color(0xFF1B2535) : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .45)),
      ),
    ),

    appBarTheme: AppBarTheme(
      centerTitle: false,
      titleSpacing: 20,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF1B2535) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF151E2C) : Colors.white,
      indicatorColor: scheme.primaryContainer,
      height: 76,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? const Color(0xFF182232) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .6)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
