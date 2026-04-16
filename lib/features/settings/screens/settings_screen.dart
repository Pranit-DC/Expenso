// features/settings/screens/settings_screen.dart
// Cashew-inspired settings: large icon tiles, section headers, animated transitions.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/backup_service.dart';
import '../../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.medium(
            title: const Text('Settings'),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // ── Theme Section ──
                  _SectionHeader(
                    title: 'Appearance',
                    colorScheme: colorScheme,
                    theme: theme,
                  ).animate().fadeIn(duration: 300.ms),

                  // ── Color Palette ──
                  _CashewSettingsTile(
                    icon: PhosphorIconsFill.palette,
                    title: 'Accent Color',
                    subtitle: 'Choose your app color theme',
                    colorScheme: colorScheme,
                    theme: theme,
                    trailing: _ColorDotRow(
                      selected: themeState.preset,
                      onSelected: (p) =>
                          ref.read(themeProvider.notifier).setPreset(p),
                    ),
                    index: 0,
                  ),

                  // ── Brightness Mode ──
                  _CashewSettingsTile(
                    icon: PhosphorIconsFill.sun,
                    title: 'Theme Mode',
                    subtitle: _themeModeLabel(themeState.themeMode),
                    colorScheme: colorScheme,
                    theme: theme,
                    onTap: () =>
                        _showThemeModeSheet(context, ref, themeState.themeMode),
                    index: 1,
                  ),

                  const SizedBox(height: 8),

                  // ── Data Section ──
                  _SectionHeader(
                    title: 'Data',
                    colorScheme: colorScheme,
                    theme: theme,
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                  _CashewSettingsTile(
                    icon: PhosphorIconsDuotone.downloadSimple,
                    title: 'Backup Data',
                    subtitle: 'Export all data as JSON',
                    colorScheme: colorScheme,
                    theme: theme,
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      final success = await BackupService.createBackup();
                      if (context.mounted) {
                        _showSnack(context, success
                            ? 'Backup generated successfully'
                            : 'Backup failed', success);
                      }
                    },
                    index: 2,
                  ),

                  _CashewSettingsTile(
                    icon: PhosphorIconsDuotone.uploadSimple,
                    title: 'Restore Data',
                    subtitle: 'Import from JSON backup',
                    colorScheme: colorScheme,
                    theme: theme,
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      final success = await BackupService.restoreBackup();
                      if (context.mounted) {
                        _showSnack(context, success
                            ? 'Data restored successfully'
                            : 'Restore failed or cancelled', success);
                      }
                    },
                    index: 3,
                  ),

                  const SizedBox(height: 8),

                  // ── About Section ──
                  _SectionHeader(
                    title: 'About',
                    colorScheme: colorScheme,
                    theme: theme,
                  ).animate().fadeIn(delay: 160.ms, duration: 300.ms),

                  _AboutCard(
                    colorScheme: colorScheme,
                    theme: theme,
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'Follow system',
    };
  }

  void _showSnack(BuildContext context, String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? const Color(0xFF59A849) : Colors.red.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      ),
    );
  }

  void _showThemeModeSheet(
      BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ThemeModeSheet(
        current: current,
        onChanged: (mode) {
          ref.read(themeProvider.notifier).setThemeMode(mode);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ── Cashew-style section header ──
class _SectionHeader extends StatelessWidget {
  final String title;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _SectionHeader({
    required this.title,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Cashew-style settings tile: big icon (30px secondary), bold title ──
class _CashewSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback? onTap;
  final Widget? trailing;
  final int index;

  const _CashewSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
    required this.theme,
    this.onTap,
    this.trailing,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Cashew: large 30px icon in secondary color
                Icon(
                  icon,
                  size: 30,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (trailing == null && onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.outline,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (index * 50).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.02, end: 0);
  }
}

// ── Color dot row (compact version of _ThemePresetSelector) ──
class _ColorDotRow extends StatelessWidget {
  final AppThemePreset selected;
  final ValueChanged<AppThemePreset> onSelected;

  const _ColorDotRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.end,
        children: AppThemePreset.values.map((preset) {
          final isSelected = preset == selected;
          return GestureDetector(
            onTap: () => onSelected(preset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: preset.seedColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: preset.seedColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── About card ──
class _AboutCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _AboutCard({required this.colorScheme, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(PhosphorIconsDuotone.currencyCircleDollar,
                size: 32, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Expenso',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'v0.1.0 — Offline-first expense tracker',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Theme Mode bottom sheet ──
class _ThemeModeSheet extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeSheet({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final modes = [
      (ThemeMode.light, PhosphorIconsFill.sun, 'Light'),
      (ThemeMode.dark, PhosphorIconsFill.moon, 'Dark'),
      (ThemeMode.system, PhosphorIconsFill.deviceMobile, 'Follow System'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Theme Mode',
                style:
                    theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...modes.map((entry) {
              final (mode, icon, label) = entry;
              final isSelected = mode == current;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(icon,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant),
                title: Text(label,
                    style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500)),
                trailing: isSelected
                    ? Icon(Icons.check_rounded, color: colorScheme.primary)
                    : null,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                    : null,
                onTap: () => onChanged(mode),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
