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

  // Tải danh sách yêu thích từ server
  Future<void> fetchFavorites(String customerCode) async {
    if (customerCode.isEmpty) {
      print('⚠️ FetchFavorites bị hủy: CustomerCode rỗng');
      return;
    }
    _isLoading = true;
    notifyListeners();

    try {
      final serverFavorites = await ApiService.fetchMyFavorites(customerCode);

      // Merge logic: Ưu tiên server, nhưng giữ lại cái mới add ở local nếu có
      // (Ở đây tôi làm đơn giản là lấy server đè lên local để đồng bộ chuẩn)
      _favoriteProducts.clear();
      _favoriteProducts.addAll(serverFavorites);

      print('✅ Đã tải ${serverFavorites.length} sản phẩm yêu thích.');
    } catch (e) {
      print('❌ Lỗi fetchFavorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm chính: Thêm/Xóa yêu thích
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

    // Debug Log quan trọng
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
          // Nãy xóa đi rồi, giờ thêm lại
          _favoriteProducts.add(product);
        } else {
          // Nãy thêm vào rồi, giờ xóa đi
          _favoriteProducts.removeWhere((p) => p.maSP == maSP);
        }
        notifyListeners();
      }
    } else {
      print('⚠️ Không gọi API: Thiếu thông tin Auth hoặc CustomerCode');
    }
  }
}