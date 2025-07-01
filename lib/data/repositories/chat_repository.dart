import 'package:chat_app/data/models/chatroom_model.dart';
import 'package:chat_app/data/services/base_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepository extends BaseRepository {
  CollectionReference get _chatRooms => firestore.collection('chatRooms');

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
}
