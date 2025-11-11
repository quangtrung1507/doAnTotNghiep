import 'package:flutter/material.dart';
import '../models/gio_hang_item.dart';
import '../models/san_pham.dart';

class CartService {
  // Dùng static để dữ liệu giỏ hàng là duy nhất trong toàn bộ ứng dụng
  static final List<GioHangItem> _items = [];

  // ValueNotifier sẽ thông báo cho các widget đang lắng nghe khi có sự thay đổi
  static final ValueNotifier<List<GioHangItem>> cartNotifier = ValueNotifier(_items);

  // Getter để lấy danh sách sản phẩm trong giỏ hàng
  static List<GioHangItem> get items => _items;

  // Thêm một sản phẩm vào giỏ
  static void addItem(SanPham sanPham) {
    // Kiểm tra xem sản phẩm đã có trong giỏ chưa
    for (var item in _items) {
      if (item.sanPham.maSP == sanPham.maSP) {
        // Nếu có rồi thì chỉ tăng số lượng
        item.soLuong++;
        // Thông báo cho giao diện cập nhật
        cartNotifier.value = List.from(_items);
        return;
      }
    }
    // Nếu chưa có thì thêm mới vào danh sách
    _items.add(GioHangItem(sanPham: sanPham, soLuong: 1));
    cartNotifier.value = List.from(_items);
  }

  // Tăng số lượng của một item
  static void increaseQuantity(String maSP) {
    for (var item in _items) {
      if (item.sanPham.maSP == maSP) {
        item.soLuong++;
        cartNotifier.value = List.from(_items);
        return;
      }
    }
  }

  // Giảm số lượng của một item
  static void decreaseQuantity(String maSP) {
    for (var item in _items) {
      if (item.sanPham.maSP == maSP) {
        if (item.soLuong > 1) {
          item.soLuong--;
        } else {
          // Nếu số lượng là 1 thì xóa luôn
          _items.remove(item);
        }
        cartNotifier.value = List.from(_items);
        return;
      }
    }
  }

  // Xóa một sản phẩm khỏi giỏ hàng
  static void removeItem(String maSP) {
    _items.removeWhere((item) => item.sanPham.maSP == maSP);
    cartNotifier.value = List.from(_items);
  }

  // Tính tổng tiền
  static double get totalPrice {
    double total = 0;
    for (var item in _items) {
      total += item.sanPham.gia * item.soLuong;
    }
    return total;
  }
}