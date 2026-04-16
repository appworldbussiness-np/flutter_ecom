import 'package:ecom_/features/auth/screens/forgetpassword_screen.dart';
import 'package:ecom_/features/auth/screens/splash_screen.dart';
import 'package:ecom_/firebase_options.dart';
import 'package:ecom_/providers/app_product_provider.dart';
import 'package:ecom_/providers/cart_provider.dart';
import 'package:ecom_/providers/profile_provider.dart';
import 'package:ecom_/providers/theme_provider.dart';
import 'package:ecom_/providers/wishlist_provider.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage((message) async {});
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProductProvider()),
        ChangeNotifierProvider(create: (_) => StorageProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      }, // in your routes setup
    );
  }
}
