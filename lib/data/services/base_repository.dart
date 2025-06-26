import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//Khởi tạo lớp cơ sở cho các repository để sử dụng Firebase Auth và Firestore
abstract class BaseRepository {
  //tạo instance của FirebaseAuth và FirebaseFirestore
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  //getter để lấy người dùng hiện tại nếu có
  User? get currentUser => auth.currentUser;

  //Nếu không có người dùng hiện tại, trả về chuỗi rỗng
  String get uid => currentUser?.uid ?? "";

  //Kiểm tra xem người dùng đã xác thực hay chưa
  bool get isAuthenticated => currentUser != null;
}
