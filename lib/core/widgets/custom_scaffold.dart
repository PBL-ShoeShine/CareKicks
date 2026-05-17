import 'package:flutter/material.dart';

/// A custom wrapper for [Scaffold] that automatically handles [SafeArea].
/// This ensures that the application's UI is protected from status bars,
/// notches, and other system intrusions without repeating [SafeArea] in every page.
class CustomScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool useSafeArea;
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final bool safeAreaLeft;
  final bool safeAreaRight;

  const CustomScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.useSafeArea = true,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
    this.safeAreaLeft = true,
    this.safeAreaRight = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    // Wrap body with SafeArea if requested.
    // Note: Scaffold's appBar already handles the top safe area.
    // If an appBar is provided, we might want to disable top safe area for the body
    // to avoid double padding, depending on the UI design.
    // However, usually body starts below the AppBar.
    if (useSafeArea) {
      content = SafeArea(
        top: appBar == null ? safeAreaTop : false, // Only apply top safe area if there's no AppBar
        bottom: safeAreaBottom,
        left: safeAreaLeft,
        right: safeAreaRight,
        child: content,
      );
    }

    return Scaffold(
      appBar: appBar,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
