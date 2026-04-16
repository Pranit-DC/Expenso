import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/widgets/tappable.dart';

class NumberPad extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback onDone;
  final Color activeColor;

  const NumberPad({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    required this.onDone,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PadKey(label: '1', onTap: () => onKeyPressed('1'), colorScheme: colorScheme),
              _PadKey(label: '2', onTap: () => onKeyPressed('2'), colorScheme: colorScheme),
              _PadKey(label: '3', onTap: () => onKeyPressed('3'), colorScheme: colorScheme),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PadKey(label: '4', onTap: () => onKeyPressed('4'), colorScheme: colorScheme),
              _PadKey(label: '5', onTap: () => onKeyPressed('5'), colorScheme: colorScheme),
              _PadKey(label: '6', onTap: () => onKeyPressed('6'), colorScheme: colorScheme),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PadKey(label: '7', onTap: () => onKeyPressed('7'), colorScheme: colorScheme),
              _PadKey(label: '8', onTap: () => onKeyPressed('8'), colorScheme: colorScheme),
              _PadKey(label: '9', onTap: () => onKeyPressed('9'), colorScheme: colorScheme),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PadKey(label: '.', onTap: () => onKeyPressed('.'), colorScheme: colorScheme),
              _PadKey(label: '0', onTap: () => onKeyPressed('0'), colorScheme: colorScheme),
              _PadKey(
                icon: PhosphorIconsRegular.backspace,
                onTap: onBackspace,
                onLongPress: () {
                  // Additional functionality like clear all could go here
                },
                colorScheme: colorScheme,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: onDone,
              icon: const Icon(Icons.check_rounded, size: 24),
              label: const Text('Confirm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: activeColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ColorScheme colorScheme;

  const _PadKey({
    this.label,
    this.icon,
    required this.onTap,
    this.onLongPress,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Tappable(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
            child: Center(
              child: label != null
                  ? Text(
                      label!,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    )
                  : Icon(icon, size: 28, color: colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
