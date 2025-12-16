// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/product_category.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../models/promotion_model.dart';
import '../models/coupon_model.dart';


class ApiService {
  // ===== Cấu hình Host =====
  static String? _overrideHost;
  static void setHost(String host) => _overrideHost = host;

  static String get _platformHost =>
      Platform.isAndroid ? '10.0.2.2' : 'localhost';
  static String get _host => _overrideHost ?? _platformHost;
  static const int _port = 8080;
  static String get baseUrl => 'http://$_host:$_port/v1/api';

  // ===== GHN =====
  static const String _ghnBaseUrl =
      'https://online-gateway.ghn.vn/shiip/public-api/master-data';
  static const String _ghnToken = '732e3629-c1d9-11f0-a09b-aec1ea660f5d';
  static Map<String, String> get _ghnHeaders => {
    'Content-Type': 'application/json',
    'Token': _ghnToken,
  };

  // ===== Token app =====
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
    if (withAuth && hasToken) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  // ===== Helpers =====
  static List<dynamic> _unwrapList(dynamic decoded) {
    if (decoded is Map) {
      final list = decoded['data'] ?? decoded['payload'];
      if (list is List) return list;
    }
    if (decoded is List) return decoded;
    return [];
  }

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
  static Future<Map<String, dynamic>?> login(
      String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers(),
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (res.body.isEmpty) throw Exception('Auth response body rỗng');
      final data = jsonDecode(res.body);
      _checkResponseSuccess(data);

      final token = (data['accessToken'] ??
          data['token'] ??
          (data is Map && data['data'] is Map
              ? data['data']['accessToken']
              : null))
      as String?;
      if (token != null && token.isNotEmpty) {
        setToken(token);
      }
      return data;
    } catch (e) {
      debugPrint('Lỗi Login: $e');
      return null;
    }
  }

  static Future<String?> register(
      String username, String password, String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/account/register'),
        headers: headers(),
        body: jsonEncode(
            {'username': username, 'password': password, 'email': email}),
      );
      if (res.body.isEmpty) return "Lỗi đăng ký (body rỗng)";
      final decoded = jsonDecode(res.body);
      _checkResponseSuccess(decoded);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  // =========================================================
  // PRODUCTS & CATEGORIES
  // =========================================================
  static Future<List<ProductCategory>> fetchAllCategories() async {
    final res =
    await http.get(Uri.parse('$baseUrl/categories'), headers: headers());
    if (res.body.isEmpty) return [];
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    return _unwrapList(decoded).map((e) => ProductCategory.fromJson(e)).toList();
  }

  static Future<List<Product>> fetchAllProducts() async {
    final res =
    await http.get(Uri.parse('$baseUrl/products'), headers: headers());
    if (res.body.isEmpty) return [];
    final decoded = jsonDecode(res.body);
    if (res.statusCode == 200) {
      _checkResponseSuccess(decoded);
      return _unwrapList(decoded).map((e) => Product.fromJson(e)).toList();
    }
    throw Exception('HTTP Error ${res.statusCode}');
  }

  static Future<List<Product>> searchProducts(String query) async {
    final res = await http.get(
      Uri.parse(
          '$baseUrl/products/search?q=${Uri.encodeQueryComponent(query)}'),
      headers: headers(),
    );
    if (res.body.isEmpty) return [];
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    return _unwrapList(decoded).map((e) => Product.fromJson(e)).toList();
  }

  static Future<Product> fetchProductByCode(String productCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/$productCode'),
      headers: headers(),
    );
    if (res.body.isEmpty) {
      throw Exception('Không tìm thấy sản phẩm $productCode');
    }
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    final data = decoded['data'] ?? decoded['payload'] ?? decoded;
    return Product.fromJson(Map<String, dynamic>.from(data));
  }

  // =========================================================
  // FAVORITES
  // =========================================================
  static Future<List<Product>> fetchMyFavorites(String customerCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/favorite/$customerCode'),
      headers: headers(withAuth: true),
    );
    if (res.body.isEmpty) return [];
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    return _unwrapList(decoded).map((e) => Product.fromJson(e)).toList();
  }

  static Future<void> addFavorite(
      String customerCode, String productCode) async {
    final url = '$baseUrl/favorite';
    final body = jsonEncode(
        {'customerCode': customerCode, 'productCode': productCode});
    final res = await http.post(Uri.parse(url),
        headers: headers(withAuth: true), body: body);
    if (res.body.isEmpty) return;
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
  }

  static Future<void> removeFavorite(
      String customerCode, String productCode) async {
    final url = '$baseUrl/favorite/$customerCode/$productCode';
    final res =
    await http.post(Uri.parse(url), headers: headers(withAuth: true));
    if (res.body.isEmpty) return;
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
  }

  static Future<List<Product>> fetchProductsByCategory(
      String categoryCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/by-category/$categoryCode'),
      headers: headers(),
    );
    if (res.body.isEmpty) return [];
    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded['statusCode'] == 200) {
      final list = _unwrapList(decoded);
      return list.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi tải sản phẩm theo danh mục: ${decoded['message']}');
    }
  }

  static Future<List<Product>> fetchProductsByCategoryType(
      String categoryType) async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/by-category-type/$categoryType'),
      headers: headers(),
    );
    if (res.body.isEmpty) return [];
    final decoded = jsonDecode(res.body);
    if (res.statusCode == 200) {
      if (decoded is Map &&
          decoded.containsKey('statusCode') &&
          decoded['statusCode'] != 200) {
        throw Exception('Lỗi: ${decoded['message']}');
      }
      final list = _unwrapList(decoded);
      return list.map((e) => Product.fromJson(e)).toList();
    }
    throw Exception('Lỗi tải sản phẩm theo loại: HTTP ${res.statusCode}');
  }

  // =========================================================
  // CART
  // =========================================================
  static Future<List<Map<String, dynamic>>> fetchCart(
      String customerCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/cart/$customerCode'),
      headers: headers(withAuth: true),
    );
    if (res.body.isEmpty) return [];
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    final list = _unwrapList(decoded);
    return list.cast<Map<String, dynamic>>();
  }

  static Future<void> addCartItem(
      String customerCode, String productCode, int quantity) async {
    final url = '$baseUrl/cart';
    final body = jsonEncode({
      'customerCode': customerCode,
      'productCode': productCode,
      'quantity': quantity
    });
    final res = await http.post(Uri.parse(url),
        headers: headers(withAuth: true), body: body);
    if (res.body.isEmpty) return;
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
  }

  static Future<void> updateCartQuantity(
      String customerCode, String productCode, int quantity) async {
    final url = '$baseUrl/cart/update-quantity';
    final body = jsonEncode({
      'customerCode': customerCode,
      'productCode': productCode,
      'quantity': quantity
    });
    final res = await http.post(Uri.parse(url),
        headers: headers(withAuth: true), body: body);
    if (res.body.isEmpty) return;
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
  }

  static Future<void> removeCartItem(
      String customerCode, String productCode) async {
    final url = '$baseUrl/cart/$customerCode/$productCode';
    final res =
    await http.post(Uri.parse(url), headers: headers(withAuth: true));
    if (res.body.isEmpty) return;
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
  }

  static Future<void> clearCartOnServer(String customerCode) async {
    final url = '$baseUrl/cart/delete-all/$customerCode';
    final res =
    await http.post(Uri.parse(url), headers: headers(withAuth: true));
    if (res.body.isEmpty) return;
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
  }

  // =========================================================
  // GHN
  // =========================================================
  static Future<List<Map<String, dynamic>>> fetchProvinces() async {
    try {
      final res =
      await http.get(Uri.parse('$_ghnBaseUrl/province'), headers: _ghnHeaders);
      if (res.body.isEmpty) return [];
      final decoded = jsonDecode(res.body);
      if (decoded['code'] == 200) {
        return (decoded['data'] as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception(decoded['message'] ?? 'Lỗi tải Tỉnh/Thành');
      }
    } catch (e) {
      throw Exception('Không thể tải danh sách Tỉnh/Thành');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchDistricts(int provinceId) async {
    try {
      final res = await http.post(
        Uri.parse('$_ghnBaseUrl/district'),
        headers: _ghnHeaders,
        body: jsonEncode({'province_id': provinceId}),
      );
      if (res.body.isEmpty) return [];
      final decoded = jsonDecode(res.body);
      if (decoded['code'] == 200) {
        return (decoded['data'] as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception(decoded['message'] ?? 'Lỗi tải Quận/Huyện');
      }
    } catch (e) {
      throw Exception('Không thể tải danh sách Quận/Huyện');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchWards(int districtId) async {
    try {
      final res = await http.post(
        Uri.parse('$_ghnBaseUrl/ward'),
        headers: _ghnHeaders,
        body: jsonEncode({'district_id': districtId}),
      );
      if (res.body.isEmpty) return [];
      final decoded = jsonDecode(res.body);
      if (decoded['code'] == 200) {
        return (decoded['data'] as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception(decoded['message'] ?? 'Lỗi tải Phường/Xã');
      }
    } catch (e) {
      throw Exception('Không thể tải danh sách Phường/Xã');
    }
  }

  // =========================================================
  // ORDERS
  // =========================================================

  /// ✅ Tạo đơn và trả về mã đơn (orderCode)
  /// ✅ Tạo đơn và trả về mã đơn (orderCode)
  /// ✅ MOBILE: chỉ dùng COUPON, không dùng PROMOTION
  static Future<String> createOrder({
    required String customerCode,
    required List<CartItem> cartItems,
    required String address,
    required String phoneNumber,
    required String paymentMethod, // 'Cash' | 'QR'
    String? note,

    // ✅ Coupon
    String? couponCode,              // VD: SALE50, G50K
    double? couponDiscountValue,     // VD: 0.5 hoặc 50000
  }) async {
    final detailsList = cartItems.map((item) {
      return {
        'productCode': item.product.maSP,
        'quantity': item.quantity,
      };
    }).toList();

    // ✅ QUAN TRỌNG: promotionCustomerCode/Value LUÔN NULL để không dính FK promotion
    final Map<String, dynamic> bodyMap = {
      'customerCode': customerCode,
      'employeeCode': null,

      'promotionCustomerCode': null,
      'promotionCustomerValue': null,

      'couponCode': (couponCode != null && couponCode.trim().isNotEmpty)
          ? couponCode.trim()
          : null,
      'couponDiscountValue': couponDiscountValue,

      'orderType': 'Online',
      'paymentMethod': paymentMethod, // 'Cash' hoặc 'QR'
      'orderStatus': null,
      'discount': null,
      'note': (note ?? '').trim(),
      'address': address,
      'phoneNumber': phoneNumber,
      'details': detailsList,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: headers(withAuth: true),
      body: jsonEncode(bodyMap),
    );

    if (res.body.isEmpty) {
      throw Exception('Tạo đơn thất bại: phản hồi rỗng từ server');
    }

    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);

    final data = decoded['data'] ?? decoded['payload'] ?? decoded;

    final dynamic oc = (data is Map)
        ? (data['orderCode'] ?? data['code'] ?? data['order_code'])
        : null;

    if (oc is String && oc.isNotEmpty) return oc;
    if (data is Map && data['id'] != null) return data['id'].toString();

    throw Exception('Tạo đơn thành công nhưng không nhận được mã đơn hàng.');
  }


  /// ✅ Lấy chi tiết đơn (header + details) và ENRICH tên/ảnh/đơn giá
  static Future<Order> fetchOrderDetails(String orderCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders/$orderCode'),
      headers: headers(withAuth: true),
    );

    if (res.body.isEmpty) {
      throw Exception('Không tìm thấy đơn $orderCode');
    }

    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);

    final headerMap = Map<String, dynamic>.from(
      (decoded['data'] ?? decoded['payload'] ?? decoded) as Map,
    );

    var order = Order.fromJson(headerMap);
    var details = order.details;

    final needCodes = details
        .where((d) =>
    d.productName.isEmpty || d.imageUrl.isEmpty || d.price <= 0)
        .map((d) => d.productCode)
        .toSet()
        .toList();

    final Map<String, Product> cache = {};
    for (final code in needCodes) {
      try {
        cache[code] = await fetchProductByCode(code);
      } catch (_) {
        // bỏ qua nếu lỗi 1 sản phẩm
      }
    }

    details = details.map((d) {
      final p = cache[d.productCode];
      if (p == null) return d;
      return d.copyWith(
        productName: d.productName.isEmpty ? p.tenSP : d.productName,
        imageUrl: d.imageUrl.isEmpty ? p.hinhAnh : d.imageUrl,
        price: (d.price > 0) ? d.price : p.gia,
      );
    }).toList();

    return order.copyWith(details: details);
  }

  /// Danh sách đơn của tôi
  static Future<List<Order>> fetchMyOrders(String customerCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders/customer/$customerCode'),
      headers: headers(withAuth: true),
    );
    if (res.body.isEmpty) return [];
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    final List<dynamic> list = _unwrapList(decoded);
    return list.whereType<Map<String, dynamic>>().map(Order.fromJson).toList();
  }

  /// ✅ Danh sách tất cả đơn (admin) + enrich chi tiết
  static Future<List<Order>> fetchAllOrders() async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: headers(withAuth: true),
    );
    if (res.body.isEmpty) return [];
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);
    final List<dynamic> list = _unwrapList(decoded);

    final rawOrders =
    list.whereType<Map<String, dynamic>>().map(Order.fromJson).toList();

    final futures = rawOrders.map((o) async {
      try {
        return await fetchOrderDetails(o.orderCode);
      } catch (_) {
        return o;
      }
    }).toList();

    return Future.wait(futures);
  }

  /// 🔴 HỦY ĐƠN HÀNG (soft delete trên backend)
  static Future<void> cancelOrder(String orderCode) async {
    final url = Uri.parse('$baseUrl/orders/$orderCode');
    final resp = await http.post(
      url,
      headers: headers(withAuth: true),
    );

    if (resp.body.isEmpty) {
      throw Exception('Không thể hủy đơn hàng (phản hồi rỗng từ server)');
    }

    final decoded = jsonDecode(resp.body);
    _checkResponseSuccess(decoded);
    // nếu muốn hiện message cụ thể có thể return decoded['message']
  }



  // ================== VOUCHER (PROMOTION + COUPON) ==================

  /// Lấy tất cả promotion (VIP) còn hiệu lực (status = true)
  static Future<List<PromotionModel>> fetchPromotions() async {
    final uri = Uri.parse('$baseUrl/promotions');

    // ✅ Gửi kèm Authorization: Bearer <token>
    final res = await http.get(
      uri,
      headers: headers(withAuth: true),
    );

    if (res.body.isEmpty) {
      throw Exception('Lỗi gọi API promotions: body rỗng');
    }

    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);

    final list = _unwrapList(decoded)
        .map((e) => PromotionModel.fromJson(e))
        .where((p) => p.status == true)
        .toList();

    return list;
  }

  /// Lấy tất cả coupon còn hiệu lực (status = true)
  static Future<List<CouponModel>> fetchCoupons() async {
    final uri = Uri.parse('$baseUrl/coupons');

    // ✅ Gửi kèm Authorization: Bearer <token>
    final res = await http.get(
      uri,
      headers: headers(withAuth: true),
    );

    if (res.body.isEmpty) {
      throw Exception('Lỗi gọi API coupons: body rỗng');
    }

    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);

    final list = _unwrapList(decoded)
        .map((e) => CouponModel.fromJson(e))
        .where((c) => c.status == true)
        .toList();

    return list;
  }

  static Future<List<Map<String, dynamic>>> fetchTransfersByOrder(String orderCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders/$orderCode/transfers'),
      headers: headers(withAuth: true),
    );

    if (res.body.isEmpty) return [];
    final decoded = jsonDecode(res.body);
    _checkResponseSuccess(decoded);

    final list = _unwrapList(decoded);
    return list.whereType<Map<String, dynamic>>().toList();
  }


}
