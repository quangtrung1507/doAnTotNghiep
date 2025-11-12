import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/san_pham.dart';

class MainCategoryProductsScreen extends StatefulWidget {
  final String mainCode;   // SACH/DOCHOI/LUUNIEM/MANGA/VPP
  final String title;
  final bool publicApi;    // không còn ý nghĩa, giữ để tương thích

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
  late Future<List<SanPham>> _future;

  @override
  void initState() {
    super.initState();
    // dùng alias đã thêm ở ApiService
    _future = ApiService.fetchProductsByMain(widget.mainCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<SanPham>>(
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

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 260,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (_, i) => _ProductCard(product: products[i]),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final SanPham product;
  const _ProductCard({required this.product});

  String _fullImage(String rel) {
    if (rel.isEmpty) return 'https://via.placeholder.com/600x400?text=No+Image';
    if (rel.startsWith('http')) return rel;
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    const port = 8080;
    return 'http://$host:$port$rel';
  }

  String _fmtPrice(double v) => '${v.toStringAsFixed(0)} đ';

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {}, // TODO: mở chi tiết
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                _fullImage(product.hinhAnh),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey.shade200, child: const Icon(Icons.image)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.tenSP,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (product.author.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  product.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _fmtPrice(product.gia),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
