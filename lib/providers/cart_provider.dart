// lib/providers/cart_provider.dart
import 'package:flutter/material.dart';
// ⬇️ ĐÃ SỬA: Import 'cart_item.dart' mới
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  // ⬇️ ĐÃ SỬA: Dùng class 'CartItem'
  final List<CartItem> _items = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ⬇️ ĐÃ SỬA: Dùng class 'CartItem'
  List<CartItem> get items => _items;

  // Getter cho tổng số lượng sản phẩm
  int get itemCount {
    // ⬇️ ĐÃ SỬA: Dùng 'quantity'
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Thêm một sản phẩm vào giỏ
  // ⬇️ ĐÃ SỬA: Đổi tên biến 'sanPham' -> 'product'
  void addItem(Product product) {
    bool found = false;
    for (var item in _items) {
      // ⬇️ ĐÃ SỬA: Dùng 'item.product'
      if (item.product.maSP == product.maSP) {
        // ⬇️ ĐÃ SỬA: Dùng 'quantity'
        item.quantity++;
        found = true;
        break;
      }
    }
    if (!found) {
      // ⬇️ ĐÃ SỬA: Dùng 'CartItem' và các thuộc tính mới
      _items.add(CartItem(product: product, quantity: 1));
    }
    notifyListeners();
  }

  // Tăng số lượng của một item
  void increaseQuantity(String maSP) {
    for (var item in _items) {
      // ⬇️ ĐÃ SỬA: Dùng 'item.product'
      if (item.product.maSP == maSP) {
        // ⬇️ ĐÃ SỬA: Dùng 'quantity'
        item.quantity++;
        notifyListeners();
        return;
      }
    }
  }

  // Giảm số lượng của một item
  void decreaseQuantity(String maSP) {
    for (var item in _items) {
      // ⬇️ ĐÃ SỬA: Dùng 'item.product'
      if (item.product.maSP == maSP) {
        // ⬇️ ĐÃ SỬA: Dùng 'quantity'
        if (item.quantity > 1) {
          item.quantity--;
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
    // ⬇️ ĐÃ SỬA: Dùng 'item.product'
    _items.removeWhere((item) => item.product.maSP == maSP);
    notifyListeners();
  }

  // Tính tổng tiền
  double get totalPrice {
    double total = 0;
    for (var item in _items) {
      // ⬇️ ĐÃ SỬA: Dùng 'item.product.gia' và 'item.quantity'
      total += item.product.gia * item.quantity;
    }
    return total;
  }

  // Xóa tất cả sản phẩm khỏi giỏ
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}