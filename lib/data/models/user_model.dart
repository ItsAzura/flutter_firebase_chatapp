import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String fullName;
  final String email;
  final String phoneNumber;
  final bool isOnline;
  final Timestamp lastSeen;
  final Timestamp createdAt;
  final String? fcmToken;
  final List<String> blockedUsers;

  UserModel({
    required this.uid,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.isOnline = false,
    Timestamp? lastSeen,
    Timestamp? createdAt,
    this.fcmToken,
    this.blockedUsers = const [],
  }) : lastSeen = lastSeen ?? Timestamp.now(),
       createdAt = createdAt ?? Timestamp.now();

  // Tạo UserModel từ dữ liệu Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      username: data["username"] ?? "",
      fullName: data["fullName"] ?? "",
      email: data["email"] ?? "",
      phoneNumber: data["phoneNumber"] ?? "",
      fcmToken: data["fcmToken"],
      lastSeen: data["lastSeen"] ?? Timestamp.now(),
      createdAt: data["createdAt"] ?? Timestamp.now(),
      blockedUsers: List<String>.from(data["blockedUsers"]),
    );
  }

  // Gửi dữ liệu UserModel lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'createdAt': createdAt,
      'blockedUsers': blockedUsers,
      'fcmToken': fcmToken,
    };
  }
}
