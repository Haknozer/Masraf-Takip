import 'dart:convert';

/// Grup ID'sini şifrelemek ve çözmek için utility class
/// Basit Base64 encoding kullanıyor (güvenlik için daha güçlü şifreleme eklenebilir)
class GroupIdEncoder {
  /// Grup ID'sini şifrele
  /// Format: "GROUP_ID:{groupId}" -> Base64 encoded
  static String encodeGroupId(String groupId) {
    if (groupId.isEmpty) {
      throw ArgumentError('Grup ID boş olamaz');
    }

    // Basit encoding: "GROUP_ID:{groupId}" formatında encode et
    final data = 'GROUP_ID:$groupId';
    final bytes = utf8.encode(data);
    return base64Encode(bytes);
  }

  /// Şifrelenmiş grup ID'sini çöz
  /// Base64 decode edip "GROUP_ID:" prefix'ini kontrol eder
  static String? decodeGroupId(String encodedId) {
    try {
      final bytes = base64Decode(encodedId);
      final decoded = utf8.decode(bytes);

      // Format kontrolü: "GROUP_ID:{groupId}" formatında olmalı
      if (decoded.startsWith('GROUP_ID:')) {
        return decoded.substring('GROUP_ID:'.length);
      }

      return null;
    } catch (e) {
      // Decode hatası - geçersiz format
      return null;
    }
  }

  /// String'in geçerli bir şifrelenmiş grup ID'si olup olmadığını kontrol et
  static bool isValidEncodedGroupId(String encodedId) {
    return decodeGroupId(encodedId) != null;
  }
}
