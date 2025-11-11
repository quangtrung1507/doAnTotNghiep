import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../providers/cart_provider.dart'; // Import CartProvider mới
import '../providers/auth_provider.dart'; // Import AuthProvider để kiểm tra đăng nhập
import '../screens/thanh_toan_screen.dart';
import '../screens/dang_nhap_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Sử dụng Consumer để lắng nghe CartProvider
    return Consumer2<CartProvider, AuthProvider>( // Lắng nghe cả CartProvider và AuthProvider
      builder: (context, cartProvider, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Giỏ Hàng'),
            automaticallyImplyLeading: false, // Ẩn nút back vì đây là tab chính
          ),
          body: cartProvider.isLoading // Thêm trạng thái loading từ CartProvider (nếu có logic tải từ API)
              ? const Center(child: CircularProgressIndicator())
              : cartProvider.items.isEmpty
              ? Center(
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
                    Navigator.of(context).pushReplacementNamed('/'); // Về trang chủ
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
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: ListTile(
                        leading: Image.network(
                          // Sửa lại URL ảnh
                          item.sanPham.hinhAnh.startsWith('http')
                              ? item.sanPham.hinhAnh
                              : 'http://10.0.2.2:8080${item.sanPham.hinhAnh}',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                                'lib/data/ngontinh/1.jpg', // Placeholder
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                        ),
                        title: Text(item.sanPham.tenSP),
                        subtitle: Text(currencyFormatter.format(item.sanPham.gia)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => cartProvider.decreaseQuantity(item.sanPham.maSP),
                            ),
                            Text(item.soLuong.toString(), style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => cartProvider.increaseQuantity(item.sanPham.maSP),
                            ),
                            IconButton( // Thêm nút xóa riêng cho từng item
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => cartProvider.removeItem(item.sanPham.maSP),
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
                    ElevatedButton(
                      onPressed: () {
                        // Sử dụng AuthProvider để kiểm tra trạng thái đăng nhập
                        if (authProvider.isAuthenticated) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ThanhToanScreen()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng đăng nhập để thanh toán!')),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DangNhapScreen()),
                          );
                        }
                      },
                      child: const Text('Thanh Toán'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary, // Dùng màu primary từ theme
                        foregroundColor: Colors.white,
                      ),
                    ),
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