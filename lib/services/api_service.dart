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

  // Tự động chọn localhost (iOS) hoặc 10.0.2.2 (Android Emulator)
  static String get _platformHost => Platform.isAndroid ? '10.0.2.2' : 'localhost';
  static String get _host => _overrideHost ?? _platformHost;
  static const int _port = 8080;
  static String get baseUrl => 'http://$_host:$_port/v1/api';

  // ===== Token =====
  static String? _token;
  static String? get token => _token;
  static void setToken(String? t) {
    _token = t;
    debugPrint('🔑 Token đã được lưu: ${_token != null ? "Có" : "Không"}');
  }
  static bool get hasToken => (_token ?? '').isNotEmpty;

  // ===== Headers =====
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

      debugPrint('Login Response: ${res.body}'); // 🟢 Xem log này để biết có accountCode ko
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
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    return _unwrapList(decoded).map((e) => ProductCategory.fromJson(e)).toList();
  }

  static Future<List<Product>> fetchAllProducts() async {
    final res = await http.get(Uri.parse('$baseUrl/products'), headers: headers());
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
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    return _unwrapList(decoded).map((e) => Product.fromJson(e)).toList();
  }

  static Future<Product> fetchProductByCode(String productCode) async {
    final res = await http.get(Uri.parse('$baseUrl/products/$productCode'), headers: headers());
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    final data = decoded['data'] ?? decoded['payload'] ?? decoded;
    return Product.fromJson(data);
  }

  // =========================================================
  // FAVORITES (ĐÃ SỬA LOG VÀ METHOD)
  // =========================================================
  static Future<List<Product>> fetchMyFavorites(String customerCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/favorite/$customerCode'),
      headers: headers(withAuth: true),
    );
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

    debugPrint('📤 Đang gửi AddFavorite: URL=$url | Body=$body'); // 🟢 SOI LOG NÀY

    final res = await http.post(
      Uri.parse(url),
      headers: headers(withAuth: true),
      body: body,
    );

    debugPrint('📥 Kết quả AddFavorite: ${res.body}');

    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
  }


  static Future<void> removeFavorite(String customerCode, String productCode) async {
    // 🔴 ĐỔI LẠI THÀNH POST (NHƯ GỐC CỦA BẠN)
    // Vì có thể Backend của bạn cấu hình xóa bằng POST

    final url = '$baseUrl/favorite/$customerCode/$productCode';
    debugPrint('📤 Đang gửi RemoveFavorite (Dùng POST): URL=$url');

    final res = await http.post( // ⬅️ Đã đổi lại thành POST
      Uri.parse(url),
      headers: headers(withAuth: true),
      // Không cần body vì 2 mã đã nằm trên URL
    );

    debugPrint('📥 Kết quả RemoveFavorite: ${res.body}');

    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded); // Hàm này sẽ ném lỗi nếu statusCode != 200/201
  }
  static Future<List<Product>> fetchProductsByCategory(String categoryCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/by-category/$categoryCode'),
      headers: headers(),
    );
    final decoded = jsonDecode(res.body);

    // Kiểm tra statusCode 200
    if (decoded is Map && decoded.containsKey('statusCode') && decoded['statusCode'] == 200) {
      final list = _unwrapList(decoded);
      return list.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi tải sản phẩm theo danh mục: ${decoded['message']}');
    }
  }


  // ... (Bên trong class ApiService)

  // Hàm lấy sản phẩm theo loại danh mục (Ví dụ: Sách, Văn phòng phẩm...)
  static Future<List<Product>> fetchProductsByCategoryType(String categoryType) async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/by-category-type/$categoryType'),
      headers: headers(),
    );
    final decoded = jsonDecode(res.body);

    if (res.statusCode == 200) {
      // Kiểm tra logic status code của backend
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

  /// Tải giỏ hàng của user
  // static Future<List<CartItem>> fetchCart(String customerCode) async {
  //   final res = await http.get(
  //     Uri.parse('$baseUrl/cart/$customerCode'),
  //     headers: headers(withAuth: true),
  //   );
  //   final decoded = jsonDecode(res.body);
  //   _checkResponseSuccess(decoded);
  //
  //   // API trả về CartItem DTO (có thể có product object bên trong)
  //   final list = _unwrapList(decoded);
  //   return list.map((e) => CartItem.fromJson(e)).toList();
  // }
  //
  // /// Thêm sản phẩm vào giỏ (hoặc cập nhật)
  // /// Backend dùng chung 1 DTO CartRequest cho 2 hàm
  // static Future<void> addCartItem(String customerCode, String productCode, int quantity) async {
  //   final url = '$baseUrl/cart';
  //   final body = jsonEncode({
  //     'customerCode': customerCode,
  //     'productCode': productCode,
  //     'quantity': quantity,
  //   });
  //
  //   debugPrint('📤 Đang gửi AddCartItem: $body');
  //
  //   final res = await http.post(
  //     Uri.parse(url),
  //     headers: headers(withAuth: true),
  //     body: body,
  //   );
  //
  //   debugPrint('📥 Kết quả AddCartItem: ${res.body}');
  //   final decoded = jsonDecode(res.body);
  //   _checkResponseSuccess(decoded);
  // }
  //
  // /// Cập nhật số lượng (theo API controller)
  // static Future<void> updateCartQuantity(String customerCode, String productCode, int quantity) async {
  //   final url = '$baseUrl/cart/update-quantity';
  //   final body = jsonEncode({
  //     'customerCode': customerCode,
  //     'productCode': productCode,
  //     'quantity': quantity,
  //   });
  //
  //   debugPrint('📤 Đang gửi UpdateQuantity: $body');
  //
  //   final res = await http.post(
  //     Uri.parse(url),
  //     headers: headers(withAuth: true),
  //     body: body,
  //   );
  //
  //   debugPrint('📥 Kết quả UpdateQuantity: ${res.body}');
  //   final decoded = jsonDecode(res.body);
  //   _checkResponseSuccess(decoded);
  // }
  //
  // /// Xóa 1 item khỏi giỏ
  // static Future<void> removeCartItem(String customerCode, String productCode) async {
  //   // API của bạn dùng POST để xóa, ta làm theo
  //   final url = '$baseUrl/cart/$customerCode/$productCode';
  //   debugPrint('📤 Đang gửi RemoveCartItem (POST): $url');
  //
  //   final res = await http.post(
  //     Uri.parse(url),
  //     headers: headers(withAuth: true),
  //   );
  //
  //   debugPrint('📥 Kết quả RemoveCartItem: ${res.body}');
  //   final decoded = jsonDecode(res.body);
  //   _checkResponseSuccess(decoded);
  // }
  //
  // /// Xóa toàn bộ giỏ hàng (khi thanh toán xong)
  // static Future<void> clearCartOnServer(String customerCode) async {
  //   final url = '$baseUrl/cart/delete-all/$customerCode';
  //   debugPrint('📤 Đang gửi ClearCart (POST): $url');
  //
  //   final res = await http.post(
  //     Uri.parse(url),
  //     headers: headers(withAuth: true),
  //   );
  //   debugPrint('📥 Kết quả ClearCart: ${res.body}');
  //   final decoded = jsonDecode(res.body);
  //   _checkResponseSuccess(decoded);
  // }



  // ===== ORDERS =====
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
      headers: headers(withAuth: true), // ⬅️ Sửa
      body: body,
    );

    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded.containsKey('statusCode') && (decoded['statusCode'] == 200 || decoded['statusCode'] == 201)) {
      return;
    } else {
      final message = decoded['message'] ?? 'Lỗi không xác định';
      throw Exception('Lỗi tạo đơn hàng: $message');
    }
  }

  static Future<List<Order>> fetchMyOrders(String customerCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders/customer/$customerCode'),
      headers: headers(withAuth: true), // ⬅️ Sửa
    );
    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded.containsKey('statusCode') && decoded['statusCode'] == 200) {
      final List<dynamic> list = _unwrapList(decoded);
      return list.map((e) => Order.fromJson(e)).toList();
    } else {
      final message = decoded['message'] ?? 'Lỗi không xác định';
      throw Exception('Lỗi tải đơn hàng: $message');
    }
  }

  static Future<Order> fetchOrderDetails(String orderCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders/$orderCode'),
      headers: headers(withAuth: true), // ⬅️ Sửa
    );
    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded.containsKey('statusCode') && decoded['statusCode'] == 200) {
      final orderData = decoded['data'] ?? decoded['payload'] ?? decoded;
      return Order.fromJson(orderData);
    } else {
      final message = decoded['message'] ?? 'Lỗi không xác định';
      throw Exception('Lỗi tải chi tiết đơn hàng: $message');
    }
  }
}