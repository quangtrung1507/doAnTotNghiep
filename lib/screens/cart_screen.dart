import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/checkout_screen.dart';
import '../screens/login_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Consumer2<CartProvider, AuthProvider>(
      builder: (context, cartProvider, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Giỏ Hàng'),
            automaticallyImplyLeading: false,
          ),
          body: cartProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : cartProvider.items.isEmpty
              ? Center(
            // (Code UI khi giỏ hàng rỗng... giữ nguyên)
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Giỏ hàng của bạn đang trống!',
                  style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    DefaultTabController.of(context).animateTo(0);
                  },
                  child: const Text('Tiếp tục mua sắm'),
                ),
              ],
            ),
          )
              : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  // (Code ListView... giữ nguyên)
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    final product = item.product;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: ListTile(
                        leading: Image.network(
                          product.hinhAnh.startsWith('http')
                              ? product.hinhAnh
                              : 'http://10.0.2.2:8080${product.hinhAnh}',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                        ),
                        title: Text(product.tenSP),
                        subtitle: Text(currencyFormatter.format(product.gia)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => cartProvider.decreaseQuantity(product.maSP),
                            ),
                            Text(item.quantity.toString(), style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => cartProvider.increaseQuantity(product.maSP),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => cartProvider.removeItem(product.maSP),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Phần tổng kết và thanh toán
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng: ${currencyFormatter.format(cartProvider.totalPrice)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    // ⬇️ ⬇️ ⬇️ BẮT ĐẦU SỬA NÚT "THANH TOÁN" ⬇️ ⬇️ ⬇️
                    ElevatedButton(
                      // 1. Biến hàm 'onPressed' thành 'async'
                      onPressed: () async {
                        // 2. Kiểm tra (như cũ)
                        if (authProvider.isAuthenticated) {
                          // Nếu ĐÃ đăng nhập, đi thẳng đến Checkout
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                          );
                        } else {
                          // 3. Nếu CHƯA đăng nhập:
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng đăng nhập để thanh toán!')),
                          );

                          // 4. CHỜ kết quả từ LoginScreen
                          final loginResult = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );

                          // 5. Nếu loginResult là 'true' (đăng nhập thành công)
                          if (loginResult == true) {
                            // TỰ ĐỘNG chuyển đến trang Checkout
                            // (thêm 'if (context.mounted)' để đảm bảo an toàn)
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                              );
                            }
                          }
                          // (Nếu loginResult là 'null' - người dùng nhấn Back - thì không làm gì)
                        }
                      },
                      child: const Text('Thanh Toán'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    // ⬆️ ⬆️ ⬆️ KẾT THÚC SỬA ⬆️ ⬆️ ⬆️
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}