import 'package:chat_app/config/theme/app_theme.dart';
import 'package:chat_app/data/services/service_locator.dart';
import 'package:chat_app/presentation/screens/auth/login_screen.dart';
import 'package:chat_app/router/app_router.dart';

import 'package:flutter/material.dart';

void main() async {
  await setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Sử dụng navigatorKey từ AppRouter để quản lý navigation
      navigatorKey: getIt<AppRouter>().navigatorKey,
      title: "Chat App",
      theme: AppTheme.lightTheme,
      home: LoginScreen(),
    );
  }
}
