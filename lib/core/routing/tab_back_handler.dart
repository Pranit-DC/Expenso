import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// A wrapper widget for shell branch roots to handle system back button correctly.
/// We use WillPopScope here (despite being deprecated) because in some
/// configurations of go_router and Flutter, it remains more reliable for
/// intercepting the system back event at the branch navigator level.
class TabBackHandler extends StatefulWidget {
  final Widget child;
  const TabBackHandler({super.key, required this.child});

  @override
  State<TabBackHandler> createState() => _TabBackHandlerState();
}

class _TabBackHandlerState extends State<TabBackHandler> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    // Get the nearest StatefulNavigationShell to control tab switching
    final shell = StatefulNavigationShell.of(context);

    return WillPopScope(
      onWillPop: () async {
        // 1. Safety check: Handle root navigator pops (Modals, Bottom Sheets)
        // If the root navigator has something to pop, we let it pop.
        final rootNavigator = Navigator.of(context, rootNavigator: true);
        if (rootNavigator.canPop()) {
          return true; // Allow pop
        }

        // 2. Tab Navigation: If not on Home tab, switch to Home tab
        if (shell.currentIndex != 0) {
          shell.goBranch(0, initialLocation: false);
          return false; // PREVENT APP EXIT
        }

        // 3. App Exit: Double-press back button on Home tab to exit
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
          return false; // PREVENT APP EXIT
        }

        // Allow app exit on second press
        return true;
      },
      child: widget.child,
    );
  }
}
