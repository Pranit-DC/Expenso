// core/theme/app_theme.dart
// Defines the 5 preset Material 3 themes for Expenso.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All available theme presets.
enum AppThemePreset {
  emerald('Emerald', Color(0xFF2E7D5F), Color(0xFF1B5E40)),
  sapphire('Sapphire', Color(0xFF1565C0), Color(0xFF0D47A1)),
  amethyst('Amethyst', Color(0xFF7B1FA2), Color(0xFF6A1B9A)),
  amber('Amber', Color(0xFFE65100), Color(0xFFBF360C)),
  onyx('Onyx', Color(0xFF37474F), Color(0xFF263238));

  const AppThemePreset(this.label, this.seedColor, this.seedColorDark);
  final String label;
  final Color seedColor;
  final Color seedColorDark;
}

class AppTheme {
  AppTheme._();

  /// Builds a full [ThemeData] from a preset and brightness.
  static ThemeData buildTheme(AppThemePreset preset, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color seed = isDark ? preset.seedColorDark : preset.seedColor;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final textTheme = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      brightness: brightness,

      // --- Expressive Surface Tints ---
      scaffoldBackgroundColor: isDark
          ? colorScheme.surface
          : colorScheme.surface,

      // --- AppBar ---
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      // --- Cards ---
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: colorScheme.primary,
      ),

      // --- Bottom Navigation ---
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: isDark
            ? colorScheme.surfaceContainer
            : colorScheme.surfaceContainerLowest,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.onPrimaryContainer,
              size: 24,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          );
          if (states.contains(WidgetState.selected)) {
            return base?.copyWith(color: colorScheme.onSurface);
          }
          return base?.copyWith(color: colorScheme.onSurfaceVariant);
        }),
      ),

      // --- FAB ---
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // --- Input Decoration ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      // --- Chips ---
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // --- Divider ---
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
      ),

      // --- BottomSheet ---
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
      ),

      // --- Page transitions ---
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Convenience getters for light/dark from a preset.
  static ThemeData light(AppThemePreset preset) =>
      buildTheme(preset, Brightness.light);

  static ThemeData dark(AppThemePreset preset) =>
      buildTheme(preset, Brightness.dark);
}
