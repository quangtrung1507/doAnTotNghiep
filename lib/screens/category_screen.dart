import 'package:flutter/material.dart';
import '../models/san_pham.dart';
import '../services/api_service.dart';

class CategoryScreen extends StatefulWidget {
  final String maLSP;
  final String tenLSP;

  const CategoryScreen({super.key, required this.maLSP, required this.tenLSP});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<SanPham>> _futureProducts;

  @override
  void initState() {
    super.initState();
    // ✅ Gọi API để lấy sản phẩm theo loại
    _futureProducts = ApiService.fetchProductsByCategory(widget.maLSP);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tenLSP),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<List<SanPham>>(
        future: _futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('❌ Lỗi: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(child: Text('Không có sản phẩm nào.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final sp = products[index];
              return GestureDetector(
                onTap: () {
                  // 🔜 Sau này có thể điều hướng sang trang chi tiết sản phẩm
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nhấn vào ${sp.tenSP}')),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(15)),
                          child: Image.network(
                            sp.hinhAnh,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          sp.tenSP,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '${sp.gia.toStringAsFixed(0)} ₫',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
