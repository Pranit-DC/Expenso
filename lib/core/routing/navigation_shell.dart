// core/routing/navigation_shell.dart
// The persistent bottom navigation bar shell — Cashew-style.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'app_router.dart';

class NavigationShell extends StatefulWidget {
  final Widget child;
  const NavigationShell({super.key, required this.child});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _previousIndex = 0;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < destinations.length; i++) {
      if (location == destinations[i].path) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: widget.child,
      // ── Extended FAB (Cashew-style add button) ──
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_transaction_fab',
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push(AppRoutes.addTransaction);
        },
        label: const Text(
          'Add',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        icon: const Icon(Icons.add_rounded, size: 22),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // ── Bottom Nav with sharp shadow (Cashew boxShadowSharp) ──
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            indicatorColor: Theme.of(context).colorScheme.primaryContainer,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.clip,
                );
              } else {
                return const TextStyle(
                  fontSize: 13,
                  overflow: TextOverflow.clip,
                );
              }
            }),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          ),
          child: NavigationBar(
          animationDuration: const Duration(milliseconds: 700),
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            setState(() => _previousIndex = currentIndex);
            context.go(destinations[index].path);
          },
          destinations: destinations
              .map(
                (d) => NavigationDestination(
                  icon: Icon(d.icon, size: 25),
                  selectedIcon: Icon(d.selectedIcon, size: 25),
                  label: d.label,
                  tooltip: '',
                ),
              )
              .toList(),
        ),
       ),
      ),
    );
  }
}
