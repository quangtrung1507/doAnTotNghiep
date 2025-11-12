// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/san_pham.dart';
import '../models/loai_san_pham.dart';

class ApiService {
  // ===== Host =====
  static String? _overrideHost;
  static void setHost(String host) => _overrideHost = host;
  static String get _platformHost => Platform.isAndroid ? '10.0.2.2' : 'localhost';
  static String get _host => _overrideHost ?? _platformHost;
  static const int _port = 8080;
  static String get baseUrl => 'http://$_host:$_port/v1/api';

  // ===== Token =====
  static String? _token;
  static void setToken(String? t) => _token = t;
  static bool get hasToken => (_token ?? '').isNotEmpty;

  static Map<String, String> _headers({bool jsonBody = true, bool withAuth = false}) {
    final h = <String, String>{};
    if (jsonBody) h['Content-Type'] = 'application/json';
    if (withAuth && hasToken) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  // ===== Helpers =====
  static List<dynamic> _unwrapList(dynamic decoded, {String key = 'data'}) {
    if (decoded is Map && decoded.containsKey(key)) return decoded[key] as List<dynamic>;
    if (decoded is List) return decoded;
    throw Exception('⚠️ Dữ liệu không hợp lệ');
  }

  // ===== AUTH =====

  /// Login – trả về map response từ server. Đồng thời lưu token nếu có.
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(),
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(res.body);

    // token có thể nằm ở data.accessToken (giống Postman)
    final token = (data['accessToken'] ??
        data['token'] ??
        (data is Map && data['data'] is Map ? data['data']['accessToken'] : null)) as String?;
    if (res.statusCode == 200 && token != null && token.isNotEmpty) {
      setToken(token);
    }
    return data;
  }

  /// Register – trả về null nếu thành công; ngược lại trả về chuỗi lỗi.
  static Future<String?> register(String username, String password, String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/account/register'),
        headers: _headers(),
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
        }),
      );

      // Thành công thường là 200/201
      if (res.statusCode == 200 || res.statusCode == 201) {
        return null;
      }

      // Thất bại: cố gắng lấy message từ JSON, nếu không có thì trả thô
      try {
        final body = jsonDecode(res.body);
        final msg = (body['message'] ?? body['error'] ?? res.reasonPhrase)?.toString();
        return msg ?? 'Đăng ký thất bại (HTTP ${res.statusCode}).';
      } catch (_) {
        return 'Đăng ký thất bại (HTTP ${res.statusCode}): ${res.body}';
      }
    } catch (e) {
      return 'Lỗi kết nối/ xử lý: $e';
    }
  }

  // ===== CATEGORIES =====
  static Future<List<LoaiSanPham>> fetchAllCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/categories'), headers: _headers());
    if (res.statusCode == 200) {
      final list = _unwrapList(jsonDecode(res.body));
      return list.map((e) => LoaiSanPham.fromJson(e)).toList();
    }
    throw Exception('HTTP ${res.statusCode} @ /categories');
  }

  static Future<List<LoaiSanPham>> fetchCategoriesByMainViaServer(String mainCode) async {
    final res = await http.get(Uri.parse('$baseUrl/categories/by-main/$mainCode'), headers: _headers());
    if (res.statusCode == 200) {
      final list = _unwrapList(jsonDecode(res.body));
      return list.map((e) => LoaiSanPham.fromJson(e)).toList();
    }
    throw Exception('HTTP ${res.statusCode} @ /categories/by-main/$mainCode');
  }

  // ===== PRODUCTS =====
  static Future<List<SanPham>> fetchAllProducts({bool public = false}) async {
    final res = await http.get(Uri.parse('$baseUrl/products'), headers: _headers(withAuth: false));
    if (res.statusCode == 200) {
      final list = _unwrapList(jsonDecode(res.body));
      return list.map((e) => SanPham.fromJson(e)).toList();
    }
    throw Exception('HTTP ${res.statusCode} @ /products');
  }

  static Future<List<SanPham>> searchProducts(String query, {bool public = false}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/search?q=${Uri.encodeQueryComponent(query)}'),
      headers: _headers(withAuth: false),
    );
    if (res.statusCode == 200) {
      final list = _unwrapList(jsonDecode(res.body));
      return list.map((e) => SanPham.fromJson(e)).toList();
    }
    throw Exception('HTTP ${res.statusCode} @ /products/search');
  }

  static Future<List<SanPham>> fetchProductsByCategory(String categoryCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/by-category/$categoryCode'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      final list = _unwrapList(jsonDecode(res.body));
      return list.map((e) => SanPham.fromJson(e)).toList();
    }
    throw Exception('HTTP ${res.statusCode} @ /products/by-category/$categoryCode');
  }

  static Future<List<SanPham>> fetchProductsByMain(String mainCode, {bool public = false}) async {
    // ⚠ /categories/by-main/{main} của bạn trả JSON đệ quy → KHÔNG dùng để lấy sản phẩm.
    // Thay vào đó: lấy toàn bộ categories rồi map từ mainCode sang các categoryCode cần, sau đó gọi by-category.
    final allCats = await fetchAllCategories();

    List<String> codes;
    switch (mainCode.toUpperCase()) {
      case 'SACH':
        codes = _pick(allCats, [
          'Romance','Horror','Fantasy','Business','Drama',
          'Biography','Cook','Poetry','Art','Architecture'
        ]);
        break;
      case 'DOCHOI':
        codes = _pick(allCats, ['Modelkit','Figure']);
        break;
      case 'LUUNIEM':
        codes = _pick(allCats, ['Watch','Gift']);
        break;
      case 'MANGA':
        codes = _pick(allCats, ['Manga']);
        break;
      case 'VPP':
        codes = _pick(allCats, [
          'Calculator','Note','Pen','Draw','Studentbook','Compa','Pencil','Eraser','PencilEraser'
        ]);
        break;
      default:
        codes = allCats.map((e) => e.maLSP).toList();
    }

    if (codes.isEmpty) return [];

    final lists = await Future.wait(codes.map(fetchProductsByCategory));
    final map = <String, SanPham>{};
    for (final l in lists) {
      for (final p in l) {
        map[p.maSP] = p;
      }
    }
    return map.values.toList();
  }

  static List<String> _pick(List<LoaiSanPham> all, List<String> names) {
    final lower = names.map((e) => e.toLowerCase()).toList();
    return all
        .where((c) => lower.any((k) => c.tenLSP.toLowerCase().contains(k)))
        .map((c) => c.maLSP)
        .toList();
  }

  static Future<SanPham> fetchProductByCode(String productCode) async {
    final res = await http.get(Uri.parse('$baseUrl/products/$productCode'), headers: _headers());
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded.containsKey('data')) {
        return SanPham.fromJson(decoded['data']);
      }
      return SanPham.fromJson(decoded);
    }
    throw Exception('HTTP ${res.statusCode} @ /products/$productCode');
  }
}
