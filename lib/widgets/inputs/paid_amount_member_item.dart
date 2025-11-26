import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../widgets/forms/custom_text_field.dart';

class PaidAmountMemberItem extends StatefulWidget {
  final UserModel member;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const PaidAmountMemberItem({super.key, required this.member, required this.controller, required this.onChanged});

  @override
  State<PaidAmountMemberItem> createState() => _PaidAmountMemberItemState();
}

class _PaidAmountMemberItemState extends State<PaidAmountMemberItem> {
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            backgroundImage: widget.member.photoUrl != null ? NetworkImage(widget.member.photoUrl!) : null,
            child:
                widget.member.photoUrl == null
                    ? Text(widget.member.displayName.isNotEmpty ? widget.member.displayName[0].toUpperCase() : '?')
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.member.displayName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  widget.member.email,
                  style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: CustomTextField(
              controller: widget.controller,
              focusNode: _focusNode,
              label: 'Ödenen',
              hint: '0.00',
              prefixIcon: Icons.currency_lira,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: widget.onChanged,
              onTap: () {
                // Tıklandığında da tüm metni seç
                widget.controller.selection = TextSelection(baseOffset: 0, extentOffset: widget.controller.text.length);
              },
            ),
          ),
        ],
      ),
    );
  }
}
