import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../buttons/type_selection_button.dart';

/// Dağılım tipi enum
enum DistributionType {
  equal, // Eşit dağılım
  manual, // Manuel dağılım
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
              child: TypeSelectionButton(
                title: 'Eşit Dağılım',
                icon: Icons.equalizer,
                isSelected: selectedType == DistributionType.equal,
                onTap: () => onTypeSelected(DistributionType.equal),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TypeSelectionButton(
                title: 'Manuel Dağılım',
                icon: Icons.edit,
                isSelected: selectedType == DistributionType.manual,
                onTap: () => onTypeSelected(DistributionType.manual),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

