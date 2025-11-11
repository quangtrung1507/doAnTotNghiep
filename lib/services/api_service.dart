import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/san_pham.dart';
import '../models/loai_san_pham.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/v1/api';

  // --- CÁC PHƯƠNG THỨC XÁC THỰC (GIỮ NGUYÊN) ---

  static Future<Map<String, dynamic>?> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      final data = json.decode(response.body); // Decode body dù thành công hay thất bại
      print("Login API Raw Response: $data (Status: ${response.statusCode})"); // In toàn bộ phản hồi

      if (response.statusCode == 200) {
        // Trả về toàn bộ data của response
        return data;
      } else {
        print("Login failed: ${response.statusCode} - ${response.body}");
        return data; // Vẫn trả về data để AuthProvider có thể đọc message lỗi nếu có
      }
    } catch (e) {
      print("Error during login: $e");
      return null;
    }
  }

  static Future<String?> register(String username, String password, String email) async {
    final url = Uri.parse('$baseUrl/account/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'email': email,
        }),
      );

      final responseBody = json.decode(response.body); // Decode body để lấy thông báo lỗi

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Registration successful: ${response.body}");
        return null; // Đăng ký thành công, không có lỗi
      } else {
        final errorMessage = responseBody['message'] ?? 'Đăng ký thất bại không rõ nguyên nhân.';
        print("Registration failed: ${response.statusCode} - $errorMessage");
        return errorMessage; // Trả về thông báo lỗi từ API
      }
    } catch (e) {
      print("Error during registration: $e");
      return "Lỗi kết nối hoặc xử lý: $e"; // Lỗi ngoại lệ
    }
  }

  // --- CÁC PHƯƠNG THỨC LẤY DỮ LIỆU SẢN PHẨM ---

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

  // *** GIỮ HÀM NÀY (1 THAM SỐ) ***
  static Future<List<SanPham>> fetchProductsByCategory(String categoryCode) async {
    final url = Uri.parse('$baseUrl/products/by-category/$categoryCode');
    try {
      final response = await http.get(url); // Dùng http.get

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('data')) {
          final List<dynamic> data = decoded['data'];
          if (data.isEmpty) {
            return [];
          }
          return data.map((e) => SanPham.fromJson(e)).toList();
        } else {
          throw Exception('⚠️ Dữ liệu không hợp lệ: Thiếu key "data"');
        }
      } else {
        throw Exception('❌ Lỗi khi tải sản phẩm theo loại: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetchProductsByCategory: $e");
      throw Exception('Lỗi kết nối hoặc xử lý: $e');
    }
  }


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

  // --- CÁC PHƯƠNG THỨC LẤY DỮ LIỆU DANH MỤC ---

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

  // *** ĐÃ XÓA HÀM fetchCategoriesByMain (gây lỗi 404) ***


  // --- CÁC PHƯƠNG THỨC KHÁC (GIỮ NGUYÊN) ---

  static Future<List<SanPham>> fetchFavoriteProducts() async => [];
  static Future<void> addFavorite(String productCode) async {}
  static Future<void> removeFavorite(String productCode) async {}

  static Future<http.Response> getAuthenticated(String path, String? token) async {
    final url = Uri.parse('$baseUrl/$path');
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  static Future<http.Response> postAuthenticated(String path, Object body, String? token) async {
    final url = Uri.parse('$baseUrl/$path');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );
  }

  static Future<http.Response> putAuthenticated(String path, Object body, String? token) async {
    final url = Uri.parse('$baseUrl/$path');
    return await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );
  }

  static Future<http.Response> deleteAuthenticated(String path, String? token) async {
    final url = Uri.parse('$baseUrl/$path');
    return await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }
}