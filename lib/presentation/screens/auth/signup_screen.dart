import 'package:chat_app/core/common/custom_button.dart';
import 'package:chat_app/core/common/custom_text_field.dart';
import 'package:chat_app/core/utils/ui_utils.dart';
import 'package:chat_app/core/utils/validators.dart';
import 'package:chat_app/data/services/service_locator.dart';
import 'package:chat_app/logic/cubits/auth/auth_cubit.dart';
import 'package:chat_app/logic/cubits/auth/auth_state.dart';
import 'package:chat_app/presentation/screens/auth/login_screen.dart';
import 'package:chat_app/router/app_router.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  final _nameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _phoneFocus = FocusNode();

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    _nameFocus.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  //* Hàm xử lý đăng ký người dùng mới
  Future<void> handleSignUp() async {
    // Bỏ focus ra các trường nhập liệu
    FocusScope.of(context).unfocus();

    // Kiểm tra tính hợp lệ của form
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Gọi hàm đăng ký từ AuthRepository thông qua GetIt
        await getIt<AuthCubit>().signUp(
          fullName: nameController.text.trim(),
          username: usernameController.text.trim(),
          email: emailController.text.trim(),
          phoneNumber: phoneController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Nếu đăng ký thành công, có thể chuyển hướng hoặc hiển thị thông báo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Account created successfully!"),
            backgroundColor: Colors.green,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
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
      } catch (e) {
        // Hiển thị thông báo lỗi nếu có
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
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
      }
    } else {
      UiUtils.showSnackBar(
        context,
        message: "Please fill in all fields correctly.",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      bloc: getIt<AuthCubit>(),
      // Lắng nghe các thay đổi trạng thái xác thực
      listener: (context, state) {
        // Nếu trạng thái là authenticated
        if (state.status == AuthStatus.authenticated) {
          // Hiển thị thông báo thành công
          getIt<AppRouter>().pushAndRemoveUntil(const LoginScreen());
        } else if (state.status == AuthStatus.error && state.error != null) {
          // Nếu có lỗi, hiển thị thông báo lỗi
          UiUtils.showSnackBar(context, message: state.error!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      "Create Account",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Please fill in the details to continue",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(
                      controller: nameController,
                      focusNode: _nameFocus,
                      hintText: "Full Name",
                      validator: FormValidators.validateName,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: usernameController,
                      hintText: "Username",
                      focusNode: _usernameFocus,
                      validator: FormValidators.validateUsername,
                      prefixIcon: const Icon(Icons.alternate_email),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: emailController,
                      hintText: "Email",
                      focusNode: _emailFocus,
                      validator: FormValidators.validateEmail,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: phoneController,
                      focusNode: _phoneFocus,
                      validator: FormValidators.validatePhone,
                      hintText: "Phone Number",
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      hintText: "Password",
                      focusNode: _passwordFocus,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      validator: FormValidators.validatePassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      onPressed: handleSignUp,
                      text: "Create Account",
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account?  ",
                          style: TextStyle(color: Colors.grey[600]),
                          children: [
                            TextSpan(
                              text: "Login",
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pop(context);
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
