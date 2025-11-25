import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';

/// Ortak sayfa yapısı için base widget
/// Scaffold, SafeArea, SingleChildScrollView yapısını tekrarlamadan kullanmak için
class BasePage extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final bool useSafeArea;
  final bool useScrollView;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const BasePage({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.useSafeArea = true,
    this.useScrollView = true,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    if (useScrollView) {
      content = SingleChildScrollView(
        padding: padding ?? const EdgeInsets.all(AppSpacing.sectionPadding),
        child: content,
      );
    } else if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      appBar: appBar,
      body: content,
      floatingActionButton: floatingActionButton,
    );
  }
}
