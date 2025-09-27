class AppConstants {
  // Uygulama Bilgileri
  static const String appName = 'Masraf Takip Uygulaması';
  static const String appVersion = '1.0.0';

  // Firebase Koleksiyonları
  static const String usersCollection = 'users';
  static const String groupsCollection = 'groups';
  static const String expensesCollection = 'expenses';
  static const String membersCollection = 'members';

  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String expenseImagesPath = 'expense_images';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxGroupNameLength = 50;
  static const int maxExpenseDescriptionLength = 200;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const double defaultElevation = 2.0;
}
