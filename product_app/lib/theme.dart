import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pocket Mart — modern shopping-app look: light grey canvas, white rounded
/// cards with soft shadows, warm coral accent, navy text.
class Mart {
  static const canvas = Color(0xFFF6F6F9);
  static const card = Colors.white;
  static const navy = Color(0xFF1E2340);
  static const grey = Color(0xFF8A8FA3);
  static const greyLight = Color(0xFFEDEEF3);
  static const coral = Color(0xFFFF6B3D);
  static const coralDeep = Color(0xFFE5532A);
  static const coralTint = Color(0xFFFFF0EA);
  static const peach = Color(0xFFFFE1D3);
  static const mint = Color(0xFF12B886);
  static const amber = Color(0xFFE8A100);
  static const red = Color(0xFFE03131);

  static const coralGradient = LinearGradient(
    colors: [Color(0xFFFF8A5B), coral, coralDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> shadow([double strength = 1]) => [
    BoxShadow(
      color: navy.withValues(alpha: 0.06 * strength),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  /// Icon per category name (falls back to a generic tag)
  static IconData categoryIcon(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('drink') || n.contains('water') || n.contains('juice'))
      return Icons.local_drink_rounded;
    if (n.contains('snack') || n.contains('chip') || n.contains('cookie'))
      return Icons.cookie_rounded;
    if (n.contains('fruit')) return Icons.apple_rounded;
    if (n.contains('milk') || n.contains('dairy')) return Icons.egg_alt_rounded;
    return Icons.sell_rounded;
  }

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}

ThemeData buildTheme() {
  final r = BorderRadius.circular(16);
  OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
    borderRadius: r,
    borderSide: BorderSide(color: c, width: w),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Mart.coral,
      primary: Mart.coral,
      onPrimary: Colors.white,
      surface: Mart.card,
      error: Mart.red,
    ),
    scaffoldBackgroundColor: Mart.canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Mart.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Mart.navy,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Mart.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: b(Mart.greyLight, 1.2),
      enabledBorder: b(Mart.greyLight, 1.2),
      focusedBorder: b(Mart.coral, 1.6),
      errorBorder: b(Mart.red, 1.2),
      focusedErrorBorder: b(Mart.red, 1.6),
      labelStyle: const TextStyle(color: Mart.grey),
      hintStyle: const TextStyle(color: Mart.grey),
      prefixIconColor: Mart.grey,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Mart.navy,
      shape: RoundedRectangleBorder(borderRadius: r),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Mart.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
