import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thư viện để định dạng số và tiền tệ
import '../models/san_pham.dart';
import '../services/cart_service.dart';
import '../utils/app_colors.dart'; // Import màu sắc của bạn

class ProductDetailScreen extends StatelessWidget {
  // Màn hình này sẽ nhận một đối tượng SanPham để hiển thị
  final SanPham sanPham;

  const ProductDetailScreen({Key? key, required this.sanPham}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dùng NumberFormat để định dạng giá tiền cho đẹp (ví dụ: 75.000đ)
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // ✅ SỬA LỖI: Thêm logic xử lý URL hình ảnh tương tự như trong ProductCard
    final String imageUrl = (sanPham.hinhAnh.isNotEmpty &&
        (sanPham.hinhAnh.startsWith('http') ||
            sanPham.hinhAnh.startsWith('https')))
        ? sanPham.hinhAnh
        : 'http://10.0.2.2:8080${sanPham.hinhAnh}';

    return Scaffold(
      appBar: AppBar(
        title: Text(sanPham.tenSP), // Tên sản phẩm trên AppBar
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hình ảnh sản phẩm
            Image.network(
              imageUrl, // <-- Sử dụng biến imageUrl đã được xử lý ở trên
              height: 300,
              width: double.infinity,
              fit: BoxFit.contain, // Dùng contain để ảnh không bị cắt xén
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 300,
                child: Center(child: Icon(Icons.image_not_supported, size: 50)),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Tên sản phẩm
                  Text(
                    sanPham.tenSP,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3. Giá sản phẩm
                  Text(
                    currencyFormatter.format(sanPham.gia),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(), // Dường kẻ phân cách
                  const SizedBox(height: 10),

                  // 4. Mô tả sản phẩm
                  const Text(
                    'Mô tả sản phẩm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sanPham.moTa,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5, // Giãn cách dòng cho dễ đọc
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 5. Nút "Thêm vào giỏ hàng" ở dưới cùng
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () {
            CartService.addItem(sanPham);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã thêm "${sanPham.tenSP}" vào giỏ hàng!')),
            );
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Thêm vào giỏ hàng'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}