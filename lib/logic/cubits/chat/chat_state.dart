// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'package:chat_app/data/models/chat_message.dart';

//các state chat chat
enum ChatStatus { initial, loading, loaded, error }

class ChatState extends Equatable {
  final ChatStatus status;
  final String? error;
  final String? receiverId;
  final String? chatRoomId;
  final List<ChatMessage> messages;
  final bool isReceiverTyping;
  final bool isReceiverOnline;
  final Timestamp? receiverLastSeen;
  final bool hasMoreMessages;
  final bool isLoadingMore;
  final bool isUserBlocked;
  final bool amIBlocked;

  //constructor của ChatState, tham số mặc định cho các thuộc tính
  const ChatState({
    this.status = ChatStatus.initial,
    this.error,
    this.receiverId,
    this.chatRoomId,
    this.messages = const [],
    this.isReceiverTyping = false,
    this.isReceiverOnline = false,
    this.receiverLastSeen,
    this.hasMoreMessages = true,
    this.isLoadingMore = false,
    this.isUserBlocked = false,
    this.amIBlocked = false,
  });

  //cho phép cập nhật trạng thái của ChatState mà không cần tạo một đối tượng mới
  ChatState copyWith({
    ChatStatus? status,
    String? error,
    String? receiverId,
    String? chatRoomId,
    List<ChatMessage>? messages,
    bool? isReceiverTyping,
    bool? isReceiverOnline,
    Timestamp? receiverLastSeen,
    bool? hasMoreMessages,
    bool? isLoadingMore,
    bool? isUserBlocked,
    bool? amIBlocked,
  }) {
    return ChatState(
      status: status ?? this.status,
      error: error ?? this.error,
      receiverId: receiverId ?? this.receiverId,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      messages: messages ?? this.messages,
      isReceiverTyping: isReceiverTyping ?? this.isReceiverTyping,
      isReceiverOnline: isReceiverOnline ?? this.isReceiverOnline,
      receiverLastSeen: receiverLastSeen ?? this.receiverLastSeen,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isUserBlocked: isUserBlocked ?? this.isUserBlocked,
      amIBlocked: amIBlocked ?? this.amIBlocked,
    );
  }

  //giúp bloc so sánh gtri thay vì tham chiếu đễ xác định xem có cần cập nhật UI hay không
  @override
  List<Object?> get props {
    return [
      status,
      error,
      receiverId,
      chatRoomId,
      messages,
      isReceiverTyping,
      isReceiverOnline,
      receiverLastSeen,
      hasMoreMessages,
      isLoadingMore,
      isUserBlocked,
      amIBlocked,
    ];
  }
}
