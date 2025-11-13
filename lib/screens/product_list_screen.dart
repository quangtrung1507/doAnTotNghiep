import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart'; // Import này đã đúng!
import '../services/api_service.dart';

class ProductListScreen extends StatefulWidget {
  final String categoryCode; // ví dụ: 'LSP01'
  final String title;

  const ProductListScreen({
    Key? key,
    required this.categoryCode,
    required this.title,
  }) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  // ⬇️ ĐÃ SỬA: Dùng class model 'Product'
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    // (Hàm ApiService.fetchProductsByCategory đã trả về List<Product>)
    _productsFuture = ApiService.fetchProductsByCategory(widget.categoryCode);
  }

  String getFullImageUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) {
      return 'https://via.placeholder.com/600x400?text=No+Image';
    }
    if (relativeUrl.startsWith('http')) return relativeUrl;
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    const port = 8080;
    return 'http://$host:$port$relativeUrl';
  }

  // ⬇️ ĐÃ SỬA: Dùng class model 'Product'
  String priceText(Product p) {
    final price = p.gia;
    final discount = p.discountValue ?? 0;
    if (discount > 0 && discount < price) {
      final sale = (price - discount).toStringAsFixed(0);
      return '$sale đ';
    }
    return '${price.toStringAsFixed(0)} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await _productsFuture;
        },
        // ⬇️ ĐÃ SỬA: Dùng class model 'Product'
        child: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            }
            // (Biến 'products' giờ là List<Product>)
            final products = snapshot.data ?? [];
            if (products.isEmpty) {
              return const Center(child: Text('Không tìm thấy sản phẩm nào.'));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 260,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                // (Biến 'p' giờ là kiểu 'Product')
                final p = products[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.network(
                          getFullImageUrl(p.hinhAnh),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0x11000000),
                            child: Icon(Icons.image, size: 40),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          p.tenSP,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: Row(
                          children: [
                            Text(
                              priceText(p),
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            if ((p.discountValue ?? 0) > 0 && (p.discountValue ?? 0) < p.gia)
                              Text(
                                '${p.gia.toStringAsFixed(0)} đ',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
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
          },
        ),
      ),
    );
  }
}