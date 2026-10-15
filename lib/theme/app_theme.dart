import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const seed = Color(0xFF087A96);
  static const lightPrimary = Color(0xFF086C84);
  static const darkPrimary = Color(0xFF75DEEB);

  /// Bảng màu dùng để phân biệt lớp học phần.
  static const classColors = <Color>[
    Color(0xFF45C5D9),
    Color(0xFF83C3FC),
    Color(0xFF9F98E8),
    Color(0xFFE4BD78),
    Color(0xFF76CDB3),
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
        onPrimary: dark ? const Color(0xFF003541) : Colors.white,
        primaryContainer: dark
            ? const Color(0xFF133E50)
            : const Color(0xFFD5F1F6),
        onPrimaryContainer: dark
            ? const Color(0xFFB4F4FC)
            : const Color(0xFF06485B),
        surface: dark ? const Color(0xFF081722) : const Color(0xFFF0F6F8),
        onSurface: dark ? const Color(0xFFEDF6FC) : const Color(0xFF153247),
        onSurfaceVariant: dark
            ? const Color(0xFFACC1D1)
            : const Color(0xFF577184),
        outlineVariant: dark
            ? const Color(0xFF365060)
            : const Color(0xFFCDDFE7),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,

    // Flutter mới yêu cầu CardThemeData cho ThemeData.cardTheme.
    cardTheme: CardThemeData(
      elevation: dark ? 0 : 1,
      shadowColor: const Color(0xFF16485C).withValues(alpha: .07),
      margin: EdgeInsets.zero,
      color: dark ? const Color(0xFF112A3B) : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
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
      fillColor: dark ? const Color(0xFF102738) : Colors.white,
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
      backgroundColor: dark ? const Color(0xFF102738) : Colors.white,
      indicatorColor: scheme.primaryContainer,
      height: 68,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? const Color(0xFF102738) : Colors.white,
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
