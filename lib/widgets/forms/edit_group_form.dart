import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_spacing.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/forms/custom_text_field.dart';
import '../../widgets/forms/custom_button.dart';
import '../../widgets/common/image_picker_widget.dart';
import '../../widgets/common/image_source_dialog.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/async_value_builder.dart';

class EditGroupForm extends ConsumerStatefulWidget {
  final String groupId;
  final VoidCallback onSuccess;

  const EditGroupForm({super.key, required this.groupId, required this.onSuccess});

  @override
  ConsumerState<EditGroupForm> createState() => _EditGroupFormState();
}

// Debug için
extension EditGroupFormDebug on EditGroupForm {
  String get debugGroupId => groupId;
}

class _EditGroupFormState extends ConsumerState<EditGroupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  XFile? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    print('EditGroupForm initState - GroupId: ${widget.groupId}');
    if (widget.groupId.isEmpty) {
      print('UYARI: EditGroupForm\'a boş groupId geçirildi!');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    if (!mounted) return;

    final ImageSource? source = await ImageSourceDialog.show(
      context,
      showRemoveOption: _selectedImage != null || _currentImageUrl != null,
    );

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
          _currentImageUrl = null; // Yeni resim seçildiğinde mevcut URL'i temizle
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, e);
      }
    }
  }

  Future<void> _updateGroup() async {
    if (!_formKey.currentState!.validate()) return;

    // GroupId'yi başta kontrol et ve sakla
    final currentGroupId = widget.groupId;
    print('_updateGroup başladı - GroupId: $currentGroupId, isEmpty: ${currentGroupId.isEmpty}');

    if (currentGroupId.isEmpty) {
      if (mounted) {
        ErrorSnackBar.show(context, 'Grup ID geçersiz. Lütfen sayfayı yenileyin.');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _currentImageUrl; // Mevcut resmi varsayılan olarak kullan

      // Yeni resim seçildiyse yükle
      if (_selectedImage != null) {
        final user = FirebaseService.currentUser;
        if (user != null) {
          try {
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final imagePath = 'groups/${user.uid}/group_$timestamp.jpg';
            imageUrl = await FirebaseService.uploadFile(path: imagePath, file: _selectedImage!);
            print('Resim başarıyla yüklendi: $imageUrl');
          } catch (uploadError) {
            print('Resim yükleme hatası (grup yine de güncellenecek): $uploadError');
            if (mounted) {
              ErrorSnackBar.showWarning(context, 'Resim yüklenemedi, grup resim olmadan güncelleniyor.');
            }
            // Resim yükleme hatası olsa bile mevcut resmi kullan veya null yap
            imageUrl = _currentImageUrl;
          }
        }
      } else if (_currentImageUrl == null && _selectedImage == null) {
        // Resim kaldırıldıysa null gönder
        imageUrl = null;
      }

      print('Grup güncelleme çağrılıyor - GroupId: $currentGroupId');

      await ref
          .read(groupNotifierProvider.notifier)
          .updateGroup(
            currentGroupId,
            _nameController.text.trim(),
            _descriptionController.text.trim(),
            imageUrl: imageUrl,
          );

      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Grup başarıyla güncellendi!');
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        print('Grup güncelleme hatası detayı: $e');
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
    final groupState = ref.watch(groupProvider(widget.groupId));

    return AsyncValueBuilder<GroupModel?>(
      value: groupState,
      dataBuilder: (context, group) {
        if (group == null) {
          return const Center(child: Text('Grup bulunamadı'));
        }

        // İlk yüklemede formu doldur
        if (!_isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _nameController.text = group.name;
            _descriptionController.text = group.description;
            _currentImageUrl = group.imageUrl;
            setState(() {
              _isInitialized = true;
            });
          });
        }

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grup Resmi
              ImagePickerWidget(
                selectedImage: _selectedImage,
                currentImageUrl: _currentImageUrl,
                onImageTap: _showImageSourceDialog,
                onRemoveImage:
                    (_selectedImage != null || _currentImageUrl != null)
                        ? () => setState(() {
                          _selectedImage = null;
                          _currentImageUrl = null;
                        })
                        : null,
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

              // Güncelle Butonu
              CustomButton(text: 'Güncelle', onPressed: _isLoading ? null : _updateGroup, isLoading: _isLoading),
            ],
          ),
        );
      },
    );
  }
}
