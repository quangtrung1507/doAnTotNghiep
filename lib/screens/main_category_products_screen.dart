// lib/screens/main_category_products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart'; // 🔴 THÊM IMPORT NÀY
import '../widgets/product_card.dart';

class MainCategoryProductsScreen extends StatefulWidget {
  final String mainCode;
  final String title;
  final bool publicApi;

  const MainCategoryProductsScreen({
    super.key,
    required this.mainCode,
    required this.title,
    this.publicApi = true,
  });

  @override
  State<MainCategoryProductsScreen> createState() => _MainCategoryProductsScreenState();
}

class _MainCategoryProductsScreenState extends State<MainCategoryProductsScreen> {
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchProductsByCategoryType(widget.mainCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }
          final products = snap.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('Chưa có sản phẩm'));
          }

          // 🔴 LẤY PROVIDER
          final cart = Provider.of<CartProvider>(context, listen: false);
          final auth = Provider.of<AuthProvider>(context, listen: false);

          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 260,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (_, i) {
              final p = products[i];
              return ProductCard(
                product: p,
                // 🔴 SỬA LỖI: Chuyển thành hàm 'async' và thêm 'customerCode'
                onAddToCartPressed: () async {
                  try {
                    // Gọi hàm 'addItem' với 2 tham số
                    await cart.addItem(p, auth.customerCode);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã thêm "${p.tenSP}" vào giỏ hàng')),
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