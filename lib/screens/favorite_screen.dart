// lib/screens/favorite_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/product_card.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart'; // 🔴 THÊM IMPORT NÀY
import '../utils/app_colors.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy provider (listen: false)
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    // 🔴 LẤY AUTH PROVIDER ĐỂ LẤY MÃ KHÁCH HÀNG
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm yêu thích'),
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favoriteProvider, child) {

          final List<Product> favoriteProducts = favoriteProvider.favoriteProducts;

          if (favoriteProducts.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa có sản phẩm yêu thích nào.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 260,
            ),
            itemCount: favoriteProducts.length,
            itemBuilder: (context, index) {
              final product = favoriteProducts[index];
              return ProductCard(
                product: product,
                // 🔴 SỬA LỖI: Chuyển thành hàm 'async' và thêm 'customerCode'
                onAddToCartPressed: () async {
                  try {
                    // Gọi hàm 'addItem' với 2 tham số
                    await cartProvider.addItem(product, authProvider.customerCode);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã thêm "${product.tenSP}" vào giỏ hàng!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}