import 'package:ecom_/features/auth/screens/forgetpassword_screen.dart';
import 'package:ecom_/features/auth/screens/splash_screen.dart';
import 'package:ecom_/firebase_options.dart';
import 'package:ecom_/providers/admin_product_provider.dart';
import 'package:ecom_/providers/app_product_provider.dart';
import 'package:ecom_/providers/cart_provider.dart';
import 'package:ecom_/providers/notification_provider.dart';
import 'package:ecom_/providers/order_provider_app.dart';
import 'package:ecom_/providers/profile_provider.dart';
import 'package:ecom_/providers/theme_provider.dart';
import 'package:ecom_/providers/wishlist_provider.dart';
import 'package:ecom_/services/fcm_service.dart';
import 'package:ecom_/services/local_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/screens/home_screen.dart';

/// ✅ BACKGROUND HANDLER
/// FIX: Must call ensureInitialized() here too — this handler runs in an
/// isolate where the binding is NOT already set up.
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  // FIX 1: ensureInitialized() is correctly first — keep it here.
  WidgetsFlutterBinding.ensureInitialized();

  // FIX 2: Register the background handler BEFORE initializeApp().
  // Firebase messaging sets up its background isolate during initializeApp,
  // so the handler must be registered first or it may be missed on cold start.
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // FIX 3: Defer the first frame so Flutter doesn't attempt to render while
  // Firebase + notifications are still initializing. This closes the timing
  // window that causes "flutter/lifecycle messages discarded" warnings.
  final binding = WidgetsBinding.instance;
  binding.deferFirstFrame();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await LocalNotificationService.init();
  } finally {
    // FIX 4: Always release the frame — even if init fails — so the app
    // doesn't freeze on a white screen.
    binding.allowFirstFrame();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProductProvider()),
        ChangeNotifierProvider(create: (_) => StorageProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => AdminProductProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// 🔥 ROOT APP
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // FIX 5: Guard against the widget being disposed before the callback
      // fires (e.g. hot restart during startup).
      if (!mounted) return;

      final provider = context.read<NotificationProvider>();
      provider.loadNotifications();
      FCMService.init(provider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      themeMode: context.watch<StorageProvider>().isDarktheme
          ? ThemeMode.dark
          : ThemeMode.light,

      initialRoute: AppConstants.splashRoute,

      routes: {
        AppConstants.splashRoute: (_) => const SplashScreen(),
        AppConstants.loginRoute: (_) => const LoginScreen(),
        AppConstants.registerRoute: (_) => const RegisterScreen(),
        AppConstants.forgotPasswordRoute: (_) => const ForgotPasswordScreen(),
        AppConstants.homeRoute: (_) => const HomeScreen(),
      },
    );
  }
}
