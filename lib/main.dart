import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/firebase_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env dosyasını yükle
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ .env dosyası başarıyla yüklendi');
    // Debug: Key'lerin yüklendiğini kontrol et
    debugPrint('Android API Key: ${dotenv.env['FIREBASE_ANDROID_API_KEY']?.substring(0, 10)}...');
    debugPrint('iOS API Key: ${dotenv.env['FIREBASE_IOS_API_KEY']?.substring(0, 10)}...');
  } catch (e) {
    debugPrint('⚠️ .env dosyası yüklenemedi: $e');
    // .env dosyası yüklenemezse uygulama çalışmaya devam eder
    // Ancak Firebase key'leri bulunamayacak, bu durumda hata verecektir
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Firebase'i başlat
  try {
    await FirebaseService.initialize();
    debugPrint('✅ Firebase başarıyla başlatıldı');
  } catch (e, stackTrace) {
    debugPrint('❌ Firebase başlatılamadı: $e');
    debugPrint('Stack trace: $stackTrace');
    // Firebase başlatılamazsa uygulama çalışmaya devam eder ama auth çalışmaz
  }

  runApp(const ProviderScope(child: MyApp()));
}
