// features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Appearance ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    'Appearance',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Accent Color'),
                  subtitle: Text(themeState.preset.label),
                  onTap: () => _showAccentColorSheet(context, ref, themeState.preset),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Theme Mode'),
                  subtitle: Text(_themeModeLabel(themeState.themeMode)),
                  onTap: () => _showThemeModeSheet(context, ref, themeState.themeMode),
                ),
                const Divider(),

                // ── Data ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    'Data',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Backup Data'),
                  subtitle: const Text('Export all data as JSON'),
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    final success = await BackupService.createBackup();
                    if (context.mounted) {
                      _showSnack(context, success ? 'Backup generated successfully' : 'Backup failed', success);
                    }
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.upload_outlined),
                  title: const Text('Restore Data'),
                  subtitle: const Text('Import from JSON backup'),
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Restore Data?'),
                        content: const Text('This will permanently replace all your current transactions, categories, and budget with the backup file. This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Restore'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    if (!context.mounted) return;
                    final success = await BackupService.restoreBackup();
                    if (context.mounted) {
                      _showSnack(context, success ? 'Data restored successfully' : 'Restore failed or cancelled', success);
                    }
                  },
                ),
                const Divider(),

                // ── About ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    'About',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Expenso'),
                  subtitle: const Text('v0.1.0 — Offline-first expense tracker'),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.code),
                  title: const Text('View on GitHub'),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    final url = Uri.parse('https://github.com/Pranit-DC/Expenso');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                ),
                const SizedBox(height: 100),
              ],
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
      ),
    );
  }

  void _showThemeModeSheet(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => _ThemeModeSheet(
        current: current,
        onChanged: (mode) {
          ref.read(themeProvider.notifier).setThemeMode(mode);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showAccentColorSheet(BuildContext context, WidgetRef ref, AppThemePreset current) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => _AccentColorSheet(
        current: current,
        onChanged: (preset) {
          ref.read(themeProvider.notifier).setPreset(preset);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _AccentColorSheet extends StatelessWidget {
  final AppThemePreset current;
  final ValueChanged<AppThemePreset> onChanged;

  const _AccentColorSheet({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('Accent Color', style: theme.textTheme.titleMedium),
            ),
            ...AppThemePreset.values.map((preset) {
              final isSelected = preset == current;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: preset.seedColor,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(preset.label),
                trailing: isSelected ? Icon(Icons.check, color: colorScheme.primary) : null,
                selected: isSelected,
                selectedColor: colorScheme.primary,
                selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                onTap: () => onChanged(preset),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeSheet extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeSheet({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final modes = [
      (ThemeMode.light, Icons.light_mode_outlined, 'Light'),
      (ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
      (ThemeMode.system, Icons.phone_android_outlined, 'Follow System'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('Theme Mode', style: theme.textTheme.titleMedium),
            ),
            ...modes.map((entry) {
              final (mode, icon, label) = entry;
              final isSelected = mode == current;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
                title: Text(label),
                trailing: isSelected ? Icon(Icons.check, color: colorScheme.primary) : null,
                selected: isSelected,
                selectedColor: colorScheme.primary,
                selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                onTap: () => onChanged(mode),
              );
            }),
          ],
        ),
      ),
    );
  }
}
