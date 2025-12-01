# expense_tracker_app

Masraf takip uygulaması - Grup masraflarını takip etmek için geliştirilmiş Flutter uygulaması

## Kurulum

### 1. Bağımlılıkları Yükleyin

```bash
flutter pub get
```

### 2. Firebase Yapılandırması

Bu proje Firebase kullanmaktadır. Uygulamayı çalıştırmak için Firebase API key'lerinizi yapılandırmanız gerekmektedir.

#### Adımlar:

1. `.env.example` dosyasını `.env` olarak kopyalayın:
   ```bash
   cp .env.example .env
   ```
   Windows'ta:
   ```cmd
   copy .env.example .env
   ```

2. `.env` dosyasını açın ve Firebase Console'dan aldığınız kendi API key'lerinizi girin:
   - `FIREBASE_ANDROID_API_KEY`: Android için Firebase API Key
   - `FIREBASE_IOS_API_KEY`: iOS için Firebase API Key
   - Diğer Firebase yapılandırma değerleri (Project ID, App ID, vb.)

3. Firebase yapılandırma dosyalarını kopyalayın:
   - Android: `google-services.json.example` dosyasını `google-services.json` olarak kopyalayın ve Firebase Console'dan indirdiğiniz gerçek dosya ile değiştirin
   - iOS: `GoogleService-Info.plist.example` dosyasını `GoogleService-Info.plist` olarak kopyalayın ve Firebase Console'dan indirdiğiniz gerçek dosya ile değiştirin

4. **ÖNEMLİ**: `.env`, `google-services.json` ve `GoogleService-Info.plist` dosyaları `.gitignore` içinde olduğu için Git'e yüklenmeyecektir. Bu sayede API key'leriniz güvende kalır.

### 3. Uygulamayı Çalıştırın

```bash
flutter run
```

## Güvenlik Notu

⚠️ **ÖNEMLİ**: Eğer Firebase API key'leriniz GitHub'a yüklendiyse, derhal Firebase Console'dan bu key'leri iptal edin (Revoke) ve yeni key'ler oluşturun. GitHub'da bir saniye bile kalan bir key, botlar tarafından taranır ve kopyalanır.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
