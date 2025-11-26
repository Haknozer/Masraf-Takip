import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_text_styles.dart';

class AddMemberQrTab extends StatelessWidget {
  final String inviteCode;

  const AddMemberQrTab({super.key, required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // QR Kod
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: QrImageView(
            data: inviteCode,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
        ),
        const SizedBox(height: AppSpacing.sectionMargin),
        Text('QR kodu taratın', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'QR kod okutulduğunda kullanıcı direkt gruba katılacak',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
