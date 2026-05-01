import 'package:flutter/material.dart';

class ColorUtils {
  ColorUtils._();

  /// Generates a monochromatic palette based on a base color.
  /// Primarily used for charts to keep the UI clean and unified.
  static List<Color> generateMonochromaticPalette(Color base, int count) {
    if (count <= 0) return [];
    if (count == 1) return [base];

    return List.generate(count, (i) {
      // Start from the base color and progressively lighten/desaturate
      // This creates a sophisticated, cohesive look.
      final double factor = i / (count > 1 ? count - 1 : 1);
      
      // We mix with white for light themes or surface for dark? 
      // Actually, varying opacity is safest for M3 surface blending.
      return base.withValues(alpha: 1.0 - (factor * 0.7).clamp(0.0, 0.7));
    });
  }

  /// Returns a harmonic color for a category based on its index.
  static Color getHarmonicColor(BuildContext context, int index, int total) {
    final primary = Theme.of(context).colorScheme.primary;
    if (total <= 1) return primary;
    
    final double opacity = 1.0 - (index / total * 0.6).clamp(0.0, 0.6);
    return primary.withValues(alpha: opacity);
  }
}
