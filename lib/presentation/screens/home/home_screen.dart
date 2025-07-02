import 'dart:developer';

import 'package:chat_app/data/repositories/auth_repository.dart';
import 'package:chat_app/data/repositories/chat_repository.dart';
import 'package:chat_app/data/repositories/contact_repository.dart';
import 'package:chat_app/data/services/service_locator.dart';
import 'package:chat_app/logic/cubits/auth/auth_cubit.dart';
import 'package:chat_app/presentation/screens/auth/login_screen.dart';
import 'package:chat_app/presentation/screens/chat/chat_message_screen.dart';
import 'package:chat_app/presentation/screens/widgets/chat_list_tile.dart';
import 'package:chat_app/router/app_router.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ContactRepository _contactRepository;
  late final ChatRepository _chatRepository;
  late final String _currentUserId;

  @override
  void initState() {
    _contactRepository = getIt<ContactRepository>();
    _chatRepository = getIt<ChatRepository>();
    _currentUserId = getIt<AuthRepository>().currentUser?.uid ?? "";

    super.initState();
  }

  void _showContactsList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Contacts",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _contactRepository.getRegisteredContacts(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final contacts = snapshot.data!;
                    if (contacts.isEmpty) {
                      return const Center(child: Text("No contacts found"));
                    }
                    return ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            child: Text(contact["name"][0].toUpperCase()),
                          ),
                          title: Text(contact["name"]),
                          onTap: () {
                            //Chuyển sang ChatMessageScreen
                            getIt<AppRouter>().push(
                              ChatMessageScreen(
                                // Truyền ID và tên người nhận vào ChatMessageScreen
                                receiverId: contact['id'],
                                receiverName: contact['name'],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
        actions: [
          InkWell(
            onTap: () async {
              await getIt<AuthCubit>().signOut();
              getIt<AppRouter>().pushAndRemoveUntil(const LoginScreen());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Logout successful!"),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  margin: const EdgeInsets.all(16.0),
                  behavior: SnackBarBehavior.floating,
                  elevation: 10.0,
                  action: SnackBarAction(
                    label: "OK",
                    textColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
            },
            child: Icon(Icons.logout, color: Colors.black, size: 24.0),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _chatRepository.getChatRooms(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            log("Error fetching chat rooms: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!;
          if (chats.isEmpty) {
            return const Center(child: Text("No chats available"));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ChatListTile(
                chat: chat,
                currentUserId: _currentUserId,
                onTap: () {
                  final otherUserId = chat.participants.firstWhere(
                    (id) => id != _currentUserId,
                  );

                  log("Navigating to chat with user ID: $_currentUserId");

                  final outherUserName =
                      chat.participantsName?[otherUserId] ?? "Unknown";
                  getIt<AppRouter>().push(
                    ChatMessageScreen(
                      receiverId: otherUserId,
                      receiverName: outherUserName,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactsList(context),
        elevation: 5.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
        child: const Icon(Icons.chat, color: Colors.white, size: 28.0),
      ),
    );
  }
}
