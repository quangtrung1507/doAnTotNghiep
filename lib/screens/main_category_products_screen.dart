// lib/screens/main_category_products_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🌟 THÊM IMPORT NÀY
import '../services/api_service.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart'; // 🌟 THÊM IMPORT NÀY
import '../widgets/product_card.dart'; // 🌟 THÊM IMPORT NÀY

// ❌ XÓA IMPORT: 'dart:io' và 'product_detail_screen.dart' (ProductCard tự xử lý)

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

          // 🌟 Lấy CartProvider
          final cart = Provider.of<CartProvider>(context, listen: false);

          return GridView.builder(
            // ⬇️ ĐÃ SỬA: Đồng bộ padding giống trang chủ
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              // ⬇️ ĐÃ SỬA: Đồng bộ chiều cao giống trang chủ
              mainAxisExtent: 260,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            // ⬇️ ĐÃ SỬA: Dùng ProductCard (widget chung)
            itemBuilder: (_, i) {
              final p = products[i];
              return ProductCard(
                product: p,
                onAddToCartPressed: () {
                  cart.addItem(p);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã thêm "${p.tenSP}" vào giỏ hàng')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ❌ XÓA TOÀN BỘ: class _ProductCard extends StatelessWidget { ... }
// (Không cần widget riêng tư này nữa)