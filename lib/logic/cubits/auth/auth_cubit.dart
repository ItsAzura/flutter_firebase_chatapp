import 'dart:async';
import 'dart:developer';

import 'package:chat_app/data/repositories/auth_repository.dart';
import 'package:chat_app/data/services/service_locator.dart';
import 'package:chat_app/logic/cubits/auth/auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  //khởi tạo Authrepository để quản lý xác thực người dùng
  final AuthRepository _authRepository;

  // StreamSubscription để lắng nghe các thay đổi trạng thái xác thực
  // ignore: unused_field
  StreamSubscription<User?>? _authStateSubscription;

  //Constructor của AuthCubit
  AuthCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState()) {
    _init();
  }

  //* Trạng thái ban đầu của AuthCubit
  void _init() {
    emit(state.copyWith(status: AuthStatus.initial));

    _authStateSubscription = _authRepository.authStateChanges.listen((
      user,
    ) async {
      //Khi có user
      if (user != null) {
        try {
          //Lấy dữ liệu người dùng từ AuthRepository
          final userData = await _authRepository.getUserData(user.uid);

          //Cập nhật trạng thái thành authenticated với thông tin người dùng
          emit(
            state.copyWith(status: AuthStatus.authenticated, user: userData),
          );
        } catch (e) {
          //Nếu có lỗi trong quá trình lấy dữ liệu người dùng, cập nhật trạng thái thành error
          emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
        }
      } else {
        //Nếu không có user, cập nhật trạng thái thành unauthenticated
        emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
      }
    });
  }

  //* Hàm đăng nhập người dùng
  Future<void> signIn({required String email, required String password}) async {
    try {
      // Bắt đầu trạng thái loading
      emit(state.copyWith(status: AuthStatus.loading));

      // Gọi hàm đăng nhập từ AuthRepository
      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );

      // Cập nhật trạng thái thành authenticated với thông tin người dùng
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
    }
  }

  //* Hàm đăng ký người dùng mới
  Future<void> signUp({
    required String email,
    required String username,
    required String fullName,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      // Bắt đầu trạng thái loading
      emit(state.copyWith(status: AuthStatus.loading));

      // Gọi hàm đăng ký từ AuthRepository với các tham số cần thiết
      final user = await _authRepository.signUp(
        fullName: fullName,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );

      // Cập nhật trạng thái thành authenticated với thông tin người dùng
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
    }
  }

  Future<void> signOut() async {
    try {
      log(getIt<AuthRepository>().currentUser?.uid ?? "aaa");
      await _authRepository.singOut();
      log(getIt<AuthRepository>().currentUser?.uid ?? "aaa");
      emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
    }
  }
}
