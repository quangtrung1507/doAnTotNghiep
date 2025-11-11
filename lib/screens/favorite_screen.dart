// lib/screens/favorite_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/product_card.dart';
import '../models/san_pham.dart';
import '../providers/cart_provider.dart';
import '../utils/app_colors.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe FavoriteProvider để cập nhật UI khi danh sách yêu thích thay đổi
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Lấy trực tiếp danh sách SanPham từ FavoriteProvider
    final List<SanPham> favoriteProducts = favoriteProvider.favoriteProducts; // <<< ĐÃ SỬA DÒNG NÀY


    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm yêu thích'),
        backgroundColor: AppColors.primary,
      ),
      body: favoriteProducts.isEmpty
          ? const Center(
        child: Text(
          'Bạn chưa có sản phẩm yêu thích nào.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: favoriteProducts.length,
        itemBuilder: (context, index) {
          final sanPham = favoriteProducts[index];
          return ProductCard(
            sanPham: sanPham,
            onAddToCartPressed: () {
              cartProvider.addItem(sanPham);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã thêm "${sanPham.tenSP}" vào giỏ hàng!'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          );
        },
      ),
    );
  }
}