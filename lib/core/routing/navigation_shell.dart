import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'app_router.dart';

class NavigationShell extends StatefulWidget {
  final Widget child;
  const NavigationShell({super.key, required this.child});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < destinations.length; i++) {
      if (location == destinations[i].path) return i;
    }
    return 0;
  }

  Future<bool> _handleSystemBack(BuildContext context) async {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return false;
    }

    final currentIndex = _currentIndex(context);
    if (currentIndex != 0) {
      context.go(AppRoutes.dashboard);
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    return WillPopScope(
      onWillPop: () => _handleSystemBack(context),
      child: Scaffold(
        body: widget.child,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'add_transaction_fab',
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.push(AppRoutes.addTransaction);
          },
          label: const Text(
            'Add',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          icon: const Icon(PhosphorIconsRegular.plus),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            context.go(destinations[index].path);
          },
          destinations: destinations
              .map(
                (d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                  tooltip: '',
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
