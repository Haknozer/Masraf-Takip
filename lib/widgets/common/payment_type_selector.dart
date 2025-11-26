import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';

/// Ödeme tipi enum
enum PaymentType {
  fullPayment, // Tamamını ödeyen
  sharedPayment, // Paylaşımlı ödeme
}

/// Dağılım tipi enum
enum DistributionType {
  equal, // Eşit dağılım
  manual, // Manuel dağılım
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
              child: _buildTypeButton(
                context: context,
                title: 'Tamamını Ödeyen',
                icon: Icons.person,
                type: PaymentType.fullPayment,
                isSelected: selectedType == PaymentType.fullPayment,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeButton(
                context: context,
                title: 'Paylaşımlı',
                icon: Icons.people,
                type: PaymentType.sharedPayment,
                isSelected: selectedType == PaymentType.sharedPayment,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required PaymentType type,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onTypeSelected(type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : colorScheme.surfaceContainerHighest,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : colorScheme.onSurfaceVariant, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.primary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dağılım tipi seçim widget'ı
class DistributionTypeSelector extends StatelessWidget {
  final DistributionType? selectedType;
  final Function(DistributionType type) onTypeSelected;

  const DistributionTypeSelector({super.key, this.selectedType, required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dağılım Tipi', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.textSpacing),
        Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                context: context,
                title: 'Eşit Dağılım',
                icon: Icons.equalizer,
                type: DistributionType.equal,
                isSelected: selectedType == DistributionType.equal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeButton(
                context: context,
                title: 'Manuel Dağılım',
                icon: Icons.edit,
                type: DistributionType.manual,
                isSelected: selectedType == DistributionType.manual,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required DistributionType type,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onTypeSelected(type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : colorScheme.surfaceContainerHighest,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.primary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
