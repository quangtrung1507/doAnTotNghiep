import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/cart_service.dart';
import '../models/gio_hang_item.dart';
import './thanh_toan_screen.dart';
import './dang_nhap_screen.dart'; // Import màn hình đăng nhập
// Giả sử có một service để kiểm tra trạng thái đăng nhập
// import '../services/auth_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ Hàng'),
        automaticallyImplyLeading: false, // Ẩn nút back vì đây là tab chính
      ),
      // Dùng ValueListenableBuilder để lắng nghe sự thay đổi từ CartService
      body: ValueListenableBuilder<List<GioHangItem>>(
        valueListenable: CartService.cartNotifier,
        builder: (context, cartItems, child) {
          if (cartItems.isEmpty) {
            return const Center(
              child: Text('Giỏ hàng của bạn đang trống!', style: TextStyle(fontSize: 18)),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: ListTile(
                        leading: Image.network(
                          'http://10.0.2.2:8080${item.sanPham.hinhAnh}',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(item.sanPham.tenSP),
                        subtitle: Text(currencyFormatter.format(item.sanPham.gia)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => CartService.decreaseQuantity(item.sanPham.maSP),
                            ),
                            Text(item.soLuong.toString(), style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => CartService.increaseQuantity(item.sanPham.maSP),
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
                      'Tổng: ${currencyFormatter.format(CartService.totalPrice)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // AuthService.isLoggedIn là một ví dụ, bạn cần thay thế bằng logic thực tế
                        bool isLoggedIn = false; // <-- THAY THẾ BẰNG LOGIC KIỂM TRA ĐĂNG NHẬP THỰC TẾ

                        if (isLoggedIn) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ThanhToanScreen()),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DangNhapScreen()),
                          );
                        }
                      },
                      child: const Text('Thanh Toán'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}