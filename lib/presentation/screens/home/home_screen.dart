import 'package:chat_app/data/services/service_locator.dart';
import 'package:chat_app/logic/cubits/auth/auth_cubit.dart';
import 'package:chat_app/presentation/screens/auth/login_screen.dart';
import 'package:chat_app/router/app_router.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
      body: const Center(child: Text("User is Authenticator")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
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
