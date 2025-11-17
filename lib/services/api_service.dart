// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Để dùng debugPrint
import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/product_category.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';

class ApiService {
  // ===== Cấu hình Host =====
  static String? _overrideHost;
  static void setHost(String host) => _overrideHost = host;

  static String get _platformHost => Platform.isAndroid ? '10.0.2.2' : 'localhost';
  static String get _host => _overrideHost ?? _platformHost;
  static const int _port = 8080;
  static String get baseUrl => 'http://$_host:$_port/v1/api';

  // =========================================================
  // 🔴 MỚI: CẤU HÌNH API GIAO HÀNG NHANH (GHN)
  // =========================================================
  static const String _ghnBaseUrl = 'https://online-gateway.ghn.vn/shiip/public-api/master-data';
  static const String _ghnToken = '732e3629-c1d9-11f0-a09b-aec1ea660f5d'; // Token của bạn

  static Map<String, String> get _ghnHeaders => {
    'Content-Type': 'application/json',
    'Token': _ghnToken,
  };
  // =========================================================

  // ===== Token (Của app bạn) =====
  static String? _token;
  static String? get token => _token;
  static void setToken(String? t) {
    _token = t;
    debugPrint('🔑 Token đã được lưu: ${_token != null ? "Có" : "Không"}');
  }
  static bool get hasToken => (_token ?? '').isNotEmpty;

  // ===== Headers (Của app bạn) =====
  static Map<String, String> headers({bool jsonBody = true, bool withAuth = false}) {
    final h = <String, String>{};
    if (jsonBody) h['Content-Type'] = 'application/json';
    if (withAuth && hasToken) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  // Helper: Bóc tách dữ liệu từ API response
  static List<dynamic> _unwrapList(dynamic decoded) {
    if (decoded is Map) {
      final list = decoded['data'] ?? decoded['payload'];
      if (list is List) return list;
    }
    if (decoded is List) return decoded;
    return [];
  }

  //Helper: Kiểm tra statusCode chuẩn từ Backend
  static void _checkResponseSuccess(dynamic decoded) {
    if (decoded is Map && decoded.containsKey('statusCode')) {
      final code = decoded['statusCode'];
      if (code != 200 && code != 201) {
        throw Exception(decoded['message'] ?? 'Lỗi từ server (Code $code)');
      }
    }
  }

  // =========================================================
  // AUTH
  // =========================================================
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers(),
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (res.body.isEmpty) throw Exception('Auth response body rỗng');
      debugPrint('Login Response: ${res.body}');
      final data = jsonDecode(res.body);
      _checkResponseSuccess(data);
      final token = (data['accessToken'] ??
          data['token'] ??
          (data is Map && data['data'] is Map ? data['data']['accessToken'] : null)) as String?;
      if (token != null && token.isNotEmpty) {
        setToken(token);
      }
      return data;
    } catch (e) {
      debugPrint('Lỗi Login: $e');
      return null;
    }
  }

  static Future<String?> register(String username, String password, String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/account/register'),
        headers: headers(),
        body: jsonEncode({'username': username, 'password': password, 'email': email}),
      );
      if (res.body.isEmpty) return "Lỗi đăng ký (body rỗng)";
      final decoded = jsonDecode(res.body);
      _checkResponseSuccess(decoded);
      return null; // Thành công
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  // =========================================================
  // PRODUCTS & CATEGORIES
  // =========================================================
  static Future<List<ProductCategory>> fetchAllCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/categories'), headers: headers());
    if (res.body.isEmpty) return []; // 🔴 SỬA LỖI: Thêm kiểm tra rỗng
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    return _unwrapList(decoded).map((e) => ProductCategory.fromJson(e)).toList();
  }

  static Future<List<Product>> fetchAllProducts() async {
    final res = await http.get(Uri.parse('$baseUrl/products'), headers: headers());
    if (res.body.isEmpty) return []; // 🔴 SỬA LỖI: Thêm kiểm tra rỗng
    final decoded = jsonDecode(res.body);
    if (res.statusCode == 200) {
      _checkResponseSuccess(decoded);
      return _unwrapList(decoded).map((e) => Product.fromJson(e)).toList();
    }
    throw Exception('HTTP Error ${res.statusCode}');
  }

  static Future<List<Product>> searchProducts(String query) async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/search?q=${Uri.encodeQueryComponent(query)}'),
      headers: headers(),
    );
    if (res.body.isEmpty) return []; // 🔴 SỬA LỖI: Thêm kiểm tra rỗng
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    return _unwrapList(decoded).map((e) => Product.fromJson(e)).toList();
  }

  static Future<Product> fetchProductByCode(String productCode) async {
    final res = await http.get(Uri.parse('$baseUrl/products/$productCode'), headers: headers());
    if (res.body.isEmpty) throw Exception('Không tìm thấy sản phẩm'); // 🔴 SỬA LỖI
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    final data = decoded['data'] ?? decoded['payload'] ?? decoded;
    return Product.fromJson(data);
  }

  // =========================================================
  // FAVORITES
  // =========================================================
  static Future<List<Product>> fetchMyFavorites(String customerCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/favorite/$customerCode'),
      headers: headers(withAuth: true),
    );
    if (res.body.isEmpty) return []; // 🔴 SỬA LỖI: Thêm kiểm tra rỗng
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    return _unwrapList(decoded).map((e) => Product.fromJson(e)).toList();
  }

  static Future<void> addFavorite(String customerCode, String productCode) async {
    final url = '$baseUrl/favorite';
    final body = jsonEncode({
      'customerCode': customerCode,
      'productCode': productCode,
    });
    debugPrint('📤 Đang gửi AddFavorite: URL=$url | Body=$body');
    final res = await http.post(
      Uri.parse(url),
      headers: headers(withAuth: true),
      body: body,
    );
    if (res.body.isEmpty) return; // 🔴 SỬA LỖI
    debugPrint('📥 Kết quả AddFavorite: ${res.body}');
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
  }


  static Future<void> removeFavorite(String customerCode, String productCode) async {
    final url = '$baseUrl/favorite/$customerCode/$productCode';
    debugPrint('📤 Đang gửi RemoveFavorite (Dùng POST): URL=$url');
    final res = await http.post(
      Uri.parse(url),
      headers: headers(withAuth: true),
    );
    if (res.body.isEmpty) return; // 🔴 SỬA LỖI
    debugPrint('📥 Kết quả RemoveFavorite: ${res.body}');
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
  }

  static Future<List<Product>> fetchProductsByCategory(String categoryCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/by-category/$categoryCode'),
      headers: headers(),
    );
    if (res.body.isEmpty) return []; // 🔴 SỬA LỖI: Thêm kiểm tra rỗng
    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded.containsKey('statusCode') && decoded['statusCode'] == 200) {
      final list = _unwrapList(decoded);
      return list.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi tải sản phẩm theo danh mục: ${decoded['message']}');
    }
  }

  static Future<List<Product>> fetchProductsByCategoryType(String categoryType) async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/by-category-type/$categoryType'),
      headers: headers(),
    );
    if (res.body.isEmpty) return []; // 🔴 SỬA LỖI: Thêm kiểm tra rỗng
    final decoded = jsonDecode(res.body);
    if (res.statusCode == 200) {
      if (decoded is Map && decoded.containsKey('statusCode') && decoded['statusCode'] != 200) {
        throw Exception('Lỗi: ${decoded['message']}');
      }
      final list = _unwrapList(decoded);
      return list.map((e) => Product.fromJson(e)).toList();
    }
    throw Exception('Lỗi tải sản phẩm theo loại: HTTP ${res.statusCode}');
  }


  // =========================================================
  // CART (GIỎ HÀNG)
  // =========================================================

  static Future<List<Map<String, dynamic>>> fetchCart(String customerCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/cart/$customerCode'),
      headers: headers(withAuth: true),
    );
    if (res.body.isEmpty) return []; // 🔴 SỬA LỖI: Thêm kiểm tra rỗng
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    final list = _unwrapList(decoded);
    return list.cast<Map<String, dynamic>>();
  }

  static Future<void> addCartItem(String customerCode, String productCode, int quantity) async {
    final url = '$baseUrl/cart';
    final body = jsonEncode({
      'customerCode': customerCode,
      'productCode': productCode,
      'quantity': quantity,
    });
    debugPrint('📤 Đang gửi AddCartItem: $body');
    final res = await http.post(
      Uri.parse(url),
      headers: headers(withAuth: true),
      body: body,
    );
    if (res.body.isEmpty) return; // 🔴 SỬA LỖI
    debugPrint('📥 Kết quả AddCartItem: ${res.body}');
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
  }

  static Future<void> updateCartQuantity(String customerCode, String productCode, int quantity) async {
    final url = '$baseUrl/cart/update-quantity';
    final body = jsonEncode({
      'customerCode': customerCode,
      'productCode': productCode,
      'quantity': quantity,
    });
    debugPrint('📤 Đang gửi UpdateQuantity: $body');
    final res = await http.post(
      Uri.parse(url),
      headers: headers(withAuth: true),
      body: body,
    );
    if (res.body.isEmpty) return; // 🔴 SỬA LỖI
    debugPrint('📥 Kết quả UpdateQuantity: ${res.body}');
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
  }

  static Future<void> removeCartItem(String customerCode, String productCode) async {
    final url = '$baseUrl/cart/$customerCode/$productCode';
    debugPrint('📤 Đang gửi RemoveCartItem (POST): $url');
    final res = await http.post(
      Uri.parse(url),
      headers: headers(withAuth: true),
    );
    if (res.body.isEmpty) return; // 🔴 SỬA LỖI
    debugPrint('📥 Kết quả RemoveCartItem: ${res.body}');
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
  }

  static Future<void> clearCartOnServer(String customerCode) async {
    final url = '$baseUrl/cart/delete-all/$customerCode';
    debugPrint('📤 Đang gửi ClearCart (POST): $url');
    final res = await http.post(
      Uri.parse(url),
      headers: headers(withAuth: true),
    );
    if (res.body.isEmpty) return; // 🔴 SỬA LỖI
    debugPrint('📥 Kết quả ClearCart: ${res.body}');
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
  }

  // =========================================================
  // 🔴 MỚI: ADDRESS (GHN) - API LẤY TỈNH/HUYỆN/XÃ
  // =========================================================

  /// Lấy danh sách Tỉnh/Thành phố
  static Future<List<Map<String, dynamic>>> fetchProvinces() async {
    try {
      final res = await http.get(
        Uri.parse('$_ghnBaseUrl/province'),
        headers: _ghnHeaders,
      );
      if (res.body.isEmpty) return []; // 🔴 SỬA LỖI
      final decoded = jsonDecode(res.body);
      if (decoded['code'] == 200) {
        // Trả về danh sách Tỉnh/Thành
        return (decoded['data'] as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception(decoded['message'] ?? 'Lỗi tải Tỉnh/Thành');
      }
    } catch (e) {
      print('Lỗi fetchProvinces: $e');
      throw Exception('Không thể tải danh sách Tỉnh/Thành');
    }
  }

  /// Lấy danh sách Quận/Huyện theo Tỉnh
  static Future<List<Map<String, dynamic>>> fetchDistricts(int provinceId) async {
    try {
      final res = await http.post(
        Uri.parse('$_ghnBaseUrl/district'),
        headers: _ghnHeaders,
        body: jsonEncode({'province_id': provinceId}),
      );
      if (res.body.isEmpty) return []; // 🔴 SỬA LỖI
      final decoded = jsonDecode(res.body);
      if (decoded['code'] == 200) {
        return (decoded['data'] as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception(decoded['message'] ?? 'Lỗi tải Quận/Huyện');
      }
    } catch (e) {
      print('Lỗi fetchDistricts: $e');
      throw Exception('Không thể tải danh sách Quận/Huyện');
    }
  }

  /// Lấy danh sách Phường/Xã theo Quận
  static Future<List<Map<String, dynamic>>> fetchWards(int districtId) async {
    try {
      final res = await http.post(
        Uri.parse('$_ghnBaseUrl/ward'),
        headers: _ghnHeaders,
        body: jsonEncode({'district_id': districtId}),
      );
      if (res.body.isEmpty) return []; // 🔴 SỬA LỖI
      final decoded = jsonDecode(res.body);
      if (decoded['code'] == 200) {
        return (decoded['data'] as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception(decoded['message'] ?? 'Lỗi tải Phường/Xã');
      }
    } catch (e) {
      print('Lỗi fetchWards: $e');
      throw Exception('Không thể tải danh sách Phường/Xã');
    }
  }

  // =========================================================
  // ORDERS (Giữ nguyên)
  // =========================================================
  static Future<void> createOrder({
    required String customerCode,
    required List<CartItem> cartItems,
    required String address,
    required String phoneNumber,
    required String paymentMethod,
    String? note,
  }) async {
    final List<Map<String, dynamic>> detailsList = cartItems.map((item) {
      return {
        'productCode': item.product.maSP,
        'quantity': item.quantity,
      };
    }).toList();
    final body = jsonEncode({
      'customerCode': customerCode,
      'address': address,
      'phoneNumber': phoneNumber,
      'paymentMethod': paymentMethod,
      'orderType': 'Online',
      'details': detailsList,
      'note': note ?? '',
    });
    final res = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: headers(withAuth: true),
      body: body,
    );
    if (res.body.isEmpty) return; // 🔴 SỬA LỖI
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
  }

  static Future<List<Order>> fetchMyOrders(String customerCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders/customer/$customerCode'),
      headers: headers(withAuth: true),
    );
    if (res.body.isEmpty) return []; // 🔴 ĐÃ SỬA
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    final List<dynamic> list = _unwrapList(decoded);
    return list.map((e) => Order.fromJson(e)).toList();
  }

  static Future<Order> fetchOrderDetails(String orderCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders/$orderCode'),
      headers: headers(withAuth: true),
    );
    if (res.body.isEmpty) throw Exception('Không tìm thấy đơn hàng'); // 🔴 SỬA LỖI
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    final orderData = decoded['data'] ?? decoded['payload'] ?? decoded;
    return Order.fromJson(orderData);
  }
}