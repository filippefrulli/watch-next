import 'dart:async';
import 'package:flutter/material.dart';
import 'package:watch_next/main.dart' show navigatorKey;

/// Vertical placement for a toast.
enum ToastGravity { top, center, bottom }

/// Lightweight, dependency-free toast built on the app's root [Overlay].
///
/// Replaces the previous `fluttertoast` (no Swift Package Manager support) and
/// `oktoast` packages. Context-free: it locates the overlay through the global
/// [navigatorKey], so it can be called from anywhere, including async gaps.
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  /// Shows a simple text toast.
  static void showText(
    String message, {
    Color backgroundColor = const Color(0xF2202028),
    Color textColor = Colors.white,
    ToastGravity gravity = ToastGravity.bottom,
    Duration duration = const Duration(seconds: 3),
    double fontSize = 16,
  }) {
    _show(
      duration: duration,
      child: _align(
        gravity,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows a fully custom toast [child]. The widget is responsible for its own
  /// alignment and padding (see `ToastWidget`).
  static void showWidget(
    Widget child, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(duration: duration, child: child);
  }

  /// Dismisses the current toast, if any.
  static void dismiss() => _dismiss();

  static Widget _align(ToastGravity gravity, Widget child) {
    switch (gravity) {
      case ToastGravity.top:
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(padding: const EdgeInsets.only(top: 24), child: child),
          ),
        );
      case ToastGravity.center:
        return Align(alignment: Alignment.center, child: child);
      case ToastGravity.bottom:
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(padding: const EdgeInsets.only(bottom: 48), child: child),
          ),
        );
    }
  }

  static void _show({required Widget child, required Duration duration}) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _dismiss();
    final entry = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: _ToastAnimator(duration: duration, child: child),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

/// Fades the toast in on mount and back out shortly before it is removed.
class _ToastAnimator extends StatefulWidget {
  final Duration duration;
  final Widget child;

  const _ToastAnimator({required this.duration, required this.child});

  @override
  State<_ToastAnimator> createState() => _ToastAnimatorState();
}

class _ToastAnimatorState extends State<_ToastAnimator> with SingleTickerProviderStateMixin {
  static const _fade = Duration(milliseconds: 220);
  late final AnimationController _controller = AnimationController(vsync: this, duration: _fade)..forward();

  @override
  void initState() {
    super.initState();
    final holdOut = widget.duration - _fade;
    Future.delayed(holdOut.isNegative ? Duration.zero : holdOut, () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: widget.child);
  }
}
