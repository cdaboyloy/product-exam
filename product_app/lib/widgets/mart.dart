import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Rises from below with a slight scale-up, staggered by index.
class RiseIn extends StatefulWidget {
  final Widget child;
  final int index;
  const RiseIn({super.key, required this.child, this.index = 0});

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Mart.reduceMotion(context)) {
      _c.value = 1;
      return;
    }
    Future.delayed(Duration(milliseconds: 60 * math.min(widget.index, 8)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) {
      final t = Curves.easeOutCubic.transform(_c.value);
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 28 * (1 - t)),
          child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
        ),
      );
    },
  );
}

/// Shrinks a little while pressed — soft tactile feedback for cards/buttons.
class Squeeze extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  const Squeeze({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
  });

  @override
  State<Squeeze> createState() => _SqueezeState();
}

class _SqueezeState extends State<Squeeze> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Coral pill button (primary action). Shows a spinner while busy.
class CoralButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool busy;

  const CoralButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) => Squeeze(
    onTap: busy ? null : onTap,
    semanticLabel: label,
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: Mart.coralGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Mart.coral.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    ),
  );
}

/// White circular icon button with soft shadow (48×48).
class RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color iconColor;
  final Color background;

  const RoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.iconColor = Mart.navy,
    this.background = Mart.card,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Squeeze(
      onTap: onTap,
      semanticLabel: tooltip,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: Mart.shadow(),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    ),
  );
}

/// Section title with optional trailing widget.
class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Mart.navy,
          ),
        ),
      ),
      ?trailing,
    ],
  );
}

/// Page transition: slides in from the right with a fade (shared-axis style).
Route<T> slideIn<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 380),
  reverseTransitionDuration: const Duration(milliseconds: 280),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (context, anim, _, child) {
    if (Mart.reduceMotion(context))
      return FadeTransition(opacity: anim, child: child);
    final c = CurvedAnimation(
      parent: anim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: c,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0.15, 0),
          end: Offset.zero,
        ).animate(c),
        child: child,
      ),
    );
  },
);

void notify(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: error ? Mart.red : Mart.navy,
        content: Row(
          children: [
            Icon(
              error ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
}

Future<bool> ask(
  BuildContext context, {
  required String title,
  required String message,
  required String yes,
  IconData icon = Icons.delete_rounded,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Mart.coralTint,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Mart.coral, size: 30),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, color: Mart.navy),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Mart.grey),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Mart.grey, fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Mart.coral,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(yes, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return res ?? false;
}
