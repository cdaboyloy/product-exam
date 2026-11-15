import 'dart:async';

import 'package:flutter/material.dart';

/// Shows the app inside an iPhone 17 Pro Max–style frame when the window is
/// wide (Chrome on a laptop). On real phones / narrow windows the app is
/// shown full-screen as normal.
class IPhoneFrame extends StatelessWidget {
  final Widget child;
  const IPhoneFrame({super.key, required this.child});

  // iPhone 17 Pro Max screen in logical points
  static const screenW = 440.0;
  static const screenH = 956.0;
  static const bezel = 14.0;
  static const radius = 66.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < 600) return child; // already a phone-sized screen

    const frameW = screenW + bezel * 2;
    const frameH = screenH + bezel * 2;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF4EE), Color(0xFFF6F6F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          // Scale the whole phone down to fit short windows
          child: FittedBox(
            child: SizedBox(
              width: frameW + 8, // room for side buttons
              height: frameH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // side buttons (left: action + volume, right: power)
                  _sideButton(left: 0, top: 190, height: 34),
                  _sideButton(left: 0, top: 250, height: 62),
                  _sideButton(left: 0, top: 326, height: 62),
                  _sideButton(right: 0, top: 290, height: 100),
                  // titanium body
                  Positioned(
                    left: 4,
                    top: 0,
                    width: frameW,
                    height: frameH,
                    child: Container(
                      padding: const EdgeInsets.all(bezel),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius + bezel),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF3B4A6B),
                            Color(0xFF1F2A44),
                            Color(0xFF3B4A6B),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40FF6B3D),
                            blurRadius: 40,
                            offset: Offset(0, 20),
                          ),
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(radius + 2),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(radius),
                          child: _Screen(child: child),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sideButton({
    double? left,
    double? right,
    required double top,
    required double height,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Container(
        width: 6,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF2A3654),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

/// The phone screen: app content + status bar, Dynamic Island, home indicator.
class _Screen extends StatelessWidget {
  final Widget child;
  const _Screen({required this.child});

  static const topInset = 62.0; // status bar + Dynamic Island area
  static const bottomInset = 34.0; // home indicator area

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      // Make the app believe it runs on an iPhone 17 Pro Max
      data: mq.copyWith(
        size: const Size(IPhoneFrame.screenW, IPhoneFrame.screenH),
        padding: const EdgeInsets.only(top: topInset, bottom: bottomInset),
        viewPadding: const EdgeInsets.only(top: topInset, bottom: bottomInset),
        devicePixelRatio: mq.devicePixelRatio,
      ),
      child: Stack(
        children: [
          Positioned.fill(child: child),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(child: _StatusBar()),
          ),
          // Dynamic Island
          Positioned(
            top: 14,
            left: (IPhoneFrame.screenW - 126) / 2,
            child: IgnorePointer(
              child: Container(
                width: 126,
                height: 37,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 14),
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFF2B3A5C), Color(0xFF0A0A12)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Home indicator
          Positioned(
            bottom: 9,
            left: (IPhoneFrame.screenW - 150) / 2,
            child: IgnorePointer(
              child: Container(
                width: 150,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1B22),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatefulWidget {
  const _StatusBar();

  @override
  State<_StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<_StatusBar> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final time = '$h:${_now.minute.toString().padLeft(2, '0')}';
    const color = Color(0xFF1C1B22);
    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(44, 16, 34, 0),
        child: Row(
          children: [
            Text(
              time,
              style: const TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.signal_cellular_alt_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 5),
            const Icon(Icons.wifi_rounded, size: 18, color: color),
            const SizedBox(width: 6),
            // battery
            Container(
              width: 27,
              height: 13,
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                border: Border.all(
                  color: color.withValues(alpha: 0.45),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 2,
              height: 5,
              margin: const EdgeInsets.only(left: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
