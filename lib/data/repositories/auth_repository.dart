import 'dart:developer';

import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/data/services/base_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository extends BaseRepository {
  Stream<User?> get authStateChanges => auth.authStateChanges();
  //* Hàm đăng ký người dùng mới
  Future<UserModel> signUp({
    required String fullName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      // Kiểm tra các trường không được để rỗng
      if (fullName.isEmpty ||
          username.isEmpty ||
          email.isEmpty ||
          phoneNumber.isEmpty ||
          password.isEmpty) {
        throw Exception("All fields are required");
      }

      // Loại bỏ space trong phone
      final formattedPhoneNumber = phoneNumber.replaceAll(
        RegExp(r'\s+'),
        "".trim(),
      );

      //Kiểm tra email có tồn tại không
      final emailExists = await checkEmailExists(email);
      if (emailExists) {
        throw Exception("Email already exists");
      }

      //Kiểm tra phone có tồn tại không
      final phoneExists = await checkPhoneExists(formattedPhoneNumber);
      if (phoneExists) {
        throw Exception("Phone number already exists");
      }

      // Tạo người dùng mới trong Firebase Authentication
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      //Nếu không tạo được user
      if (userCredential.user == null) {
        throw "Failed to create user";
      }

      // Tạo đối tượng UserModel
      final user = UserModel(
        uid: userCredential.user!.uid,
        username: username,
        fullName: fullName,
        email: email,
        phoneNumber: formattedPhoneNumber,
      );

      //Lưu vào Firestore
      await saveUserData(user);

      return user;
    } catch (e) {
      log("Error checking email or phone: $e");
      rethrow;
    }
  }

  //* Hàm kiểm tra email đã tồn tại trong Firebase Authentication
  Future<bool> checkEmailExists(String email) async {
    try {
      //Kiểm tra email trong Firebase Authentication
      // ignore: deprecated_member_use
      final methods = await auth.fetchSignInMethodsForEmail(email);

      // Trả về true nếu có ít nhất một phương thức đăng nhập khớp với email
      return methods.isNotEmpty;
    } catch (e) {
      log("Error checking email: $e");
      return false;
    }
  }

  //* Hàm kiểm tra phone đã tồn tại trong Firestore
  Future<bool> checkPhoneExists(String phoneNumber) async {
    try {
      // Kiểm tra phone trong Firestore
      final querySnapshot = await firestore
          .collection("users")
          .where("phoneNumber", isEqualTo: phoneNumber)
          .get();

      // Trả về true nếu có ít nhất một tài liệu khớp
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      log("Error checking phone number: $e");
      return false;
    }
  }

  //* Hàm lưu thông tin người dùng vào Firestore
  Future<void> saveUserData(UserModel user) async {
    try {
      //lưu thông tin người dùng vào Firestore
      firestore.collection("users").doc(user.uid).set(user.toMap());
    } catch (e) {
      log("Error saving user data: $e");
      throw "Failed to save user data";
    }
  }

  //* Hàm đăng nhập
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Kiểm tra email và password không được để rỗng
      if (email.isEmpty || password.isEmpty) {
        log("Email and password are required");
        throw Exception("Email and password are required");
      }

      // Đăng nhập người dùng với email và mật khẩu
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kiểm tra xem người dùng đã đăng nhập thành công hay chưa
      if (userCredential.user == null) {
        log("Failed to sign in");
        throw Exception("Failed to sign in");
      }

      // Lấy thông tin người dùng từ Firestore
      final userData = await getUserData(userCredential.user!.uid);

      // Trả về đối tượng UserModel
      return userData;
    } catch (e) {
      log("Error during sign in: $e");
      rethrow;
    }
  }

  //* Hàm đăng xuất
  Future<void> singOut() async {
    await auth.signOut();
  }

  //* Hàm lấy thông tin người dùng từ Firestore thông qua uid
  Future<UserModel> getUserData(String uid) async {
    try {
      // Kiểm tra uid không được để rỗng
      if (uid.isEmpty) {
        log("User ID is empty");
        throw "User ID is empty";
      }

      //Lấy thông tin người dùng từ Firestore
      final doc = await firestore.collection("users").doc(uid).get();

      //Kiểm tra xem tài liệu có tồn tại không
      if (!doc.exists) {
        log("User not found");
        throw "User not found";
      }

      log(doc.id);

      // Chuyển đổi tài liệu Firestore thành đối tượng UserModel
      return UserModel.fromFirestore(doc);
    } catch (e) {
      log("Error getting user data: $e");
      rethrow;
    }
  }
}
