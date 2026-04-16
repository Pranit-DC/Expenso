import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A Cashew-inspired Tappable widget that provides iOS-style opacity fades
/// or Android-style ripples depending on the platform/configuration.
class Tappable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final Color? color;

  const Tappable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.color,
  });

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  bool _isDown = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isDown = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isDown = false);
    }
  }

  void _handleTapCancel() {
    if (_isDown) {
      setState(() => _isDown = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.macOS;

    if (!isIOS) {
      return Material(
        color: widget.color ?? Colors.transparent,
        borderRadius: widget.borderRadius,
        clipBehavior: widget.borderRadius != null ? Clip.antiAlias : Clip.none,
        child: InkWell(
          onTap: () {
            if (widget.onTap != null) HapticFeedback.selectionClick();
            widget.onTap?.call();
          },
          onLongPress: () {
            if (widget.onLongPress != null) HapticFeedback.heavyImpact();
            widget.onLongPress?.call();
          },
          borderRadius: widget.borderRadius,
          splashFactory: InkSparkle.splashFactory,
          child: widget.child,
        ),
      );
    }

    // iOS/macOS opacity fade style
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: () {
        if (widget.onTap != null) HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      onLongPress: () {
        if (widget.onLongPress != null) HapticFeedback.heavyImpact();
        widget.onLongPress?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _isDown ? 0.6 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: widget.color ?? Colors.transparent,
            borderRadius: widget.borderRadius,
          ),
          clipBehavior: widget.borderRadius != null ? Clip.antiAlias : Clip.none,
          child: widget.child,
        ),
      ),
    );
  }
}
