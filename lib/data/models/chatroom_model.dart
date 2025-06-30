import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final Timestamp? lastMessageTime;
  final Map<String, Timestamp>? lastReadTime;
  final Map<String, String>? participantsName;
  final bool isTyping;
  final String? typingUserId;
  final bool isCallActive;

  //constructor
  ChatRoomModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTime,
    this.lastReadTime,
    this.participantsName,
    required this.isTyping,
    this.typingUserId,
    required this.isCallActive,
  });

  //tạo object từ Firestore DocumentSnapshot
  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    //gọi data() để lấy dữ liệu từ DocumentSnapshot
    final data = doc.data() as Map<String, dynamic>;

    //trả về một instance của ChatRoomModel
    return ChatRoomModel(
      id: doc.id,
      participants: List<String>.from(data['participants']),
      lastMessage: data['lastMessage'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageTime: data['lastMessageTime'],
      lastReadTime: Map<String, Timestamp>.from(data['lastReadTime'] ?? {}),
      participantsName: Map<String, String>.from(
        data['participantsName'] ?? {},
      ),
      isTyping: data['isTyping'] ?? false,
      typingUserId: data['typingUserId'],
      isCallActive: data['isCallActive'] ?? false,
    );
  }

  //chuyển đổi ChatRoomModel thành Map<String, dynamic> để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime,
      'lastReadTime': lastReadTime,
      'isTyping': isTyping,
      'participantsName': participantsName,
      'typingUserId': typingUserId,
      'isCallActive': isCallActive,
    };
  }
}
