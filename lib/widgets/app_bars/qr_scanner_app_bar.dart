import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class QRScannerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const QRScannerAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'QR Kod Tara',
        style: TextStyle(color: AppColors.white),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

