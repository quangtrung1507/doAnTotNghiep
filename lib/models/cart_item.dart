// lib/models/cart_item.dart
import 'product.dart'; // Import model Product tiếng Anh

// ⬇️ ĐÃ SỬA: Đổi tên class
class CartItem {
  // ⬇️ ĐÃ SỬA: Đổi tên thuộc tính
  final Product product;
  // ⬇️ ĐÃ SỬA: Đổi tên thuộc tính
  int quantity;

  // ⬇️ ĐÃ SỬA: Cập nhật constructor
  CartItem({
    required this.product,
    required this.quantity,
  });
}