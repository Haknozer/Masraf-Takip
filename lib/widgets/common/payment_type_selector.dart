import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../buttons/type_selection_button.dart';

/// Ödeme tipi enum
enum PaymentType {
  fullPayment, // Tamamını ödeyen
  sharedPayment, // Paylaşımlı ödeme
}

/// Ödeme tipi seçim widget'ı
class PaymentTypeSelector extends StatelessWidget {
  final PaymentType? selectedType;
  final Function(PaymentType type) onTypeSelected;

  const PaymentTypeSelector({super.key, this.selectedType, required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ödeme Tipi', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.textSpacing),
        Row(
          children: [
            Expanded(
              child: TypeSelectionButton(
                title: 'Tamamını Ödeyen',
                icon: Icons.person,
                isSelected: selectedType == PaymentType.fullPayment,
                onTap: () => onTypeSelected(PaymentType.fullPayment),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TypeSelectionButton(
                title: 'Paylaşımlı',
                icon: Icons.people,
                isSelected: selectedType == PaymentType.sharedPayment,
                onTap: () => onTypeSelected(PaymentType.sharedPayment),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
