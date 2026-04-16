import 'package:flutter/material.dart';

/// Wraps AnimatedSize for smooth height expansion and collapsing
/// with intelligent clipping and alignment.
class AnimatedSizeSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Alignment alignment;

  const AnimatedSizeSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: alignment,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
