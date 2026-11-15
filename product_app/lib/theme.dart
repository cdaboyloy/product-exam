import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens — soft, airy, translucent pastel (light theme)
class AppColors {
  static const bg = Color(0xFFF8F7FF); // airy lavender-white
  static const surface = Colors.white;
  static const glass = Color(0xD9FFFFFF); // white @ 85% — translucent cards
  static const glassBorder = Color(0xB3FFFFFF);
  static const field = Color(0xFFF4F2FE);
  static const text = Color(0xFF2B2840);
  static const muted = Color(0xFF6E6A85);
  static const primary = Color(0xFF6C5CE7); // text/icons (AA on white)
  static const primaryLight = Color(0xFFB3A6FF);
  static const primarySoft = Color(0xFFF0EDFF);
  static const accent = Color(0xFFF9A8D4);
  static const sky = Color(0xFFA5D8FF);
  static const mint = Color(0xFFB2F2DE);
  static const success = Color(0xFF0F9F6E);
  static const warning = Color(0xFFC77700);
  static const danger = Color(0xFFE5486B);

  /// Buttons: soft periwinkle → violet (white bold text ≥ 3:1, large)
  static const gradient = LinearGradient(
    colors: [Color(0xFFA899FF), Color(0xFF7A6AF2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Header: bright pastel wash (dark text on top)
  static const headerGradient = LinearGradient(
    colors: [Color(0xFFE4DDFF), Color(0xFFDCEBFF), Color(0xFFFDE4F2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppRadius {
  static const card = 28.0;
  static const button = 20.0;
  static const field = 16.0;
}

class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 450);
  static const springOut = Curves.easeOutBack;

  /// Respect the OS "reduce motion" / "remove animations" setting
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}

/// Multi-layer clay shadow: soft tinted drop shadow + white top-left highlight
List<BoxShadow> clayShadow({
  Color tint = AppColors.primary,
  double depth = 1,
}) => [
  BoxShadow(
    color: tint.withValues(alpha: 0.10 * depth),
    offset: Offset(0, 12 * depth),
    blurRadius: 32 * depth,
    spreadRadius: -10,
  ),
  BoxShadow(
    color: tint.withValues(alpha: 0.04),
    offset: const Offset(0, 2),
    blurRadius: 6,
  ),
  const BoxShadow(
    color: Colors.white,
    offset: Offset(-3, -3),
    blurRadius: 8,
    spreadRadius: -2,
  ),
];

/// Translucent "glass-clay" card: 85% white, bright rim, soft tinted shadow
BoxDecoration clayBox({
  Color color = AppColors.glass,
  double radius = AppRadius.card,
}) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: AppColors.glassBorder, width: 1.5),
  boxShadow: clayShadow(),
);

/// Soft pastel page background with color washes (sits behind translucent cards)
class SoftBackground extends StatelessWidget {
  final Widget child;
  const SoftBackground({super.key, required this.child});

  Widget _wash(Color c, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.bg)),
        Positioned(
          top: 220,
          left: -120,
          child: _wash(AppColors.sky.withValues(alpha: 0.35), 340),
        ),
        Positioned(
          bottom: 60,
          right: -140,
          child: _wash(AppColors.accent.withValues(alpha: 0.28), 360),
        ),
        Positioned(
          bottom: -120,
          left: 40,
          child: _wash(AppColors.mint.withValues(alpha: 0.30), 300),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    error: AppColors.danger,
    surface: AppColors.surface,
  );
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.field),
    borderSide: BorderSide.none,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.text,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      bodyMedium: TextStyle(color: AppColors.text, height: 1.45),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: AppColors.muted),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.text,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
