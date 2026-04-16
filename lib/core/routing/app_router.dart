// core/routing/app_router.dart
// go_router configuration with ShellRoute for bottom navigation.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/transactions/screens/history_screen.dart';
import '../../features/transactions/screens/add_transaction_screen.dart';
import '../../features/insights/screens/insights_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../core/database/models/transaction_model.dart';
import 'navigation_shell.dart';

/// Route path constants.
abstract class AppRoutes {
  static const dashboard = '/';
  static const history = '/history';
  static const insights = '/insights';
  static const settings = '/settings';
  static const addTransaction = '/add-transaction';
}

/// Tab definition for the bottom nav.
class NavDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;

  const NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });
}

const List<NavDestination> destinations = [
  NavDestination(
    label: 'Home',
    icon: PhosphorIconsRegular.house,
    selectedIcon: PhosphorIconsFill.house,
    path: AppRoutes.dashboard,
  ),
  NavDestination(
    label: 'History',
    icon: PhosphorIconsRegular.clockCounterClockwise,
    selectedIcon: PhosphorIconsFill.clockCounterClockwise,
    path: AppRoutes.history,
  ),
  NavDestination(
    label: 'Insights',
    icon: PhosphorIconsRegular.chartPieSlice,
    selectedIcon: PhosphorIconsFill.chartPieSlice,
    path: AppRoutes.insights,
  ),
  NavDestination(
    label: 'Settings',
    icon: PhosphorIconsRegular.gearSix,
    selectedIcon: PhosphorIconsFill.gearSix,
    path: AppRoutes.settings,
  ),
];

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,
  routes: [
    // --- Shell Route for bottom nav ---
    ShellRoute(
      builder: (context, state, child) {
        return NavigationShell(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.history,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HistoryScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.insights,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: InsightsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),

    // --- Full-screen routes (pushed on top of shell) ---
    GoRoute(
      path: AppRoutes.addTransaction,
      builder: (context, state) {
        final existing = state.extra as TransactionModel?;
        return AddTransactionScreen(existingTransaction: existing);
      },
    ),
  ],
);
