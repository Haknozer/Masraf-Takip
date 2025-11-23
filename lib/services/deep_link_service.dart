import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/group_provider.dart';
import '../utils/group_id_encoder.dart';
import '../widgets/common/error_snackbar.dart';
import 'package:flutter/material.dart';

/// Deep link servisi - Web URL ve custom scheme linklerini handle eder
class DeepLinkService {
  static final AppLinks _appLinks = AppLinks();

  /// Deep link stream provider (Riverpod için)
  static final deepLinkProvider = StreamProvider<Uri?>((ref) {
    return _appLinks.uriLinkStream;
  });

  /// Deep link stream'ini direkt al (initState'te kullanım için)
  static Stream<Uri?> getDeepLinkStream() {
    return _appLinks.uriLinkStream;
  }

  /// İlk açılışta gelen deep link'i al
  static Future<Uri?> getInitialLink() async {
    try {
      return await _appLinks.getInitialLink();
    } catch (e) {
      return null;
    }
  }

  /// Deep link'i parse et ve gruba katıl
  static Future<void> handleDeepLink(Uri uri, BuildContext context, WidgetRef ref) async {
    try {
      // Web URL formatı: https://masraftakipuygulamasi.web.app/join?groupId={encodedGroupId}
      // Sadece web URL'leri destekliyoruz (App Links)

      if (uri.path == '/join' || uri.pathSegments.contains('join')) {
        final groupIdParam = uri.queryParameters['groupId'];

        if (groupIdParam != null && groupIdParam.isNotEmpty) {
          // Şifrelenmiş grup ID'sini çöz
          final groupId = GroupIdEncoder.decodeGroupId(groupIdParam);

          if (groupId != null) {
            // Gruba katıl
            await ref.read(groupNotifierProvider.notifier).joinGroupById(groupId);

            if (context.mounted) {
              // ScaffoldMessenger hazır olana kadar bekle
              Future.delayed(const Duration(milliseconds: 300), () {
                if (context.mounted) {
                  ErrorSnackBar.showSuccess(context, 'Gruba başarıyla katıldınız!');
                }
              });
            }
          } else {
            if (context.mounted) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (context.mounted) {
                  ErrorSnackBar.show(context, 'Geçersiz grup linki.');
                }
              });
            }
          }
        } else {
          // Eski format desteği: code parametresi
          final codeParam = uri.queryParameters['code'];
          if (codeParam != null && codeParam.isNotEmpty) {
            // Invite code artık grup ID olduğu için direkt kullan
            await ref.read(groupNotifierProvider.notifier).joinGroupById(codeParam);

            if (context.mounted) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (context.mounted) {
                  ErrorSnackBar.showSuccess(context, 'Gruba başarıyla katıldınız!');
                }
              });
            }
          }
        }
      }
    } catch (e) {
      // Kullanıcı zaten üyeyse sessizce devam et (hata gösterme)
      if (e.toString().contains('InvalidOperationException') && e.toString().contains('Bu grubun zaten üyesisiniz')) {
        // Kullanıcı zaten üye, sessizce devam et
        return;
      }

      if (context.mounted) {
        String errorMessage = 'Gruba katılma hatası: ';
        if (e.toString().contains('NotFoundException')) {
          errorMessage = 'Grup bulunamadı.';
        } else {
          errorMessage = 'Gruba katılma hatası: ${e.toString()}';
        }

        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            ErrorSnackBar.show(context, errorMessage);
          }
        });
      }
    }
  }
}
