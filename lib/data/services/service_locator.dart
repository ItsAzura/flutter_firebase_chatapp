import 'package:chat_app/data/repositories/auth_repository.dart';
import 'package:chat_app/data/repositories/contact_repository.dart';
import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/logic/cubits/auth/auth_cubit.dart';
import 'package:chat_app/router/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

//* Khởi tạo GetIt instance để quản lý dependency injection
final getIt = GetIt.instance;

//* Khởi tạo hàm bất đồng bộ để tạo các service cần thiết
Future<void> setupServiceLocator() async {
  //Khởi tạo Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //Đăng ký AppRouter như một singleton trong GetIt để routing
  getIt.registerLazySingleton(() => AppRouter());

  //Đăng ký FirebaseAuth như một singleton trong GetIt để quản lý xác thực người dùng
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  //Đăng ký AuthRepository như một singleton trong GetIt để quản lý xác thực người dùng
  getIt.registerLazySingleton(() => AuthRepository());

  //Đăng ký ContactRepository như một singleton trong GetIt để quản lý contact
  getIt.registerLazySingleton(() => ContactRepository());

  //Đăng ký AuthCubit như một singleton trong GetIt để quản lý trạng thái xác thực
  getIt.registerLazySingleton(
    () => AuthCubit(authRepository: getIt<AuthRepository>()),
  );
}
