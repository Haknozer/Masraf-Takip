import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_page.dart';
import 'widgets/navigation/main_navigation.dart';
import 'services/deep_link_service.dart';
import 'constants/app_colors.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<Uri?>? _deepLinkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  Uri? _lastHandledUri; // Son handle edilen URI'yi sakla

  @override
  void initState() {
    super.initState();
    // MaterialApp build edildikten sonra deep link'leri handle et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialDeepLink();
      _listenToDeepLinks();
    });
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  /// İlk açılışta gelen deep link'i handle et
  Future<void> _handleInitialDeepLink() async {
    final uri = await DeepLinkService.getInitialLink();
    if (uri != null && mounted && uri != _lastHandledUri) {
      _lastHandledUri = uri;
      // Navigator hazır olduğunda handle et
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _navigatorKey.currentContext != null) {
          DeepLinkService.handleDeepLink(uri, _navigatorKey.currentContext!, ref);
        }
      });
    }
  }

  /// Deep link stream'ini dinle
  void _listenToDeepLinks() {
    // Stream'i direkt dinle
    final deepLinkStream = DeepLinkService.getDeepLinkStream();
    _deepLinkSubscription = deepLinkStream.listen((uri) {
      // Aynı URI'yi tekrar handle etme
      if (uri != null && uri != _lastHandledUri && mounted && _navigatorKey.currentContext != null) {
        _lastHandledUri = uri;
        DeepLinkService.handleDeepLink(uri, _navigatorKey.currentContext!, ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Masraf Takip Uygulaması',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const MainNavigation();
          } else {
            return const LoginPage();
          }
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) => const LoginPage(),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: Colors.white,
        surfaceVariant: AppColors.greyLight,
        onSurfaceVariant: AppColors.textSecondary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.cardBackground,
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: AppColors.textPrimary),
        displayMedium: TextStyle(color: AppColors.textPrimary),
        displaySmall: TextStyle(color: AppColors.textPrimary),
        headlineLarge: TextStyle(color: AppColors.textPrimary),
        headlineMedium: TextStyle(color: AppColors.textPrimary),
        headlineSmall: TextStyle(color: AppColors.textPrimary),
        titleLarge: TextStyle(color: AppColors.textPrimary),
        titleMedium: TextStyle(color: AppColors.textPrimary),
        titleSmall: TextStyle(color: AppColors.textPrimary),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        bodySmall: TextStyle(color: AppColors.textSecondary),
        labelLarge: TextStyle(color: AppColors.textPrimary),
        labelMedium: TextStyle(color: AppColors.textSecondary),
        labelSmall: TextStyle(color: AppColors.textHint),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.greyLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.greyLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.greyLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      dividerColor: AppColors.greyLight,
      dividerTheme: DividerThemeData(
        color: AppColors.greyLight,
        thickness: 1,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.copyWith(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: const Color(0xFFE0E0E0),
        onBackground: const Color(0xFFE0E0E0),
        onError: Colors.white,
        surfaceVariant: const Color(0xFF2C2C2C),
        onSurfaceVariant: const Color(0xFFB0B0B0),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: const Color(0xFFE0E0E0),
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: TextTheme(
        displayLarge: const TextStyle(color: Color(0xFFE0E0E0)),
        displayMedium: const TextStyle(color: Color(0xFFE0E0E0)),
        displaySmall: const TextStyle(color: Color(0xFFE0E0E0)),
        headlineLarge: const TextStyle(color: Color(0xFFE0E0E0)),
        headlineMedium: const TextStyle(color: Color(0xFFE0E0E0)),
        headlineSmall: const TextStyle(color: Color(0xFFE0E0E0)),
        titleLarge: const TextStyle(color: Color(0xFFE0E0E0)),
        titleMedium: const TextStyle(color: Color(0xFFE0E0E0)),
        titleSmall: const TextStyle(color: Color(0xFFE0E0E0)),
        bodyLarge: const TextStyle(color: Color(0xFFE0E0E0)),
        bodyMedium: const TextStyle(color: Color(0xFFE0E0E0)),
        bodySmall: const TextStyle(color: Color(0xFFB0B0B0)),
        labelLarge: const TextStyle(color: Color(0xFFE0E0E0)),
        labelMedium: const TextStyle(color: Color(0xFFB0B0B0)),
        labelSmall: const TextStyle(color: Color(0xFF808080)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
      ),
      dividerColor: const Color(0xFF2C2C2C),
      dividerTheme: DividerThemeData(
        color: const Color(0xFF2C2C2C),
        thickness: 1,
      ),
    );
  }
}
