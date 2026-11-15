import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Tappable wrapper: squishes (spring) and tilts in 3D toward the finger.
class Pressable3D extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double maxTilt; // radians
  final double pressedScale;
  final String? semanticLabel;

  const Pressable3D({
    super.key,
    required this.child,
    this.onTap,
    this.maxTilt = 0.14,
    this.pressedScale = 0.95,
    this.semanticLabel,
  });

  @override
  State<Pressable3D> createState() => _Pressable3DState();
}

class _Pressable3DState extends State<Pressable3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Offset _tilt = Offset.zero; // -1..1

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(TapDownDetails d) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && !AppMotion.reduced(context)) {
      final s = box.size;
      _tilt = Offset(
        ((d.localPosition.dx / s.width) - 0.5) * 2,
        ((d.localPosition.dy / s.height) - 0.5) * 2,
      );
    } else {
      _tilt = Offset.zero;
    }
    HapticFeedback.selectionClick();
    _c.animateTo(
      1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  void _up([_]) {
    _c.animateTo(
      0,
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : _down,
        onTapUp: widget.onTap == null ? null : _up,
        onTapCancel: widget.onTap == null ? null : _up,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _c,
          child: widget.child,
          builder: (context, child) {
            final t = _c.value;
            final scale = 1 - (1 - widget.pressedScale) * t;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0016) // perspective
                ..rotateX(-_tilt.dy * widget.maxTilt * t)
                ..rotateY(_tilt.dx * widget.maxTilt * t),
              child: Transform.scale(scale: scale, child: child),
            );
          },
        ),
      ),
    );
  }
}

/// Entrance animation: card flips up in 3D + fades + slides, staggered by index.
class StaggerIn extends StatefulWidget {
  final Widget child;
  final int index;
  const StaggerIn({super.key, required this.child, this.index = 0});

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    final delay = Duration(milliseconds: 50 * math.min(widget.index, 8));
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX((1 - t) * 0.55),
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 36),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Soft colored blobs drifting slowly in the background (header decoration).
class FloatingBlobs extends StatefulWidget {
  const FloatingBlobs({super.key});

  @override
  State<FloatingBlobs> createState() => _FloatingBlobsState();
}

class _FloatingBlobsState extends State<FloatingBlobs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _blob(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final a = _c.value * 2 * math.pi;
          return Stack(
            children: [
              Positioned(
                right: -40 + 22 * math.sin(a),
                top: -50 + 18 * math.cos(a),
                child: _blob(AppColors.accent.withValues(alpha: 0.55), 220),
              ),
              Positioned(
                left: -60 + 20 * math.cos(a),
                bottom: -70 + 16 * math.sin(a),
                child: _blob(AppColors.sky.withValues(alpha: 0.6), 240),
              ),
              Positioned(
                left: 120 + 26 * math.sin(a + 1.5),
                top: 30 + 14 * math.cos(a + 1.5),
                child: _blob(AppColors.mint.withValues(alpha: 0.55), 160),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A cube-like icon slowly spinning in 3D (Y axis) — header mascot.
class Spin3DIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  const Spin3DIcon({super.key, required this.icon, this.size = 30});

  @override
  State<Spin3DIcon> createState() => _Spin3DIconState();
}

class _Spin3DIconState extends State<Spin3DIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final a = _c.value * 2 * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.003)
            ..rotateY(a)
            ..rotateX(0.25 * math.sin(a)),
          child: Container(
            width: widget.size * 1.9,
            height: widget.size * 1.9,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(
              widget.icon,
              color: AppColors.primary,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}

/// Animated number that counts up when it appears or changes.
class CountUp extends StatelessWidget {
  final double value;
  final String Function(double) format;
  final TextStyle? style;
  const CountUp({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: AppMotion.reduced(context)
          ? Duration.zero
          : const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(format(v), style: style),
    );
  }
}

/// Shimmer gradient sweeping over placeholder shapes.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) => LinearGradient(
          colors: const [
            Color(0xFFECE8F6),
            Color(0xFFFBFAFE),
            Color(0xFFECE8F6),
          ],
          stops: const [0.35, 0.5, 0.65],
          transform: _SlideGradient(_c.value),
        ).createShader(rect),
        child: child,
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double t;
  const _SlideGradient(this.t);
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (2 * t - 1), 0, 0);
}

/// Gentle vertical bobbing (used for the empty/error illustration).
class Bob extends StatefulWidget {
  final Widget child;
  const Bob({super.key, required this.child});

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
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
      final t = Curves.easeInOut.transform(_c.value);
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateY((t - 0.5) * 0.5),
        child: Transform.translate(offset: Offset(0, -10 * t), child: child),
      );
    },
  );
}

/// Page route: new screen swings in with 3D perspective + fade.
Route<T> route3D<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: AppMotion.slow,
  reverseTransitionDuration: const Duration(milliseconds: 300),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (context, anim, _, child) {
    if (AppMotion.reduced(context)) {
      return FadeTransition(opacity: anim, child: child);
    }
    final curved = CurvedAnimation(
      parent: anim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        final v = curved.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY((1 - v) * -0.4),
            child: Transform.translate(
              offset: Offset((1 - v) * 40, 0),
              child: child,
            ),
          ),
        );
      },
    );
  },
);
