import 'dart:developer';

import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/data/services/base_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactRepository extends BaseRepository {
  // Trả về ID người dùng hiện tại hoặc '' nếu chưa đăng nhập
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Hàm yêu cầu Permission. Trả về true/false tùy người dùng cho phép.
  Future<bool> requestContactsPermission() async {
    return await FlutterContacts.requestPermission();
  }

  //* Hàm lấy danh bạ đã đăng ký
  Future<List<Map<String, dynamic>>> getRegisteredContacts() async {
    try {
      // Xin Permission truy cập danh bạ
      bool hasPermission = await requestContactsPermission();
      if (!hasPermission) {
        log('Contacts permission denied');
        return [];
      }

      // Lấy danh sách Contact có đầy đủ phone number, name, photo
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      // Kiểm tra nếu không có Contact nào
      if (contacts.isEmpty) {
        log('No contacts found');
        return [];
      }

      // Chuẩn hoá danh sách số Phone
      final phoneNumbers = contacts
          .where((contact) => contact.phones.isNotEmpty)
          .map(
            (contact) => {
              'name': contact.displayName,
              'phoneNumber': contact.phones.first.number.replaceAll(
                RegExp(r'[^\d+]'), //Xoá tất cả ký tự đặc biệt
                '',
              ),
              'photo': contact.photo,
            },
          )
          .toList();

      // Lấy danh sách user từ Firestore
      final usersSnapshot = await firestore.collection('users').get();

      if (usersSnapshot.docs.isEmpty) {
        log('No registered users found');
        return [];
      }

      // Chuyển đổi danh sách user từ Firestore thành danh sách UserModel
      final registeredUsers = usersSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      // So khớp danh bạ với user đã đăng ký
      final matchedContacts = phoneNumbers
          .where((contact) {
            String phoneNumber = contact["phoneNumber"].toString();

            // Chuẩn hoá số Phone
            if (phoneNumber.startsWith("+84")) {
              phoneNumber = phoneNumber.substring(3);
            }

            // Kiểm tra nếu contact này đã có trong Firestore và không phải là người dùng hiện tại
            return registeredUsers.any(
              (user) =>
                  user.phoneNumber == phoneNumber && user.uid != currentUserId,
            );
          })
          .map((contact) {
            //Tìm user trong danh sách đã đăng ký phù hợp với số Phone đó.
            String phoneNumber = contact["phoneNumber"].toString();

            if (phoneNumber.startsWith("+84")) {
              phoneNumber = phoneNumber.substring(3);
            }

            final registeredUser = registeredUsers.firstWhere(
              (user) => user.phoneNumber == phoneNumber,
            );

            // Trả về một Map chứa: ID user, tên hiển thị từ danh bạ, số Phone.
            return {
              'id': registeredUser.uid,
              'name': contact['name'],
              'phoneNumber': contact['phoneNumber'],
            };
          })
          .toList();

      return matchedContacts;
    } catch (e) {
      log('Error fetching registered contacts: $e');
      return [];
    }
  }
}

/*

1. Xin Permission truy cập danh bạ máy.
2. Lấy danh bạ có số Phone.
3. Chuẩn hoá số Phone.
4. Lấy toàn bộ người dùng từ Firestore.
5. So khớp số Phone với người dùng đã đăng ký.
6. Trả về danh sách người dùng trùng với danh bạ.

*/
