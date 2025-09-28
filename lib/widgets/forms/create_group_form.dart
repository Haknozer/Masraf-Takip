import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/group_provider.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/custom_button.dart';

class CreateGroupForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const CreateGroupForm({super.key, required this.onSuccess});

  @override
  ConsumerState<CreateGroupForm> createState() => _CreateGroupFormState();
}

class _CreateGroupFormState extends ConsumerState<CreateGroupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(groupNotifierProvider.notifier)
          .createGroup(_nameController.text.trim(), _descriptionController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grup başarıyla oluşturuldu!'), backgroundColor: AppColors.success),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grup oluşturma hatası: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Grup Adı
          CustomTextField(
            controller: _nameController,
            label: 'Grup Adı',
            hint: 'Örn: Ev Arkadaşları',
            prefixIcon: Icons.group,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Grup adı gereklidir';
              }
              if (value.length < 3) {
                return 'Grup adı en az 3 karakter olmalıdır';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // Grup Açıklaması
          CustomTextField(
            controller: _descriptionController,
            label: 'Açıklama (İsteğe bağlı)',
            hint: 'Grup hakkında kısa bilgi',
            prefixIcon: Icons.description,
            maxLines: 3,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 32),

          // Grup Oluştur Butonu
          CustomButton(text: 'Grup Oluştur', onPressed: _isLoading ? null : _createGroup, isLoading: _isLoading),
        ],
      ),
    );
  }
}
