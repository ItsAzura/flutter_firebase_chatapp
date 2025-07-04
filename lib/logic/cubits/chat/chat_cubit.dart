import 'dart:async';
import 'dart:developer';

import 'package:chat_app/data/repositories/chat_repository.dart';
import 'package:chat_app/logic/cubits/chat/chat_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository; // Repository để xử lý logic chat
  final String currentUserId; // ID của user hiện tại
  bool _isInChat = false; // Trạng thái có đang trong chat không
  StreamSubscription? _messageSubscription;
  StreamSubscription? _onlineStatusSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _blockStatusSubscription;
  StreamSubscription? _amIBlockStatusSubscription;
  Timer? typingTimer; // Timer cho typing indicator

  //constructor
  ChatCubit({
    // Đầu vào
    required ChatRepository chatRepository,
    required this.currentUserId,
  }) : _chatRepository = chatRepository,
       super(const ChatState());

  //* Hàm tạo or tham gia vào chat room
  void enterChat(String receiverId) async {
    //đặt cờ
    _isInChat = true;

    //emit trạng thái loading
    emit(state.copyWith(status: ChatStatus.loading));

    try {
      //gọi hàm getOrCreateChatRoom từ repository để lấy hoặc tạo chat room
      final chatRoom = await _chatRepository.getOrCreateChatRoom(
        currentUserId,
        receiverId,
      );

      //kiểm tra chat room đã tồn tại hay chưa
      if (chatRoom.id.isEmpty) {
        emit(
          state.copyWith(
            status: ChatStatus.error,
            error: 'Chat room not found',
          ),
        );
        return;
      }

      // thành công, emit trạng thái loaded
      emit(
        state.copyWith(
          status: ChatStatus.loaded,
          chatRoomId: chatRoom.id,
          receiverId: receiverId,
        ),
      );

      _subscribeToMessages(chatRoom.id);
      _subscribeToOnlineStatus(receiverId);
      _subscribeToTypingStatus(chatRoom.id);
      _subscribeToBlockStatus(receiverId);

      await _chatRepository.updateOnlineStatus(currentUserId, true);
    } catch (e) {
      // nếu có lỗi, emit trạng thái error
      emit(state.copyWith(status: ChatStatus.error, error: e.toString()));
    }
  }

  //* Hàm để gửi tin nhắn
  Future<void> sendMessage({
    required String content,
    required String receiverId,
  }) async {
    //kiểm tra xem đã có chat room chưa
    if (state.chatRoomId == null) {
      log("Chat room ID is null");
      return;
    }

    //kiểm tra id người nhận có rỗng hay không
    if (receiverId.isEmpty) {
      emit(
        state.copyWith(
          status: ChatStatus.error,
          error: 'Receiver ID cannot be empty',
        ),
      );
      log("Receiver ID is empty");
      return;
    }

    //kiểm tra nội dung tin nhắn có rỗng hay không
    if (content.trim().isEmpty) {
      emit(
        state.copyWith(
          status: ChatStatus.error,
          error: 'Message cannot be empty',
        ),
      );
      log("Message content is empty");
      return;
    }

    try {
      //gọi hàm sendMessage từ repository để gửi tin nhắn
      var sendMessage = await _chatRepository.sendMessage(
        chatRoomId: state.chatRoomId!,
        senderId: currentUserId,
        receiverId: receiverId,
        content: content,
      );

      if (sendMessage == false) {
        emit(
          state.copyWith(
            status: ChatStatus.error,
            error: 'Failed to send message',
          ),
        );
        log("Failed to send message");
        return;
      }

      log("Message sent successfully");
    } catch (e) {
      log("Error sending message: $e");

      //nếu có lỗi, emit trạng thái error
      emit(state.copyWith(status: ChatStatus.error, error: e.toString()));
    }
  }

  //* Hàm để đăng ký lắng nghe các tin nhắn mới trong một phòng chat
  void _subscribeToMessages(String chatRoomId) {
    //nếu user đang ở phòng chat cũ thì huỷ lắng nghe cũ
    _messageSubscription?.cancel(); // Hủy đăng ký cũ nếu có

    _messageSubscription = _chatRepository
        .getMessages(
          chatRoomId,
        ) //gọi hàm getMessages từ repository trả về stream<List<ChatMessage>>
        .listen(
          //lắng nghe stream và cập nhật trạng thái khi có tin nhắn mới
          (messages) {
            if (_isInChat) {
              _markMessagesAsRead(chatRoomId);
            }
            //Cập nhật state với danh sách tin nhắn mới
            emit(state.copyWith(messages: messages, error: null));
          },
          //Nếu bị lỗi khi lắng nghe stream
          onError: (error) {
            emit(
              state.copyWith(
                error: "Failed to load messages",
                status: ChatStatus.error,
              ),
            );
          },
        );
  }

  //* Hàm để đánh dấu các tin nhắn là đã đọc
  Future<void> _markMessagesAsRead(String chatRoomId) async {
    try {
      await _chatRepository.markMessagesAsRead(chatRoomId, currentUserId);
    } catch (e) {
      log("Error marking messages as read: $e");
      emit(
        state.copyWith(
          error: "Failed to mark messages as read",
          status: ChatStatus.error,
        ),
      );
    }
  }

  Future<void> leaveChat() async {
    _isInChat = false;
  }

  void _subscribeToOnlineStatus(String userId) {
    _onlineStatusSubscription?.cancel();
    _onlineStatusSubscription = _chatRepository
        .getUserOnlineStatus(userId)
        .listen(
          (status) {
            final isOnline = status["isOnline"] as bool;
            final lastSeen = status["lastSeen"] as Timestamp?;

            emit(
              state.copyWith(
                isReceiverOnline: isOnline,
                receiverLastSeen: lastSeen,
              ),
            );
          },
          onError: (error) {
            log("Error getting online status: $error");
          },
        );
  }

  void _subscribeToTypingStatus(String chatRoomId) {
    _typingSubscription?.cancel();
    _typingSubscription = _chatRepository
        .getTypingStatus(chatRoomId)
        .listen(
          //lắng nghe trạng thái gõ tin nhắn
          (status) {
            //có đang typing hay không
            final isTyping = status["isTyping"] as bool;

            //user id
            final typingUserId = status["typingUserId"] as String?;

            emit(
              state.copyWith(
                // Cập nhật trạng thái gõ tin nhắn
                isReceiverTyping: isTyping && typingUserId != currentUserId,
              ),
            );
          },
          onError: (error) {
            log("Error getting typing status: $error");
          },
        );
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    if (state.chatRoomId == null) return;

    try {
      var isUpdated = await _chatRepository.updateTypingStatus(
        state.chatRoomId!,
        currentUserId,
        isTyping,
      );

      if (isUpdated == false) {
        log("Failed to update typing status");
        return;
      }
    } catch (e) {
      log("Error updating typing status: $e");
    }
  }

  void startTyping() {
    if (state.chatRoomId == null) return;
    typingTimer?.cancel();
    _updateTypingStatus(true);
    typingTimer = Timer(const Duration(seconds: 3), () {
      _updateTypingStatus(false);
    });
  }

  Future<void> blockUser(String userId) async {
    try {
      var isUserBlocked = await _chatRepository.blockUser(
        currentUserId,
        userId,
      );
      if (isUserBlocked == false) {
        emit(state.copyWith(error: 'Failed to block user'));
        return;
      }
    } catch (e) {
      emit(state.copyWith(error: 'failed to block user $e'));
    }
  }

  Future<void> unBlockUser(String userId) async {
    try {
      var isUnblockedUser = await _chatRepository.unBlockUser(
        currentUserId,
        userId,
      );
      if (isUnblockedUser == false) {
        emit(state.copyWith(error: 'Failed to unblock user'));
        return;
      }
    } catch (e) {
      emit(state.copyWith(error: 'failed to unblock user $e'));
    }
  }

  Future<void> loadMoreMessages() async {
    if (state.status != ChatStatus.loaded ||
        state.messages.isEmpty ||
        !state.hasMoreMessages ||
        state.isLoadingMore) {
      return;
    }

    try {
      emit(state.copyWith(isLoadingMore: true));

      final lastMessage = state.messages.last;
      final lastDoc = await _chatRepository
          .getChatRoomMessages(state.chatRoomId!)
          .doc(lastMessage.id)
          .get();

      final moreMessages = await _chatRepository.getMoreMessages(
        state.chatRoomId!,
        lastDocument: lastDoc,
      );

      if (moreMessages.isEmpty) {
        emit(state.copyWith(hasMoreMessages: false, isLoadingMore: false));
        return;
      }

      emit(
        state.copyWith(
          messages: [...state.messages, ...moreMessages],
          hasMoreMessages: moreMessages.length >= 20,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: "Failed to load more messages",
          isLoadingMore: false,
        ),
      );
    }
  }

  void _subscribeToBlockStatus(String otherUserId) {
    _blockStatusSubscription?.cancel();
    _blockStatusSubscription = _chatRepository
        .isUserBlocked(currentUserId, otherUserId)
        .listen(
          (isBlocked) {
            emit(state.copyWith(isUserBlocked: isBlocked));

            _amIBlockStatusSubscription?.cancel();
            _blockStatusSubscription = _chatRepository
                .amIBlocked(currentUserId, otherUserId)
                .listen((isBlocked) {
                  emit(state.copyWith(amIBlocked: isBlocked));
                });
          },
          onError: (error) {
            log("Error checking block status: $error");
          },
        );
  }
}
