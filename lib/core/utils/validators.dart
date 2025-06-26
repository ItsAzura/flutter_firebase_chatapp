class FormValidators {
  //Hàm kiểm tra tính hợp lệ của email
  static String? validateEmail(String? value) {
    //Nếu giá trị là null hoặc rỗng, trả về thông báo lỗi
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }

    //Khởi tạo biểu thức chính quy để kiểm tra định dạng email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    //Kiểm tra xem giá trị có khớp với biểu thức chính quy không
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address (e.g., example@email.com)';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    // Kiểm tra xem username có chứa ký tự đặc biệt hay không
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    // Kiểm tra định dạng số điện thoại Việt Nam
    final phoneRegex = RegExp(r'^(0[3|5|7|8|9]\d{8})$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number (e.g., 0123456789)';
    }
    return null;
  }
}
