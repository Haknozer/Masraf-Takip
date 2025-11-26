import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';
import '../../models/user_model.dart';
import '../../widgets/forms/custom_text_field.dart';

class ManualDistributionMemberInput extends StatefulWidget {
  final UserModel member;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const ManualDistributionMemberInput({
    super.key,
    required this.member,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<ManualDistributionMemberInput> createState() => _ManualDistributionMemberInputState();
}

class _ManualDistributionMemberInputState extends State<ManualDistributionMemberInput> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Focus alındığında tüm metni seç
      widget.controller.selection = TextSelection(baseOffset: 0, extentOffset: widget.controller.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.textSpacing * 2),
      child: CustomTextField(
        controller: widget.controller,
        focusNode: _focusNode,
        label: widget.member.displayName,
        hint: '0.00',
        prefixIcon: Icons.person,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: widget.onChanged,
        onTap: () {
          // Tıklandığında da tüm metni seç
          widget.controller.selection = TextSelection(baseOffset: 0, extentOffset: widget.controller.text.length);
        },
        validator: (value) {
          final amount = double.tryParse(value ?? '') ?? 0.0;
          if (amount < 0) {
            return 'Negatif olamaz';
          }
          return null;
        },
      ),
    );
  }
}
