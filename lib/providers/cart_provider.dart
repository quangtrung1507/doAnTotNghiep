// lib/providers/cart_provider.dart
import 'package:flutter/material.dart';
import '../models/gio_hang_item.dart'; // Đảm bảo đúng đường dẫn tới model giỏ hàng của bạn
import '../models/san_pham.dart';      // Đảm bảo đúng đường dẫn tới model sản phẩm của bạn

// CartProvider sẽ là một ChangeNotifier, thay thế cho CartService tĩnh
class CartProvider with ChangeNotifier {
  final List<GioHangItem> _items = []; // Sử dụng danh sách cục bộ

  // THÊM BIẾN VÀ GETTER isLoading NÀY VÀO LẠI
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // Thông báo cho UI cập nhật
  }
  // HẾT PHẦN THÊM

  List<GioHangItem> get items => _items;

  // Getter cho tổng số lượng sản phẩm
  int get itemCount => _items.fold(0, (sum, item) => sum + item.soLuong);


  // Thêm một sản phẩm vào giỏ
  void addItem(SanPham sanPham) {
    bool found = false;
    for (var item in _items) {
      if (item.sanPham.maSP == sanPham.maSP) {
        item.soLuong++;
        found = true;
        break;
      }
    }
    if (!found) {
      _items.add(GioHangItem(sanPham: sanPham, soLuong: 1));
    }
    notifyListeners(); // Thông báo cho tất cả các widget đang lắng nghe
  }

  // Tăng số lượng của một item
  void increaseQuantity(String maSP) {
    for (var item in _items) {
      if (item.sanPham.maSP == maSP) {
        item.soLuong++;
        notifyListeners();
        return;
      }
    }
  }

  // Giảm số lượng của một item
  void decreaseQuantity(String maSP) {
    for (var item in _items) {
      if (item.sanPham.maSP == maSP) {
        if (item.soLuong > 1) {
          item.soLuong--;
        } else {
          _items.remove(item); // Xóa khỏi danh sách nếu số lượng về 0
        }
        notifyListeners();
        return;
      }
    }
  }

  // Xóa một sản phẩm khỏi giỏ hàng
  void removeItem(String maSP) {
    _items.removeWhere((item) => item.sanPham.maSP == maSP);
    notifyListeners();
  }

  // Tính tổng tiền
  double get totalPrice {
    double total = 0;
    for (var item in _items) {
      total += item.sanPham.gia * item.soLuong;
    }
    return total;
  }

  // Xóa tất cả sản phẩm khỏi giỏ
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}