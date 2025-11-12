import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// Model người dùng tối giản
class User {
  final String username;
  final String email;
  final String id;            // dùng accountCode hoặc username
  final String? accountCode;  // nếu API có

  User({
    required this.id,
    required this.username,
    required this.email,
    this.accountCode,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['accountCode'] ?? json['username'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      accountCode: json['accountCode']?.toString(),
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
  bool get isAuthenticated => (_authToken ?? '').isNotEmpty;
  bool get isLoading => _isLoading;

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');
    notifyListeners();
  }

  /// Đăng nhập: đọc token ở data.accessToken như Postman của bạn
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    final Map<String, dynamic>? apiResponse =
    await ApiService.login(username, password);

    // apiResponse có thể là {statusCode, message, data:{...}}
    final Map<String, dynamic>? data =
    (apiResponse?['data'] is Map) ? apiResponse!['data'] : apiResponse;

    final token = data?['accessToken']?.toString();
    if (token != null && token.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', token);
      _authToken = token;

      _currentUser = User.fromJson(data!);

      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

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

  /// Đăng ký: ApiService.register trả về `null` nếu OK, còn lại là chuỗi lỗi
  Future<String?> register(String username, String password, String email) async {
    _isLoading = true;
    notifyListeners();

    final String? errorMessage =
    await ApiService.register(username, password, email);

    _isLoading = false;
    notifyListeners();
    return errorMessage;
  }
}
