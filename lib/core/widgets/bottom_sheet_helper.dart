import 'package:flutter/material.dart';

/// Helper to show a Cashew-style bottom sheet with a unified rounded look.
/// The drag handle is rendered automatically via [BottomSheetThemeData.showDragHandle]
/// set to true in [AppTheme] — no need to draw it manually here.
class BottomSheetHelper {
  BottomSheetHelper._();

  static Future<T?> openBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useRootNavigator: true,
      backgroundColor: backgroundColor,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
