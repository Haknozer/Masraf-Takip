import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../constants/app_colors.dart';
import '../../providers/group_provider.dart';
import '../../services/firebase_service.dart';
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

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galeriden Seç'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Kameradan Çek'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                if (_selectedImage != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: AppColors.error),
                    title: const Text('Resmi Kaldır', style: TextStyle(color: AppColors.error)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedImage = null);
                    },
                  ),
              ],
            ),
          ),
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
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim seçme hatası: ${e.toString()}'), backgroundColor: AppColors.error),
        );
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
            print('Resim başarıyla yüklendi: $imageUrl');
          } catch (uploadError) {
            print('Resim yükleme hatası (grup yine de oluşturulacak): $uploadError');
            // Resim yükleme hatası olsa bile grup oluşturulacak (resim olmadan)
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Resim yüklenemedi, grup resim olmadan oluşturuluyor.'),
                  backgroundColor: AppColors.warning,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }
      }

      await ref
          .read(groupNotifierProvider.notifier)
          .createGroup(_nameController.text.trim(), _descriptionController.text.trim(), imageUrl: imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grup başarıyla oluşturuldu!'), backgroundColor: AppColors.success),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Grup oluşturma hatası: ';

        // Middleware exception kontrolü
        if (e.toString().contains('UnauthorizedException')) {
          errorMessage = 'Giriş yapmanız gerekiyor. Lütfen giriş yapıp tekrar deneyin.';
        } else if (e.toString().contains('ForbiddenException')) {
          errorMessage = 'Bu işlem için yetkiniz yok.';
        } else if (e.toString().contains('NotFoundException')) {
          errorMessage = 'Kullanıcı dokümanı bulunamadı. Lütfen tekrar giriş yapın.';
        } else if (e is FirebaseException) {
          if (e.code == 'permission-denied' || e.code == '-13021') {
            errorMessage =
                'Resim yükleme izni yok. Lütfen Firebase Console\'da Storage Security Rules\'ı kontrol edin.';
          } else if (e.code == 'unauthorized') {
            errorMessage = 'Giriş yapmanız gerekiyor.';
          } else {
            errorMessage = 'Firebase hatası: ${e.message ?? e.code}';
          }
        } else {
          errorMessage = 'Grup oluşturma hatası: ${e.toString()}';
        }

        print('Grup oluşturma hatası detayı: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error, duration: const Duration(seconds: 5)),
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
          // Grup Resmi Seçme
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grey, width: 2, strokeAlign: BorderSide.strokeAlignInside),
                    ),
                    child:
                        _selectedImage != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                            )
                            : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 40, color: AppColors.textSecondary),
                                const SizedBox(height: 8),
                                Text('Resim Ekle', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                  ),
                ),
                if (_selectedImage != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: AppColors.white, size: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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
