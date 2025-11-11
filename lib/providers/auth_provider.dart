// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import "package:shared_preferences/shared_preferences.dart";
import '../services/api_service.dart';

// Tạo một Model đơn giản cho User (nếu API trả về thông tin user sau login)
class User {
  final String username;
  final String email;
  final String id; // Hoặc bất kỳ ID nào bạn có
  // Thêm các trường thông tin khác của user nếu cần, ví dụ:
  final String? accountCode; // Thêm accountCode

  User({required this.id, required this.username, required this.email, this.accountCode});

  factory User.fromJson(Map<String, dynamic> json) {
    // Đảm bảo các key ở đây khớp với key trong JSON API trả về
    return User(
      id: json['accountCode'] ?? json['username'] ?? '', // Sử dụng accountCode làm ID chính nếu có, hoặc username
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      accountCode: json['accountCode'], // Lấy accountCode
    );
  }
}

class AuthProvider with ChangeNotifier {
  String? _authToken;
  User? _currentUser;
  bool _isLoading = false;

  AuthProvider() {
    _loadAuthToken();
  }

  String? get authToken => _authToken;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _authToken != null;
  bool get isLoading => _isLoading;

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');
    // Khi khởi động, nếu có token, bạn có thể gọi API để lấy lại thông tin user
    // hoặc giải mã token nếu nó chứa đủ thông tin
    // Hiện tại, chúng ta chỉ kiểm tra sự tồn tại của token
    if (_authToken != null) {
      // Vì API đăng nhập của bạn trả về toàn bộ thông tin user trong 'data',
      // việc load token ở đây sẽ không tự động load user.
      // Bạn có thể cần một API riêng để lấy thông tin user bằng token,
      // hoặc lưu toàn bộ user object vào SharedPreferences sau khi đăng nhập.
      // Để đơn giản, nếu có token, ta giả định là đã đăng nhập.
      // user info sẽ được set khi login thành công.
      // Nếu bạn muốn user info được giữ lại sau khi app bị tắt, bạn sẽ phải
      // lưu cả user info vào SharedPreferences cùng với token.
      // Tạm thời, chúng ta sẽ để _currentUser là null khi load token,
      // và chỉ set khi đăng nhập thành công.
    }
    notifyListeners();
  }

  // Phương thức Đăng nhập
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    // ApiService.login bây giờ sẽ trả về toàn bộ Map phản hồi từ API
    final Map<String, dynamic>? apiResponse = await ApiService.login(username, password);

    if (apiResponse != null && apiResponse['statusCode'] == 200) {
      // Lấy đối tượng 'data' từ phản hồi API
      final Map<String, dynamic>? data = apiResponse['data'];

      if (data != null) {
        final token = data['accessToken']; // Lấy accessToken từ đối tượng 'data'
        // Tất cả thông tin user nằm trực tiếp trong đối tượng 'data' này
        final userJson = data;

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', token);
          _authToken = token;

          _currentUser = User.fromJson(userJson); // Gán userJson trực tiếp vào User.fromJson

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Phương thức Đăng xuất
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    _authToken = null;
    _currentUser = null;

    _isLoading = false;
    notifyListeners();
  }

  // Phương thức Đăng ký
  Future<String?> register(String username, String password, String email) async {
    _isLoading = true;
    notifyListeners();

    final String? errorMessage = await ApiService.register(username, password, email);

    _isLoading = false;
    notifyListeners();
    return errorMessage; // Trả về null nếu thành công, chuỗi lỗi nếu thất bại
  }
}