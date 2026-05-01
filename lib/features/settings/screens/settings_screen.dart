// features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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
        slivers: [
          SliverAppBar.large(
            title: const Text('Settings'),
            pinned: true,
            centerTitle: false,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  'APPEARANCE',
                  [
                    _buildSettingItem(
                      icon: PhosphorIconsFill.palette,
                      title: 'Accent Color',
                      subtitle: themeState.preset.label,
                      colorScheme: colorScheme,
                      onTap: () => _showAccentColorSheet(context, ref, themeState.preset),
                    ),
                    _buildSettingItem(
                      icon: PhosphorIconsFill.moonStars,
                      title: 'Theme Mode',
                      subtitle: _themeModeLabel(themeState.themeMode),
                      colorScheme: colorScheme,
                      onTap: () => _showThemeModeSheet(context, ref, themeState.themeMode),
                    ),
                  ],
                  theme,
                ),
                _buildSection(
                  'DATA MANAGEMENT',
                  [
                    _buildSettingItem(
                      icon: PhosphorIconsFill.cloudArrowUp,
                      title: 'Backup Data',
                      subtitle: 'Export all data as JSON',
                      colorScheme: colorScheme,
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        final success = await BackupService.createBackup();
                        if (context.mounted) {
                          _showSnack(context, success ? 'Backup generated successfully' : 'Backup failed', success);
                        }
                      },
                    ),
                    _buildSettingItem(
                      icon: PhosphorIconsFill.cloudArrowDown,
                      title: 'Restore Data',
                      subtitle: 'Import from JSON backup',
                      colorScheme: colorScheme,
                      onTap: () => _handleRestore(context, colorScheme),
                    ),
                  ],
                  theme,
                ),
                _buildSection(
                  'ABOUT',
                  [
                    _buildSettingItem(
                      icon: PhosphorIconsFill.info,
                      title: 'Expenso',
                      subtitle: 'v0.1.0 — Offline-first tracker',
                      colorScheme: colorScheme,
                      trailing: const SizedBox.shrink(),
                    ),
                  ],
                  theme,
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _launchGitHub(),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(PhosphorIconsFill.githubLogo, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              const Text(
                                'View on GitHub',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 24, 12),
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 11,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
      trailing: trailing ?? Icon(PhosphorIconsBold.caretRight, size: 16, color: colorScheme.onSurfaceVariant),
    );
  }

  Future<void> _handleRestore(BuildContext context, ColorScheme colorScheme) async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data?'),
        content: const Text('This will permanently replace all your current data with the backup file. This cannot be undone.'),
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
    final success = await BackupService.restoreBackup();
    if (context.mounted) {
      _showSnack(context, success ? 'Data restored successfully' : 'Restore failed', success);
    }
  }

  Future<void> _launchGitHub() async {
    HapticFeedback.selectionClick();
    final url = Uri.parse('https://github.com/Pranit-DC/Expenso');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
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
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: AppThemePreset.values.map((preset) {
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
                }).toList(),
              ),
            ),
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
