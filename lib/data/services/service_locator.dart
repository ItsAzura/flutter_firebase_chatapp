import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

// Khởi tạo GetIt instance để quản lý dependency injection
final getIt = GetIt.instance;

//Khởi tạo hàm bất đồng bộ để tạo các service cần thiết
Future<void> setupServiceLocator() async {
  //Khởi tạo Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //Đăng ký AppRouter như một singleton trong GetIt để routing
  getIt.registerLazySingleton(() => AppRouter());
}
