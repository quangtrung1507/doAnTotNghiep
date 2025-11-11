import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/san_pham.dart';
import '../models/loai_san_pham.dart'; // ✅ thêm import model danh mục

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/v1/api';

  // ✅ Lấy danh sách tất cả sản phẩm
  static Future<List<SanPham>> fetchAllProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      List<dynamic> data;
      if (decoded is Map && decoded.containsKey('data')) {
        data = decoded['data'];
      } else if (decoded is List) {
        data = decoded;
      } else {
        throw Exception('⚠️ Dữ liệu không hợp lệ: ${response.body}');
      }

      return data.map((e) => SanPham.fromJson(e)).toList();
    } else {
      throw Exception('❌ Lỗi khi tải danh sách sản phẩm: ${response.statusCode}');
    }
  }

  // ✅ Lấy sản phẩm theo mã loại (Category)
  static Future<List<SanPham>> fetchProductsByCategory(String categoryCode) async {
    final response = await http.get(Uri.parse('$baseUrl/products/category/$categoryCode'));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      List<dynamic> data;
      if (decoded is Map && decoded.containsKey('data')) {
        data = decoded['data'];
      } else if (decoded is List) {
        data = decoded;
      } else {
        throw Exception('⚠️ Dữ liệu không hợp lệ: ${response.body}');
      }

      return data.map((e) => SanPham.fromJson(e)).toList();
    } else {
      throw Exception('❌ Lỗi khi tải sản phẩm theo loại: ${response.statusCode}');
    }
  }

  // ✅ Lấy chi tiết 1 sản phẩm (tuỳ mã)
  static Future<SanPham> fetchProductByCode(String productCode) async {
    final response = await http.get(Uri.parse('$baseUrl/products/$productCode'));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map && decoded.containsKey('data')) {
        return SanPham.fromJson(decoded['data']);
      }

      return SanPham.fromJson(decoded);
    } else {
      throw Exception('❌ Lỗi khi tải sản phẩm: ${response.statusCode}');
    }
  }

  // ✅ Lấy danh sách tất cả loại sản phẩm (Category)
  static Future<List<LoaiSanPham>> fetchAllCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/product-categories'));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      List<dynamic> data;
      if (decoded is Map && decoded.containsKey('data')) {
        data = decoded['data'];
      } else if (decoded is List) {
        data = decoded;
      } else {
        throw Exception('⚠️ Dữ liệu danh mục không hợp lệ: ${response.body}');
      }

      return data.map((e) => LoaiSanPham.fromJson(e)).toList();
    } else {
      throw Exception('❌ Lỗi khi tải danh mục: ${response.statusCode}');
    }
  }

  // ✅ (Tạm thời tắt yêu thích vì chưa cần)
  static Future<List<SanPham>> fetchFavoriteProducts() async => [];
  static Future<void> addFavorite(String productCode) async {}
  static Future<void> removeFavorite(String productCode) async {}
}
