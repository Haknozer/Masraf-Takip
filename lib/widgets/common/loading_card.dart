import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';

/// Loading state için card widget'ı
class LoadingCard extends StatelessWidget {
  final EdgeInsets? padding;

  const LoadingCard({
    super.key,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

