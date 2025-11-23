import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_page.dart';
import 'screens/home/home_page.dart';
import 'services/deep_link_service.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<Uri?>? _deepLinkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

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
    if (uri != null && mounted) {
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
      if (uri != null && mounted && _navigatorKey.currentContext != null) {
        DeepLinkService.handleDeepLink(uri, _navigatorKey.currentContext!, ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Masraf Takip Uygulaması',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary), useMaterial3: true),
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) => const LoginPage(),
      ),
    );
  }
}
