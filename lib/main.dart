// main.dart
// Entry point for the Expenso application.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routing/app_router.dart';
import 'core/database/database_service.dart';
import 'core/database/default_categories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Register adapters and open boxes
  await DatabaseService.initialize();

  // Seed default categories on first launch
  await DefaultCategories.seed();

  runApp(
    const ProviderScope(
      child: ExpensoApp(),
    ),
  );
}

class ExpensoApp extends ConsumerWidget {
  const ExpensoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Expenso',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.light(themeState.preset),
      darkTheme: AppTheme.dark(themeState.preset),
      themeMode: themeState.themeMode,

      // Router
      routerConfig: appRouter,
    );
  }
}
