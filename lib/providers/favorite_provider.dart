// lib/providers/favorite_provider.dart
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'dart:async';

class FavoriteProvider with ChangeNotifier {
  final List<Product> _favoriteProducts = [];
  bool _isLoading = false;
  bool _isAuthenticated = false;

  List<Product> get favoriteProducts => [..._favoriteProducts];
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  void updateAuth(bool isAuthenticated) {
    _isAuthenticated = isAuthenticated;
  }

  void clearFavorites() {
    _favoriteProducts.clear();
    notifyListeners();
  }

  // Kiểm tra xem sản phẩm có trong danh sách không
  bool isFavorite(String productId) {
    return _favoriteProducts.any((product) => product.maSP == productId);
  }

  // -----------------------------------------------------------------
  // 🔴 HÀM ĐÃ SỬA: Tải danh sách yêu thích (Và lấy giá đầy đủ)
  // -----------------------------------------------------------------
  Future<void> fetchFavorites(String customerCode) async {
    if (customerCode.isEmpty) {
      print('⚠️ FetchFavorites bị hủy: CustomerCode rỗng');
      return;
    }
    _isLoading = true;
    notifyListeners();

    try {
      // BƯỚC 1: Lấy danh sách TẤT CẢ sản phẩm (để có giá)
      // (Chúng ta giả định ApiService.fetchAllProducts() trả về sản phẩm CÓ giá)
      final allProductsList = await ApiService.fetchAllProducts();

      // Chuyển sang Map để tra cứu nhanh bằng mã SP
      final Map<String, Product> allProductsMap = {
        for (var product in allProductsList) product.maSP: product
      };

      // BƯỚC 2: Lấy danh sách ID YÊU THÍCH (có thể bị thiếu giá)
      final serverFavoritesSummaries = await ApiService.fetchMyFavorites(customerCode);

      // BƯỚC 3: Gộp 2 danh sách lại
      final List<Product> fullFavoriteProducts = [];

      for (var favSummary in serverFavoritesSummaries) {
        // Tìm sản phẩm đầy đủ (có giá) trong Map
        final fullProduct = allProductsMap[favSummary.maSP];

        if (fullProduct != null) {
          // Nếu tìm thấy, thêm sản phẩm CÓ GIÁ vào danh sách
          fullFavoriteProducts.add(fullProduct);
        } else {
          // Nếu không tìm thấy (hiếm khi xảy ra), dùng tạm data tóm tắt (sẽ bị 0 đ)
          // Có thể sản phẩm này đã bị xóa khỏi shop
          print('⚠️ Không tìm thấy chi tiết của sản phẩm yêu thích: ${favSummary.maSP}');
          fullFavoriteProducts.add(favSummary);
        }
      }

      // BƯỚC 4: Cập nhật UI với danh sách đã có giá
      _favoriteProducts.clear();
      _favoriteProducts.addAll(fullFavoriteProducts);

      print('✅ Đã tải ${fullFavoriteProducts.length} sản phẩm yêu thích (có giá).');
    } catch (e) {
      print('❌ Lỗi fetchFavorites (đã sửa): $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -----------------------------------------------------------------
  // HÀM TOGGLE (Giữ nguyên, không thay đổi)
  // -----------------------------------------------------------------
  Future<void> toggleFavorite(Product product, String? customerCode) async {
    final String maSP = product.maSP;
    final bool isCurrentlyFavorite = isFavorite(maSP);

    // 1. Cập nhật UI ngay lập tức (Optimistic UI)
    if (isCurrentlyFavorite) {
      _favoriteProducts.removeWhere((p) => p.maSP == maSP);
    } else {
      _favoriteProducts.add(product);
    }
    notifyListeners();

    // 2. Kiểm tra điều kiện để gọi API
    final token = ApiService.token;

    print('--- TOGGLE FAVORITE ---');
    print('Product: $maSP');
    print('CustomerCode (từ Auth): $customerCode');
    print('Token Valid: ${token != null}');

    if (_isAuthenticated && token != null && customerCode != null && customerCode.isNotEmpty) {
      try {
        if (isCurrentlyFavorite) {
          await ApiService.removeFavorite(customerCode, maSP);
          print('✅ API: Đã xóa $maSP thành công');
        } else {
          await ApiService.addFavorite(customerCode, maSP);
          print('✅ API: Đã thêm $maSP thành công');
        }
      } catch (e) {
        // 3. Nếu lỗi API -> Hoàn tác UI (Rollback)
        print('❌ Lỗi API Yêu thích: $e');
        print('🔄 Đang hoàn tác UI...');

        if (isCurrentlyFavorite) {
          _favoriteProducts.add(product);
        } else {
          _favoriteProducts.removeWhere((p) => p.maSP == maSP);
        }
        notifyListeners();
      }
    } else {
      print('⚠️ Không gọi API: Thiếu thông tin Auth hoặc CustomerCode');
    }
  }
}