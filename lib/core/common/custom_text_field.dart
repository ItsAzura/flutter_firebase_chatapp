import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  //controller để quản lý nội dung nhập vào
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  //keyboardType để xác định loại bàn phím hiển thị
  final TextInputType? keyboardType;

  //prefixIcon và suffixIcon để thêm biểu tượng vào đầu hoặc cuối trường nhập
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  // focusNode để quản lý trạng thái focus của trường nhập
  final FocusNode? focusNode;

  //validator để kiểm tra tính hợp lệ của nội dung nhập vào
  final String? Function(String?)? validator;
  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      focusNode: focusNode,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
