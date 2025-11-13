// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dart:convert'; // Thêm import này để decode User từ SharedPref nếu cần

class User {
  final String username;
  final String email;
  final String accountCode;  // Ví dụ: AC_123...
  final String customerCode; // Ví dụ: CUS_456... (Cái này mới dùng để order/favorite)

  User({
    required this.username,
    required this.email,
    required this.accountCode,
    required this.customerCode,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      // Lấy đúng trường accountCode
      accountCode: (json['accountCode'] ?? '').toString(),
      // 🔴 QUAN TRỌNG: Lấy đúng trường customerCode
      customerCode: (json['customerCode'] ?? '').toString(),
    );
  }

  // Hàm chuyển ngược lại JSON để lưu nếu cần (Optional)
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'accountCode': accountCode,
      'customerCode': customerCode,
    };
  }
}

class AuthProvider with ChangeNotifier {
  String? _authToken;
  User? _currentUser;
  bool _isLoading = false;

  AuthProvider(); // Constructor

  String? get authToken => _authToken;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => (_authToken ?? '').isNotEmpty;
  bool get isLoading => _isLoading;

  // 🔴 GETTER QUAN TRỌNG NHẤT: Trả về đúng customerCode (CUS_...)
  String? get customerCode {
    if (_currentUser != null && _currentUser!.customerCode.isNotEmpty) {
      return _currentUser!.customerCode;
    }
    // Fallback: Nếu không có customerCode thì mới trả về accountCode (nhưng thường là sẽ sai)
    return _currentUser?.accountCode;
  }

  Future<void> loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');

    // Thử khôi phục User từ SharedPreferences nếu có (để không phải login lại)
    final String? userData = prefs.getString('userData');
    if (userData != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userData));
      } catch(e) {
        print('Lỗi parse user data local: $e');
      }
    }

    if (_authToken != null && _authToken!.isNotEmpty) {
      ApiService.setToken(_authToken);
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic>? apiResponse =
      await ApiService.login(username, password);

      // Lấy phần 'data' bên trong response
      final Map<String, dynamic>? data =
      (apiResponse?['data'] is Map) ? apiResponse!['data'] : apiResponse;

      final token = data?['accessToken']?.toString();

      if (token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);
        _authToken = token;

        // Tạo user từ data
        if (data != null) {
          _currentUser = User.fromJson(data);
          // Lưu thông tin user xuống máy luôn để lần sau mở app vẫn còn
          await prefs.setString('userData', jsonEncode(data));

          print('Login Success!');
          print('Account: ${_currentUser?.accountCode}');
          print('Customer: ${_currentUser?.customerCode}'); // Kiểm tra log này
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;

    } catch (error) {
      debugPrint('Lỗi khi đăng nhập: $error');
      return false;

    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
      await prefs.remove('userData'); // Xóa cả thông tin user
      _authToken = null;
      _currentUser = null;
      ApiService.setToken(null);
    } catch (e) {
      debugPrint('Lỗi khi logout: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> register(String username, String password, String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await ApiService.register(username, password, email);
    } catch (error) {
      debugPrint('Lỗi khi đăng ký: $error');
      return error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}