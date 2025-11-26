import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_spacing.dart';
import '../../providers/group_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/common/image_picker_widget.dart';
import '../../widgets/common/image_source_dialog.dart';
import '../../widgets/common/error_snackbar.dart';

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
  final _imagePicker = ImagePicker();

  XFile? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    if (!mounted) return;

    final ImageSource? source = await ImageSourceDialog.show(context, showRemoveOption: _selectedImage != null);

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, e);
      }
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // Resim varsa yükle (hata olsa bile devam et)
      if (_selectedImage != null) {
        final user = FirebaseService.currentUser;
        if (user != null) {
          try {
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final imagePath = 'groups/${user.uid}/group_$timestamp.jpg';
            imageUrl = await FirebaseService.uploadFile(path: imagePath, file: _selectedImage!);
            debugPrint('Resim başarıyla yüklendi: $imageUrl');
          } catch (uploadError) {
            debugPrint('Resim yükleme hatası (grup yine de oluşturulacak): $uploadError');
            // Resim yükleme hatası olsa bile grup oluşturulacak (resim olmadan)
            if (mounted) {
              ErrorSnackBar.showWarning(context, 'Resim yüklenemedi, grup resim olmadan oluşturuluyor.');
            }
          }
        }
      }

      await ref
          .read(groupNotifierProvider.notifier)
          .createGroup(_nameController.text.trim(), _descriptionController.text.trim(), imageUrl: imageUrl);

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Grup başarıyla oluşturuldu!');
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Grup oluşturma hatası detayı: $e');
        ErrorSnackBar.show(context, e);
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
          // Grup Resmi Seçme
          ImagePickerWidget(
            selectedImage: _selectedImage,
            onImageTap: _showImageSourceDialog,
            onRemoveImage: _selectedImage != null ? () => setState(() => _selectedImage = null) : null,
          ),
          const SizedBox(height: AppSpacing.sectionMargin),

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
          const SizedBox(height: AppSpacing.textSpacing * 2),

          // Grup Açıklaması
          CustomTextField(
            controller: _descriptionController,
            label: 'Açıklama (İsteğe bağlı)',
            hint: 'Grup hakkında kısa bilgi',
            prefixIcon: Icons.description,
            maxLines: 3,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.sectionMargin),

          // Grup Oluştur Butonu
          CustomButton(text: 'Grup Oluştur', onPressed: _isLoading ? null : _createGroup, isLoading: _isLoading),
        ],
      ),
    );
  }
}
