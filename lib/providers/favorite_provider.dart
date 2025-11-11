// lib/providers/favorite_provider.dart
import 'package:flutter/material.dart';
import '../models/san_pham.dart'; // <<< Đảm bảo import SanPham model

class FavoriteProvider with ChangeNotifier {
  // Thay đổi từ List<String> sang List<SanPham>
  final List<SanPham> _favoriteProducts = [];

  // Getter để lấy danh sách sản phẩm yêu thích
  List<SanPham> get favoriteProducts => [..._favoriteProducts]; // Trả về bản sao để tránh sửa đổi trực tiếp

  // Kiểm tra xem sản phẩm có trong danh sách yêu thích không
  bool isFavorite(String productId) {
    return _favoriteProducts.any((product) => product.maSP == productId);
  }

  // Thêm hoặc xóa sản phẩm khỏi danh sách yêu thích
  void toggleFavorite(SanPham sanPham) { // <<< NHẬN ĐẦU VÀO LÀ SanPham
    final existingIndex = _favoriteProducts.indexWhere((product) => product.maSP == sanPham.maSP);

    if (existingIndex >= 0) {
      // Đã có trong yêu thích, xóa đi
      _favoriteProducts.removeAt(existingIndex);
      // Bạn có thể thêm SnackBar ở đây hoặc ở ProductCard/FavoriteScreen
    } else {
      // Chưa có, thêm vào
      _favoriteProducts.add(sanPham);
      // Bạn có thể thêm SnackBar ở đây hoặc ở ProductCard/FavoriteScreen
    }
    notifyListeners(); // Cập nhật UI
  }
}