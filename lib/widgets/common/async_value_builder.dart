import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AsyncValue için ortak builder widget'ı
/// Loading, error ve data state'lerini tekrarlamadan yönetmek için
class AsyncValueBuilder<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) dataBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error, StackTrace stackTrace)? errorBuilder;

  const AsyncValueBuilder({
    super.key,
    required this.value,
    required this.dataBuilder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) => dataBuilder(context, data),
      loading: () => loadingBuilder?.call(context) ?? const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => errorBuilder?.call(context, error, stackTrace) ?? Center(child: Text('Hata: $error')),
    );
  }
}
