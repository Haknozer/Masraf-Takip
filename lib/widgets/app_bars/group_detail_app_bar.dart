import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/group_model.dart';
import '../../screens/groups/edit_group_page.dart';
import '../../screens/home/home_page.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/pdf_report_service.dart';

class GroupDetailAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String groupId;
  final GroupModel? group; // Opsiyonel: group objesi varsa ondan id al

  const GroupDetailAppBar({super.key, required this.groupId, this.group});

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, String effectiveGroupId) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Grup Sil'),
            content: const Text('Bu grubu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('İptal')),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext); // Dialog'u kapat
                  await _deleteGroup(context, ref, effectiveGroupId);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Sil'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteGroup(BuildContext context, WidgetRef ref, String effectiveGroupId) async {
    try {
      // Grup silme işlemi
      await ref.read(groupNotifierProvider.notifier).deleteGroup(effectiveGroupId);

      // Başarılı olduysa ana sayfaya yönlendir
      if (context.mounted) {
        // Önce başarı mesajını göster
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Grup başarıyla silindi!'), backgroundColor: AppColors.success));

        // Ana sayfaya yönlendir - tüm route stack'ini temizle
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomePage()), (route) => false);
      }
    } catch (e) {
      // Hata durumunda mesaj göster
      if (context.mounted) {
        String errorMessage = 'Grup silme hatası: ';
        if (e.toString().contains('ForbiddenException')) {
          errorMessage = 'Bu işlem için yetkiniz yok.';
        } else if (e.toString().contains('NotFoundException')) {
          errorMessage = 'Grup bulunamadı.';
        } else {
          errorMessage = 'Grup silme hatası: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error, duration: const Duration(seconds: 5)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // GroupId'yi belirle: önce group objesinden, yoksa parametreden
    final effectiveGroupId = group?.id.isNotEmpty == true ? group!.id : groupId;

    // Kullanıcının admin olup olmadığını kontrol et
    final isAdmin = group != null ? group!.isGroupAdmin(ref.read(currentUserProvider)?.uid ?? '') : false;

    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      title: const Text('Grup Detayı'),
      elevation: 0,
      actions: [
        if (group != null)
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Grup raporunu PDF olarak oluştur',
            onPressed: () => PdfReportService.generateGroupSummary(context: context, group: group!),
          ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            if (effectiveGroupId.isEmpty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Grup ID bulunamadı. Lütfen tekrar deneyin.')));
              return;
            }
            Navigator.push(context, MaterialPageRoute(builder: (context) => EditGroupPage(groupId: effectiveGroupId)));
          },
        ),
        // Sadece admin için silme butonu göster
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              if (effectiveGroupId.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Grup ID bulunamadı. Lütfen tekrar deneyin.')));
                return;
              }
              _showDeleteConfirmationDialog(context, ref, effectiveGroupId);
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
