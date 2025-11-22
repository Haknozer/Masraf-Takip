import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/forms/custom_button.dart';
import 'error_snackbar.dart';

/// Kopyalama işlemi için ortak buton widget'ı
class CopyButton extends StatelessWidget {
  final String text;
  final String successMessage;
  final String? buttonLabel;
  final IconData? icon;
  final bool showAsIconButton;

  const CopyButton({
    super.key,
    required this.text,
    this.successMessage = 'Kopyalandı!',
    this.buttonLabel,
    this.icon,
    this.showAsIconButton = false,
  });

  /// Icon button olarak göster
  const CopyButton.icon({
    super.key,
    required this.text,
    this.successMessage = 'Kopyalandı!',
    this.icon,
  })  : buttonLabel = null,
        showAsIconButton = true;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ErrorSnackBar.showSuccess(context, successMessage);
  }

  @override
  Widget build(BuildContext context) {
    if (showAsIconButton) {
      return IconButton(
        icon: Icon(icon ?? Icons.copy, size: 20),
        onPressed: () => _copyToClipboard(context),
      );
    }

    return CustomButton(
      text: buttonLabel ?? 'Kopyala',
      icon: icon ?? Icons.copy,
      onPressed: () => _copyToClipboard(context),
    );
  }
}

