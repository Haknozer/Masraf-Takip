import 'package:intl/intl.dart';

class AppDateUtils {
  // Tarih formatları
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String isoFormat = 'yyyy-MM-ddTHH:mm:ss';

  // Tarihi formatla
  static String formatDate(DateTime date) {
    return DateFormat(dateFormat).format(date);
  }

  // Saati formatla
  static String formatTime(DateTime time) {
    return DateFormat(timeFormat).format(time);
  }

  // Tarih ve saati formatla
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(dateTimeFormat).format(dateTime);
  }

  // ISO formatında tarih
  static String formatISO(DateTime dateTime) {
    return DateFormat(isoFormat).format(dateTime);
  }

  // Bugün mü?
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Dün mü?
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  // Bu hafta mı?
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // Bu ay mı?
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // Göreceli tarih (bugün, dün, 2 gün önce, vb.)
  static String getRelativeDate(DateTime date) {
    if (isToday(date)) {
      return 'Bugün';
    } else if (isYesterday(date)) {
      return 'Dün';
    } else {
      final difference = DateTime.now().difference(date).inDays;
      if (difference < 7) {
        return '$difference gün önce';
      } else if (difference < 30) {
        final weeks = (difference / 7).floor();
        return '$weeks hafta önce';
      } else if (difference < 365) {
        final months = (difference / 30).floor();
        return '$months ay önce';
      } else {
        final years = (difference / 365).floor();
        return '$years yıl önce';
      }
    }
  }

  // Ay adı
  static String getMonthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return months[month - 1];
  }

  // Gün adı
  static String getDayName(int weekday) {
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return days[weekday - 1];
  }
}
