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
  DateTime? _lastBackPress;

  void _trackTab(int index) {
    if (_tabHistory.isNotEmpty && _tabHistory.last == index) return;
    _tabHistory.remove(index);
    _tabHistory.add(index);
  }

  /// Called when the system back button is pressed and no modal (bottom sheet,
  /// dialog, or full-screen route like AddTransactionScreen) is on top.
  ///
  /// We NEVER call appRouter.pop() / context.pop() here — that would pop the
  /// shell route itself and exit the app. Instead we only switch tabs.
  void _handleSystemBack() {
    // 1. If we have visited multiple tabs, go back to the previous one.
    if (_tabHistory.length > 1) {
      _tabHistory.removeLast();
      final previousIndex = _tabHistory.last;
      widget.navigationShell.goBranch(previousIndex, initialLocation: false);
      return;
    }

    // 2. If on any tab other than Home, jump to Home.
    final currentIndex = widget.navigationShell.currentIndex;
    if (currentIndex != 0) {
      _tabHistory.clear();
      widget.navigationShell.goBranch(0, initialLocation: false);
      _trackTab(0);
      return;
    }

    // 3. On Home tab — double-press to exit.
    final now = DateTime.now();
    final lastPress = _lastBackPress;
    if (lastPress == null ||
        now.difference(lastPress) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Press back again to exit')),
        );
      return;
    }

    // 4. Second press within 2 s → exit.
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    _trackTab(currentIndex);

    // PopScope with canPop: false tells the framework this route should NOT
    // be popped by the system back button. Navigator.maybePop() will return
    // RoutePopDisposition.doNotPop → the framework reports the event as
    // "handled" so Android does NOT exit the app.
    //
    // When a bottom sheet / dialog / full-screen route (e.g. AddTransaction)
    // is pushed ON TOP of this shell (on the root navigator), that route
    // becomes the topmost ModalRoute. The system back button pops THAT route
    // first; our PopScope is NOT involved. So bottom sheets close normally.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // didPop == true means the route actually popped (won't happen since
        // canPop is false, but guard anyway).
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
