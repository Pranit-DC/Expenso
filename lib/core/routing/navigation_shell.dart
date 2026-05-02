import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'app_router.dart';

class NavigationShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const NavigationShell({super.key, required this.navigationShell});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> with WidgetsBindingObserver {
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    _handleSystemBack();
    return true;
  }

  void _handleSystemBack() {
    if (appRouter.canPop()) {
      appRouter.pop();
      return;
    }

    final currentIndex = widget.navigationShell.currentIndex;
    if (currentIndex != 0) {
      widget.navigationShell.goBranch(0, initialLocation: false);
      return;
    }

    final now = DateTime.now();
    final lastPress = _lastBackPress;
    if (lastPress == null || now.difference(lastPress) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Press back again to exit')),
        );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: Scaffold(
        body: widget.navigationShell,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'add_transaction_fab',
          onPressed: () {
            HapticFeedback.mediumImpact();
            appRouter.push(AppRoutes.addTransaction);
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
            widget.navigationShell.goBranch(index, initialLocation: false);
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
