import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'motion.dart';

/// Primary CTA: gradient clay button with loading → success morph.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool success;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.loading = false,
    this.success = false,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading && !success;
    Widget content;
    if (success) {
      content = const Icon(
        Icons.check_rounded,
        key: ValueKey('ok'),
        color: Colors.white,
        size: 28,
      );
    } else if (loading) {
      content = const SizedBox(
        key: ValueKey('loading'),
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    } else {
      content = Row(
        key: const ValueKey('label'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Pressable3D(
      onTap: enabled ? onPressed : null,
      maxTilt: 0.08,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppMotion.normal,
        height: height,
        decoration: BoxDecoration(
          gradient: success
              ? const LinearGradient(
                  colors: [Color(0xFF34D399), AppColors.success],
                )
              : AppColors.gradient,
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: [
            BoxShadow(
              color: (success ? AppColors.success : AppColors.primary)
                  .withValues(alpha: 0.35),
              offset: const Offset(0, 10),
              blurRadius: 22,
              spreadRadius: -6,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: AppMotion.normal,
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Round 48×48 clay icon button (meets touch-target size).
class ClayIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String tooltip;
  final double size;

  const ClayIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color = AppColors.primary,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Pressable3D(
        onTap: onTap,
        pressedScale: 0.88,
        semanticLabel: tooltip,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(size / 2.6),
          ),
          child: Icon(icon, color: color, size: size * 0.46),
        ),
      ),
    );
  }
}

/// Small rounded label (category, status). Always pairs color with text/icon.
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Pill({
    super.key,
    required this.text,
    this.color = AppColors.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating toast with icon (success / error).
void showToast(BuildContext context, String message, {bool error = false}) {
  if (!error) HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: error ? const Color(0xFFFDA4AF) : const Color(0xFF6EE7B7),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/// Confirm-delete dialog that flips in with 3D perspective.
Future<bool> confirmDelete(BuildContext context, String name) async {
  HapticFeedback.mediumImpact();
  final res = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cancel',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: AppMotion.normal,
    pageBuilder: (ctx, _, _) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: clayBox(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.danger,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete product?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"$name" will be removed from your product list.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.field,
                          foregroundColor: AppColors.text,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final t = Curves.easeOutBack.transform(anim.value);
      return Opacity(
        opacity: anim.value,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateX((1 - t) * 0.8),
          child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
        ),
      );
    },
  );
  return res ?? false;
}
