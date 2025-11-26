# Log Service Kullanım Kılavuzu

## Kurulum

1. `pubspec.yaml` dosyasına `logger: ^2.4.0` eklenmiştir.
2. `lib/services/log_service.dart` oluşturulmuştur.

## Kullanım

### 1. Debug Log (Geliştirme için)
```dart
LogService.debug('Kullanıcı profili yükleniyor...');
LogService.debug('API Response', response);
```

### 2. Info Log (Bilgilendirme)
```dart
LogService.info('Masraf başarıyla eklendi', expense.toJson());
LogService.info('Kullanıcı giriş yaptı: ${user.email}');
```

### 3. Warning Log (Uyarı)
```dart
LogService.warning('Kullanıcı profil fotoğrafı yüklenemedi');
LogService.warning('Ağ bağlantısı yavaş');
```

### 4. Error Log (Hata - Firebase'e de kaydedilir)
```dart
try {
  await someOperation();
} catch (e, stackTrace) {
  LogService.error('İşlem başarısız', e, stackTrace);
}
```

### 5. Fatal Log (Kritik Hata)
```dart
try {
  await criticalOperation();
} catch (e, stackTrace) {
  LogService.fatal('Kritik işlem başarısız - Uygulama durabilir', e, stackTrace);
}
```

### 6. User Action Log (Kullanıcı Davranışı)
```dart
LogService.logUserAction('expense_created', data: {
  'amount': expense.amount,
  'category': expense.category,
  'groupId': expense.groupId,
});

LogService.logUserAction('button_clicked', data: {'button': 'add_expense'});
```

### 7. API Call Log
```dart
try {
  final response = await api.getExpenses();
  LogService.logApiCall('/expenses', method: 'GET', response: response);
} catch (e) {
  LogService.logApiCall('/expenses', method: 'GET', error: e);
}
```

### 8. Navigation Log
```dart
LogService.logNavigation('HomePage', 'GroupDetailPage');
```

## Firebase'de Loglar

Production modda kritik hatalar otomatik olarak Firebase Firestore'da şu koleksiyonlarda saklanır:

### app_logs koleksiyonu
```json
{
  "level": "ERROR",
  "message": "Masraf eklenemedi",
  "error": "FirebaseException: ...",
  "stackTrace": "...",
  "userId": "user123",
  "userEmail": "user@example.com",
  "timestamp": "2024-11-26T10:30:00Z",
  "platform": "TargetPlatform.android"
}
```

### user_actions koleksiyonu
```json
{
  "action": "expense_created",
  "data": {
    "amount": 100.0,
    "category": "food"
  },
  "userId": "user123",
  "userEmail": "user@example.com",
  "timestamp": "2024-11-26T10:30:00Z",
  "platform": "TargetPlatform.android"
}
```

## Önerilen Kullanım Yerleri

### 1. Authentication İşlemleri
```dart
// lib/providers/auth_provider.dart
Future<void> signIn(String email, String password) async {
  try {
    LogService.info('Giriş denemesi: $email');
    final credential = await FirebaseService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    LogService.info('Giriş başarılı: ${credential.user?.uid}');
    LogService.logUserAction('user_login', data: {'email': email});
  } catch (e, stackTrace) {
    LogService.error('Giriş hatası: $email', e, stackTrace);
    rethrow;
  }
}
```

### 2. Expense İşlemleri
```dart
// lib/providers/expense_provider.dart
Future<void> addExpense(...) async {
  try {
    LogService.info('Masraf ekleniyor: $description');
    await FirebaseService.firestore.collection('expenses').add(data);
    LogService.info('Masraf eklendi: ${expense.id}');
    LogService.logUserAction('expense_created', data: {
      'amount': amount,
      'category': category,
      'groupId': groupId,
    });
  } catch (e, stackTrace) {
    LogService.error('Masraf eklenemedi', e, stackTrace);
    rethrow;
  }
}
```

### 3. Navigasyon
```dart
// Her sayfa geçişinde
Navigator.push(context, route).then((_) {
  LogService.logNavigation(currentPage, targetPage);
});
```

### 4. Kritik İşlemler
```dart
// Ödeme işlemleri, settlement vb.
try {
  await processPayment();
} catch (e, stackTrace) {
  LogService.fatal('Ödeme işlemi başarısız', e, stackTrace);
}
```

## Firebase Console'da Log Görüntüleme

1. Firebase Console → Firestore Database
2. `app_logs` koleksiyonunu açın
3. Filtreleme yapın:
   - `level == ERROR` → Sadece hataları gör
   - `userId == "user123"` → Belirli kullanıcının loglarını gör
   - `timestamp` → Tarih aralığında filtrele

## Production vs Development

- **Development**: Tüm loglar console'da görünür (renkli, emoji'li)
- **Production**: Sadece Error ve Fatal loglar Firebase'e kaydedilir

## Performans

- Console logları maliyetsizdir
- Firebase logları sadece kritik durumlarda yazılır
- User action logları opsiyoneldir (analytics için)

