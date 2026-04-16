// core/theme/theme_provider.dart
// Riverpod providers for theme state management.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_theme.dart';

/// Persisted theme settings key constants.
const String _kThemeBox = 'settings';
const String _kPresetKey = 'themePreset';
const String _kBrightnessKey = 'themeBrightness'; // 'light', 'dark', 'system'

/// Holds the current theme configuration.
class ThemeState {
  final AppThemePreset preset;
  final ThemeMode themeMode;

  const ThemeState({
    this.preset = AppThemePreset.emerald,
    this.themeMode = ThemeMode.system,
  });

  ThemeState copyWith({AppThemePreset? preset, ThemeMode? themeMode}) {
    return ThemeState(
      preset: preset ?? this.preset,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Manages theme state and persists to Hive.
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _load();
  }

  late Box _box;

  Future<void> _load() async {
    _box = await Hive.openBox(_kThemeBox);

    final presetIndex = _box.get(_kPresetKey, defaultValue: 0) as int;
    final brightnessStr =
        _box.get(_kBrightnessKey, defaultValue: 'system') as String;

    final preset = AppThemePreset.values[
        presetIndex.clamp(0, AppThemePreset.values.length - 1)];

    final themeMode = switch (brightnessStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    state = ThemeState(preset: preset, themeMode: themeMode);
  }

  void setPreset(AppThemePreset preset) {
    state = state.copyWith(preset: preset);
    _box.put(_kPresetKey, preset.index);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    _box.put(_kBrightnessKey, str);
  }

  void toggleBrightness(BuildContext context) {
    final currentBrightness = Theme.of(context).brightness;
    if (currentBrightness == Brightness.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}

/// Global theme provider.
final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeState>((ref) => ThemeNotifier());
