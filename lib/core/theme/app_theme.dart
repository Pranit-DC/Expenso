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
  onyx('Onyx', Color(0xFF37474F), Color(0xFF263238)),
  ruby('Ruby', Color(0xFFC62828), Color(0xFFB71C1C)),
  gold('Gold', Color(0xFFFBC02D), Color(0xFFF9A825)),
  indigo('Indigo', Color(0xFF3F51B5), Color(0xFF303F9F)),
  rose('Rose', Color(0xFFEC407A), Color(0xFFD81B60));

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

    final baseTextTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.robotoTextTheme(baseTextTheme).copyWith(
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
        fontSize: 48,
        color: colorScheme.onSurface,
        letterSpacing: -1.5,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w900,
        fontSize: 28,
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      brightness: brightness,

      // --- Expressive Surface Tints ---
      scaffoldBackgroundColor: colorScheme.surface,

      // --- AppBar ---
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 3,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: textTheme.titleLarge,
      ),

      // --- Cards ---
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: colorScheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
      ),

      // --- Bottom Navigation ---
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: colorScheme.surfaceContainer,
      ),

      // --- FAB ---
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(8),
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
