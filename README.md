# Chat App - Flutter

Ứng dụng chat được xây dựng bằng Flutter với Firebase Authentication và Firestore.

## 📋 Flow Hoạt Động Chi Tiết - Login và Signup

### 🏗️ Kiến Trúc Tổng Quan

Ứng dụng sử dụng kiến trúc **Clean Architecture** với **BLoC pattern** và **Dependency Injection**:

```
Presentation Layer (UI) → Business Logic Layer (Cubit) → Data Layer (Repository) → Firebase Services
```

### 🔄 Flow Khởi Tạo Ứng Dụng

#### 1. **main.dart** → **service_locator.dart**

- **File**: `lib/main.dart`
- **Function**: `main()`
- **Flow**:
  1. Gọi `setupServiceLocator()` để khởi tạo các dependencies
  2. Khởi tạo Firebase với `Firebase.initializeApp()`
  3. Đăng ký các services vào GetIt container:
     - `AppRouter()` - Quản lý navigation
     - `FirebaseFirestore.instance` - Database
     - `AuthRepository()` - Xử lý authentication
     - `AuthCubit()` - Quản lý state authentication

### 🔐 Flow Đăng Nhập (Login)

#### 1. **LoginScreen** → **handleSignIn()**

- **File**: `lib/presentation/screens/auth/login_screen.dart`
- **Function**: `handleSignIn()`
- **Flow**:
  1. **Validation**: Kiểm tra form với `_formKey.currentState?.validate()`
  2. **Validation Rules**: Sử dụng `FormValidators.validateEmail()` và `FormValidators.validatePassword()`
  3. **Gọi AuthCubit**: `getIt<AuthCubit>().signIn(email, password)`

#### 2. **AuthCubit** → **signIn()**

- **File**: `lib/logic/cubits/auth/auth_cubit.dart`
- **Function**: `signIn({required String email, required String password})`
- **Flow**:
  1. **Emit Loading State**: `emit(state.copyWith(status: AuthStatus.loading))`
  2. **Gọi Repository**: `await _authRepository.signIn(email: email, password: password)`
  3. **Emit Success State**: `emit(state.copyWith(status: AuthStatus.authenticated, user: user))`
  4. **Emit Error State**: Nếu có lỗi → `emit(state.copyWith(status: AuthStatus.error, error: e.toString()))`

#### 3. **AuthRepository** → **signIn()**

- **File**: `lib/data/repositories/auth_repository.dart`
- **Function**: `signIn({required String email, required String password})`
- **Flow**:
  1. **Validation**: Kiểm tra email và password không rỗng
  2. **Firebase Auth**: `await auth.signInWithEmailAndPassword(email: email, password: password)`
  3. **Lấy User Data**: `await getUserData(userCredential.user!.uid)`
  4. **Return UserModel**: Trả về đối tượng UserModel

#### 4. **AuthRepository** → **getUserData()**

- **File**: `lib/data/repositories/auth_repository.dart`
- **Function**: `getUserData(String uid)`
- **Flow**:
  1. **Firestore Query**: `await firestore.collection("users").doc(uid).get()`
  2. **Convert to Model**: `UserModel.fromFirestore(doc)`
  3. **Return UserModel**: Trả về đối tượng UserModel

#### 5. **BlocConsumer** → **Navigation**

- **File**: `lib/presentation/screens/auth/login_screen.dart`
- **Listener**: Trong `BlocConsumer<AuthCubit, AuthState>`
- **Flow**:
  1. **Success**: `if (state.status == AuthStatus.authenticated)` → `getIt<AppRouter>().pushAndRemoveUntil(const HomeScreen())`
  2. **Error**: `if (state.status == AuthStatus.error)` → Hiển thị SnackBar lỗi

### 📝 Flow Đăng Ký (Signup)

#### 1. **SignupScreen** → **handleSignUp()**

- **File**: `lib/presentation/screens/auth/signup_screen.dart`
- **Function**: `handleSignUp()`
- **Flow**:
  1. **Validation**: Kiểm tra form với `_formKey.currentState?.validate()`
  2. **Validation Rules**: Sử dụng các validators:
     - `FormValidators.validateName()`
     - `FormValidators.validateUsername()`
     - `FormValidators.validateEmail()`
     - `FormValidators.validatePhone()`
     - `FormValidators.validatePassword()`
  3. **Gọi AuthCubit**: `getIt<AuthCubit>().signUp(fullName, username, email, phoneNumber, password)`

#### 2. **AuthCubit** → **signUp()**

- **File**: `lib/logic/cubits/auth/auth_cubit.dart`
- **Function**: `signUp({required String email, required String username, required String fullName, required String phoneNumber, required String password})`
- **Flow**:
  1. **Emit Loading State**: `emit(state.copyWith(status: AuthStatus.loading))`
  2. **Gọi Repository**: `await _authRepository.signUp(fullName, username, email, phoneNumber, password)`
  3. **Emit Success State**: `emit(state.copyWith(status: AuthStatus.authenticated, user: user))`
  4. **Emit Error State**: Nếu có lỗi → `emit(state.copyWith(status: AuthStatus.error, error: e.toString()))`

#### 3. **AuthRepository** → **signUp()**

- **File**: `lib/data/repositories/auth_repository.dart`
- **Function**: `signUp({required String fullName, required String username, required String email, required String phoneNumber, required String password})`
- **Flow**:
  1. **Validation**: Kiểm tra tất cả fields không rỗng
  2. **Format Phone**: Loại bỏ spaces trong phone number
  3. **Check Email Exists**: `await checkEmailExists(email)`
  4. **Check Phone Exists**: `await checkPhoneExists(formattedPhoneNumber)`
  5. **Create Firebase User**: `await auth.createUserWithEmailAndPassword(email: email, password: password)`
  6. **Create UserModel**: Tạo đối tượng UserModel với thông tin người dùng
  7. **Save to Firestore**: `await saveUserData(user)`
  8. **Return UserModel**: Trả về đối tượng UserModel

#### 4. **AuthRepository** → **checkEmailExists()**

- **File**: `lib/data/repositories/auth_repository.dart`
- **Function**: `checkEmailExists(String email)`
- **Flow**:
  1. **Firebase Auth Check**: `await auth.fetchSignInMethodsForEmail(email)`
  2. **Return Boolean**: Trả về `true` nếu email đã tồn tại

#### 5. **AuthRepository** → **checkPhoneExists()**

- **File**: `lib/data/repositories/auth_repository.dart`
- **Function**: `checkPhoneExists(String phoneNumber)`
- **Flow**:
  1. **Firestore Query**: `await firestore.collection("users").where("phoneNumber", isEqualTo:  phoneNumber).get()`
  2. **Return Boolean**: Trả về `true` nếu phone đã tồn tại

#### 6. **AuthRepository** → **saveUserData()**

- **File**: `lib/data/repositories/auth_repository.dart`
- **Function**: `saveUserData(UserModel user)`
- **Flow**:
  1. **Firestore Save**: `firestore.collection("users").doc(user.uid).set(user.toMap())`

#### 7. **BlocConsumer** → **Navigation**

- **File**: `lib/presentation/screens/auth/signup_screen.dart`
- **Listener**: Trong `BlocConsumer<AuthCubit, AuthState>`
- **Flow**:
  1. **Success**: `if (state.status == AuthStatus.authenticated)` → `getIt<AppRouter>().pushAndRemoveUntil(const LoginScreen())`
  2. **Error**: `if (state.status == AuthStatus.error)` → Hiển thị SnackBar lỗi

### 🔄 Flow Navigation

#### **AppRouter** → **Navigation Methods**

- **File**: `lib/router/app_router.dart`
- **Các phương thức**:
  - `push(Widget page)`: Chuyển đến trang mới
  - `pushReplacement(Widget page)`: Thay thế trang hiện tại
  - `pushAndRemoveUntil(Widget page)`: Thay thế và xóa tất cả trang trước đó
  - `pop()`: Quay lại trang trước đó

### 📊 Data Models

#### **UserModel**

- **File**: `lib/data/models/user_model.dart`
- **Fields**:
  - `uid`: ID người dùng từ Firebase
  - `username`: Tên đăng nhập
  - `fullName`: Họ tên đầy đủ
  - `email`: Email
  - `phoneNumber`: Số điện thoại
  - `isOnline`: Trạng thái online
  - `lastSeen`: Thời gian cuối cùng hoạt động
  - `createdAt`: Thời gian tạo tài khoản
  - `fcmToken`: Token cho push notification
  - `blockedUsers`: Danh sách người dùng bị chặn

### ✅ Validation Rules

#### **FormValidators**

- **File**: `lib/core/utils/validators.dart`
- **Email**: Regex pattern `^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$`
- **Password**: Tối thiểu 6 ký tự
- **Name**: Tối thiểu 2 ký tự
- **Username**: Tối thiểu 3 ký tự, chỉ chứa letters, numbers, underscores
- **Phone**: Regex pattern `^(0[3|5|7|8|9]\d{8})$` (định dạng Việt Nam)

### 🔧 State Management

#### **AuthState**

- **File**: `lib/logic/cubits/auth/auth_state.dart`
- **Các trạng thái**:
  - `initial`: Trạng thái ban đầu
  - `loading`: Đang xử lý
  - `authenticated`: Đã xác thực thành công
  - `unauthenticated`: Chưa xác thực
  - `error`: Có lỗi xảy ra

### 🚀 Cách Sử Dụng

1. **Khởi chạy ứng dụng**: `flutter run`
2. **Đăng ký tài khoản mới**: Nhập đầy đủ thông tin và nhấn "Sign up"
3. **Đăng nhập**: Nhập email và password, nhấn "Login"
4. **Chuyển đổi giữa Login/Signup**: Nhấn vào link tương ứng

### 📱 Tính Năng

- ✅ Đăng ký tài khoản mới với validation đầy đủ
- ✅ Đăng nhập với email/password
- ✅ Kiểm tra trùng lặp email và số điện thoại
- ✅ Lưu trữ dữ liệu người dùng trên Firestore
- ✅ Quản lý state với BLoC pattern
- ✅ Navigation với AppRouter
- ✅ Dependency injection với GetIt
- ✅ Validation form real-time
- ✅ Hiển thị thông báo lỗi/thành công
- ✅ Responsive UI design
