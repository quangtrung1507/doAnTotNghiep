// lib/models/cart_item.dart
import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    if (json['product'] == null || json['product'] is! Map) {
      throw Exception("Lỗi đọc giỏ hàng: Dữ liệu 'product' bị thiếu.");
    }

    final productData = Product.fromJson(json['product'] as Map<String, dynamic>);
    final qty = (json['quantity'] as int?) ?? 1;

    print('🛒 [CartItem] Đã parse: ${productData.tenSP} (SL: $qty)');

    return CartItem(
      product: productData,
      quantity: qty,
    );
  }

  // ✅ Getter tiện dụng – KHÔNG bắt buộc nhưng rất hữu ích
  String get productCode => product.maSP;
  String get productName => product.tenSP;
  String get imageUrl   => product.hinhAnh;
  double get price      => product.gia;
}
