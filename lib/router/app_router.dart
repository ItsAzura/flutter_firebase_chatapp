import 'package:flutter/material.dart';

//AppRouter class to manage navigation in the app
class AppRouter {
  //Khởi tạo một GlobalKey để quản lý NavigatorState
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  //Getter để lấy NavigatorState từ GlobalKey
  NavigatorState get _navigator => navigatorKey.currentState!;

  //Phương thức để kiểm tra xem có thể quay lại trang trước đó hay không
  void pop<T>([T? result]) {
    if (_navigator.canPop()) {
      _navigator.pop(result);
    }
  }

  //Phương thức để quay lại trang trước đó
  Future<T?> push<T>(Widget page) {
    return _navigator.push<T>(MaterialPageRoute<T>(builder: (_) => page));
  }

  //Phương thức để thay thế trang hiện tại bằng một trang mới
  Future<T?> pushReplacement<T>(Widget page) {
    return _navigator.pushReplacement<T, dynamic>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  //Phương thức để thay thế trang hiện tại và xóa tất cả các trang trước đó
  Future<T?> pushAndRemoveUntil<T>(Widget page) {
    return _navigator.pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  //Phương thức để chuyển hướng đến một trang mới bằng tên route
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return _navigator.pushNamed<T>(routeName, arguments: arguments);
  }
}
