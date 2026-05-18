import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SwipeHintOverlay extends StatefulWidget {
  final int step;
  final bool isFirstItem;
  const SwipeHintOverlay({super.key, required this.step, this.isFirstItem = false});

  @override
  State<SwipeHintOverlay> createState() => _SwipeHintOverlayState();
}

class _SwipeHintOverlayState extends State<SwipeHintOverlay> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _gestureController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _gestureOffset;
  late final Animation<double> _gestureOpacity;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _gestureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    // Hold for 25 % of the cycle, then slide + fade over the remaining 75 %.
    // At t=1 the arrows are fully transparent, so the loop reset is invisible.
    _gestureOffset = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 25),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 16.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 75,
      ),
    ]).animate(_gestureController);

    _gestureOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 75,
      ),
    ]).animate(_gestureController);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _gestureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _gestureController]),
      builder: (context, _) => FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: widget.step == 1 ? _buildBrowseHint() : _buildDetailsHint(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseHint() {
    final offset = _gestureOffset.value;
    final opacity = _gestureOpacity.value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.isFirstItem) ...[
          _animatedArrow(Icons.arrow_back_ios_new_rounded, Offset(-offset, 0), opacity),
          const SizedBox(width: 14),
        ],
        Text(
          'swipe_to_browse'.tr(),
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0.2),
        ),
        const SizedBox(width: 14),
        _animatedArrow(Icons.arrow_forward_ios_rounded, Offset(offset, 0), opacity),
      ],
    );
  }

  Widget _buildDetailsHint() {
    final offset = _gestureOffset.value;
    final opacity = _gestureOpacity.value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _animatedArrow(Icons.arrow_upward_rounded, Offset(0, -offset), opacity),
        const SizedBox(width: 14),
        Text(
          'swipe_up_for_details'.tr(),
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0.2),
        ),
      ],
    );
  }

  Widget _animatedArrow(IconData icon, Offset offset, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: offset,
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
