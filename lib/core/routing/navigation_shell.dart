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

class _NavigationShellState extends State<NavigationShell> {
  final List<int> _tabHistory = [];

  void _trackTab(int index) {
    if (_tabHistory.isNotEmpty && _tabHistory.last == index) return;
    _tabHistory.remove(index);
    _tabHistory.add(index);
  }

  void _handleSystemBack() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }

    if (_tabHistory.length > 1) {
      _tabHistory.removeLast();
      final previousIndex = _tabHistory.last;
      widget.navigationShell.goBranch(previousIndex, initialLocation: false);
      return;
    }

    final currentIndex = widget.navigationShell.currentIndex;
    if (currentIndex != 0) {
      widget.navigationShell.goBranch(0, initialLocation: false);
      _trackTab(0);
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    _trackTab(currentIndex);
    return BackButtonListener(
      onBackButtonPressed: () async {
        _handleSystemBack();
        return true;
      },
      child: Scaffold(
        body: widget.navigationShell,
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
            _trackTab(index);
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
