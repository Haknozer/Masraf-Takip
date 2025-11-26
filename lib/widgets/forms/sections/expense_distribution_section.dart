import 'package:flutter/material.dart';
import '../../../constants/app_spacing.dart';
import '../../common/member_selector.dart';
import '../../selectors/distribution_type_selector.dart';
import '../../common/manual_distribution_input.dart';

class ExpenseDistributionSection extends StatelessWidget {
  final List<String> selectedMemberIds;
  final List<String> availableMemberIds;
  final ValueChanged<List<String>> onMembersChanged;
  final DistributionType? distributionType;
  final ValueChanged<DistributionType> onDistributionTypeChanged;
  final Map<String, double> manualAmounts;
  final ValueChanged<Map<String, double>> onManualAmountsChanged;
  final double totalAmount;

  const ExpenseDistributionSection({
    super.key,
    required this.selectedMemberIds,
    required this.availableMemberIds,
    required this.onMembersChanged,
    required this.distributionType,
    required this.onDistributionTypeChanged,
    required this.manualAmounts,
    required this.onManualAmountsChanged,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Harcamaya dahil edilecek kişiler
        MemberSelector(
          selectedMemberIds: selectedMemberIds,
          availableMemberIds: availableMemberIds,
          onMembersChanged: (memberIds) {
            onMembersChanged(memberIds);

            // Manuel dağılım varsa update et
            if (distributionType == DistributionType.manual) {
              final newManualAmounts = Map<String, double>.from(manualAmounts);

              // Yeni eklenenler için 0.0 ekle
              for (final memberId in memberIds) {
                if (!newManualAmounts.containsKey(memberId)) {
                  newManualAmounts[memberId] = 0.0;
                }
              }

              // Çıkarılanları sil
              newManualAmounts.removeWhere((key, value) => !memberIds.contains(key));

              onManualAmountsChanged(newManualAmounts);
            }
          },
        ),
        const SizedBox(height: AppSpacing.sectionMargin),

        // Dağılım Tipi
        DistributionTypeSelector(
          selectedType: distributionType,
          onTypeSelected: (type) {
            onDistributionTypeChanged(type);

            if (type == DistributionType.equal) {
              onManualAmountsChanged({});
            } else {
              // Manuel dağılım için başlangıç değerleri
              final perPerson = selectedMemberIds.isNotEmpty ? totalAmount / selectedMemberIds.length : 0.0;
              final newManualAmounts = {for (final memberId in selectedMemberIds) memberId: perPerson};
              onManualAmountsChanged(newManualAmounts);
            }
          },
        ),
        const SizedBox(height: AppSpacing.sectionMargin),

        // Manuel dağılım input'u
        if (distributionType == DistributionType.manual && selectedMemberIds.isNotEmpty)
          ManualDistributionInput(
            memberIds: selectedMemberIds,
            totalAmount: totalAmount,
            manualAmounts: manualAmounts,
            onChanged: onManualAmountsChanged,
          ),
      ],
    );
  }
}
