import 'package:flutter/material.dart';
import '../models/san_pham.dart';
import '../screens/product_detail_screen.dart'; // ✅ BƯỚC 1: IMPORT MÀN HÌNH CHI TIẾT
import '../services/cart_service.dart';
import '../utils/app_colors.dart';

class ProductCard extends StatelessWidget {
  final SanPham sanPham;
  final VoidCallback onAddToCartPressed;

  const ProductCard({
    Key? key,
    required this.sanPham,
    required this.onAddToCartPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Đường dẫn ảnh an toàn
    final String imageUrl = (sanPham.hinhAnh.isNotEmpty &&
        (sanPham.hinhAnh.startsWith('http') ||
            sanPham.hinhAnh.startsWith('https'
            )))
        ? sanPham.hinhAnh
        : 'http://10.0.2.2:8080${sanPham.hinhAnh}';

    return GestureDetector(
      onTap: () {
        // ✅ BƯỚC 2: THAY THẾ HÀNH ĐỘNG CŨ BẰNG VIỆC ĐIỀU HƯỚNG
        Navigator.push(
          context,
          MaterialPageRoute(
            // Truyền đối tượng 'sanPham' hiện tại vào màn hình chi tiết
            builder: (context) => ProductDetailScreen(sanPham: sanPham),
          ),
        );
      },
      child: Card(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        shadowColor: Colors.black12,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼 Ảnh sản phẩm
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 🏷 Tên sản phẩm
              Text(
                sanPham.tenSP,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // 💰 Giá + nút giỏ hàng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${sanPham.gia.toStringAsFixed(0)}đ",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    color: AppColors.primary,
                    onPressed: () {
                      CartService.addItem(sanPham);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã thêm "${sanPham.tenSP}" vào giỏ'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

