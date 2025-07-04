import 'dart:developer';

import 'package:chat_app/data/models/chat_message.dart';
import 'package:chat_app/data/models/chatroom_model.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/data/services/base_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepository extends BaseRepository {
  //Định nghĩa một collection reference cho các phòng chat
  CollectionReference get _chatRooms => firestore.collection('chatRooms');

  //Hàm lấy tất cả các messages trong một phòng chat
  CollectionReference getChatRoomMessages(String chatRoomId) {
    return _chatRooms.doc(chatRoomId).collection("messages");
  }

  //* Hàm để lấy hoặc tạo một phòng chat giữa hai người dùng
  Future<ChatRoomModel> getOrCreateChatRoom(
    //Đầu vào là ID của người dùng hiện tại và ID của người dùng khác
    String currentUserId,
    String otherUserId,
  ) async {
    //kiểm tra xem ID người dùng hiện tại và ID người dùng khác có rỗng hay không
    if (currentUserId.isEmpty || otherUserId.isEmpty) {
      throw Exception('User IDs cannot be empty');
    }

    //không thể tạo phòng chat với chính mình
    if (currentUserId == otherUserId) {
      throw Exception('Cannot create a chat room with yourself');
    }

    //tạo Id duy nhất cho chat room

    //Tạo 1 list chứa 2 user id và sắp xếp chúng theo thứ tự
    final users = [currentUserId, otherUserId]..sort();
    //kết nối các user id bằng dấu "_" để tạo ra 1 roomId duy nhất
    final roomId = users.join('_');

    //kiểm tra room đã tồn tại chưa thông qua id
    final roomDoc = await _chatRooms.doc(roomId).get();
    if (roomDoc.exists) {
      return ChatRoomModel.fromFirestore(roomDoc);
    }

    //Lấy dữ liệu của người dùng hiện tại và người dùng khác từ Firestore
    final currentUserData =
        //firestore -> collection "users" -> document currentUserId
        (await firestore.collection("users").doc(currentUserId).get()).data()
            as Map<String, dynamic>; //trả về dữ liệu Map<String, dynamic>

    final otherUserData =
        //firestore -> collection "users" -> document otherUserId
        (await firestore.collection("users").doc(otherUserId).get()).data()
            as Map<String, dynamic>; //trả về dữ liệu Map<String, dynamic>

    //Tạo một Map<String, String> để lưu tên của các người tham gia
    final participantsName = {
      currentUserId: currentUserData['fullName']?.toString() ?? "",
      otherUserId: otherUserData['fullName']?.toString() ?? "",
    };

    //Tạo một ChatRoomModel mới với các thông tin cần thiết
    final newRoom = ChatRoomModel(
      id: roomId,
      participants: users,
      participantsName: participantsName,
      lastReadTime: {
        currentUserId: Timestamp.now(),
        otherUserId: Timestamp.now(),
      },
    );

    //Lưu ChatRoomModel mới vào Firestore
    await _chatRooms.doc(roomId).set(newRoom.toMap());
    return newRoom;
  }

  //* Hàm để gửi một tin nhắn trong một phòng chat
  Future<bool> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    //kiểm tra xem chatRoomId, senderId, receiverId có rỗng hay không
    if (chatRoomId.isEmpty ||
        senderId.isEmpty ||
        receiverId.isEmpty ||
        content.isEmpty) {
      return false;
    }

    //khai báo batch để thực hiện nhiều thao tác ghi dữ liệu trong Firestore
    final batch = firestore.batch();

    //Lấy reference đến collection messages trong chat room
    final messageRef = getChatRoomMessages(chatRoomId);

    //tạo doc id mới cho message
    final messageDoc = messageRef.doc();

    final message = ChatMessage(
      id: messageDoc.id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: type,
      timestamp: Timestamp.now(),
      readBy: [senderId],
    );

    if (message.content.isEmpty) {
      return false;
    }

    //dùng batch để thêm message vào collection messages
    batch.set(messageDoc, message.toMap());

    //cập nhật lại thông tin của chat room
    batch.update(_chatRooms.doc(chatRoomId), {
      "lastMessage": content,
      "lastMessageSenderId": senderId,
      "lastMessageTime": message.timestamp,
    });

    //commit batch để thực hiện các thao tác ghi dữ liệu
    await batch.commit();

    return true;
  }

  //* Hàm để lấy các tin nhắn trong một phòng chat
  Stream<List<ChatMessage>> getMessages(
    String chatRoomId, {
    DocumentSnapshot? lastDocument,
  }) {
    if (chatRoomId.isEmpty) {
      throw Exception('Chat room ID cannot be empty');
    }

    //lấy collection reference đến các tin nhắn trong phòng chat
    var query = getChatRoomMessages(chatRoomId)
        .orderBy('timestamp', descending: true) //tin nhắn mới nhất sẽ ở đầu
        .limit(20); //giới hạn số lượng tin nhắn lấy về là 20

    //nếu có lastDocument thì bắt đầu từ document đó
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    //trả về stream của danh sách tin nhắn
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromFirestore(
          doc,
        ); //chuyển đổi DocumentSnapshot thành ChatMessage
      }).toList();
    });
  }

  //* Hàm để lấy thêm tin nhắn trong một phòng chat
  Future<List<ChatMessage>> getMoreMessages(
    String chatRoomId, {
    required DocumentSnapshot lastDocument,
  }) async {
    if (chatRoomId.isEmpty) {
      throw Exception('Chat room ID cannot be empty');
    }

    //lấy collection reference đến các tin nhắn trong phòng chat
    final query = getChatRoomMessages(chatRoomId)
        .orderBy('timestamp', descending: true) //tin nhắn mới nhất sẽ ở đầu
        .startAfterDocument(lastDocument) //bắt đầu từ document cuối cùng đã lấy
        .limit(20);
    log("Loading");

    //lấy snapshot của query
    final snapshot = await query.get();

    //trả về danh sách các tin nhắn
    return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
  }

  //* Hàm để lấy danh sách các phòng chat của một người dùng
  Stream<List<ChatRoomModel>> getChatRooms(String userId) {
    if (userId.isEmpty) {
      throw Exception('User ID cannot be empty');
    }

    return _chatRooms
        .where(
          "participants",
          arrayContains: userId,
        ) //lọc các phòng chat có người dùng tham gia
        .orderBy(
          'lastMessageTime',
          descending: true,
        ) //sắp xếp theo thời gian tin nhắn cuối cùng
        .snapshots() //trả về stream của snapshot
        .map(
          //chuyển đổi snapshot thành danh sách các ChatRoomModel
          (snapshot) => snapshot.docs
              .map((doc) => ChatRoomModel.fromFirestore(doc))
              .toList(),
        );
  }

  //* Hàm lấy số lượng tin nhắn chưa đọc trong một phòng chat
  Stream<int> getUnreadCount(String chatRoomId, String userId) {
    return getChatRoomMessages(chatRoomId)
        .where(
          "receiverId",
          isEqualTo: userId,
        ) //lọc các tin nhắn gửi đến người dùng
        .where(
          'status',
          isEqualTo: MessageStatus.sent.toString(),
        ) //lọc các tin nhắn chưa đọc
        .snapshots() //trả về stream của snapshot
        .map(
          (snapshot) => snapshot.docs.length,
        ); //trả về số lượng tin nhắn chưa đọc
  }

  //* Hàm để đánh dấu các tin nhắn là đã đọc trong một phòng chat
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      // Kiểm tra xem chatRoomId và userId có hợp lệ không
      if (chatRoomId.isEmpty || userId.isEmpty) {
        throw Exception('Chat room ID and user ID cannot be empty');
      }

      //tạo một batch để thực hiện nhiều thao tác ghi dữ liệu
      final batch = firestore.batch();

      //lấy tất cả các tin nhắn chưa đọc của người dùng trong phòng chat
      final unreadMessage = await getChatRoomMessages(chatRoomId)
          .where(
            "receiverId",
            isEqualTo: userId,
          ) //lọc các tin nhắn gửi đến người dùng
          .where(
            'status',
            isEqualTo: MessageStatus.sent.toString(),
          ) //lọc các tin nhắn chưa đọc
          .get();

      log("found ${unreadMessage.docs.length} unread messages");

      if (unreadMessage.docs.isEmpty) {
        log("No unread messages found");
        return; //nếu không có tin nhắn chưa đọc thì không cần làm gì
      }

      //vòng lặp qua các tin nhắn chưa đọc và cập nhật trạng thái của chúng
      for (final doc in unreadMessage.docs) {
        batch.update(doc.reference, {
          'status': MessageStatus.read.toString(),
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }

      //gửi lên firestore
      await batch.commit();
      log("Marked ${unreadMessage.docs.length} messages as read");
    } catch (e) {
      log("Error marking messages as read: $e");
      throw Exception('Failed to mark messages as read');
    }
  }

  Stream<Map<String, dynamic>> getUserOnlineStatus(String userId) {
    return firestore.collection("users").doc(userId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      return {
        'isOnline': data?['isOnline'] ?? false,
        'lastSeen': data?['lastSeen'],
      };
    });
  }

  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    await firestore.collection("users").doc(userId).update({
      'isOnline': isOnline,
      'lastSeen': Timestamp.now(),
    });
  }

  //* Hàm để lấy trạng thái gõ tin nhắn trong một phòng chat
  Stream<Map<String, dynamic>> getTypingStatus(String chatRoomId) {
    //trả về stream của trạng thái gõ tin nhắn dạng Map<String, dynamic>
    return
    //truy cập vào document của room chat và tạo stream từ snapshots
    _chatRooms.doc(chatRoomId).snapshots().map((snapshot) {
      //nếu mà snapshot không tồn tại thì trả về trạng thái không gõ
      if (!snapshot.exists) {
        return {'isTyping': false, 'typingUserId': null};
      }

      //lấy dữ liệu từ snapshot và ép kiểu về Map<String, dynamic>
      final data = snapshot.data() as Map<String, dynamic>;

      //trả về trạng thái gõ tin nhắn
      return {
        "isTyping": data['isTyping'] ?? false,
        "typingUserId": data['typingUserId'],
      };
    });
  }

  //* Hàm để cập nhật trạng thái gõ tin nhắn trong một phòng chat
  Future<bool> updateTypingStatus(
    String chatRoomId,
    String userId,
    bool isTyping,
  ) async {
    try {
      //lấy document của chat room
      final doc = await _chatRooms.doc(chatRoomId).get();
      if (!doc.exists) {
        log("Chat room does not exist");
        return false;
      }
      await _chatRooms.doc(chatRoomId).update({
        'isTyping': isTyping,
        'typingUserId': isTyping ? userId : null,
      });

      return true;
    } catch (e) {
      log("Error updating typing status: $e");
      return false;
    }
  }

  Future<bool> blockUser(String currentUserId, String blockedUserId) async {
    try {
      final userRef = firestore.collection("users").doc(currentUserId);
      await userRef.update({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
      });

      log("User blocked successfully");
      return true;
    } catch (e) {
      log("Failed to block user: $e");
      return false;
    }
  }

  Future<bool> unBlockUser(String currentUserId, String blockedUserId) async {
    try {
      final userRef = firestore.collection("users").doc(currentUserId);
      await userRef.update({
        'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
      });

      log("User unblocked successfully");
      return true;
    } catch (e) {
      log("Failed to unblock user: $e");
      return false;
    }
  }

  Stream<bool> isUserBlocked(String currentUserId, String otherUserId) {
    return firestore.collection("users").doc(currentUserId).snapshots().map((
      doc,
    ) {
      final userData = UserModel.fromFirestore(doc);
      return userData.blockedUsers.contains(otherUserId);
    });
  }

  Stream<bool> amIBlocked(String currentUserId, String otherUserId) {
    return firestore.collection("users").doc(otherUserId).snapshots().map((
      doc,
    ) {
      final userData = UserModel.fromFirestore(doc);
      return userData.blockedUsers.contains(currentUserId);
    });
  }
}
