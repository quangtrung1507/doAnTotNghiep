// lib/screens/product_list_screen.dart (Đã sửa theo Giải pháp 2)
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // <<< XÓA IMPORT NÀY
import '../models/san_pham.dart';
import '../services/api_service.dart';
// import '../providers/auth_provider.dart'; // <<< XÓA IMPORT NÀY

class ProductListScreen extends StatefulWidget {
  final String categoryCode; // Nhận mã 'LSP01'
  final String title;

  const ProductListScreen({
    Key? key,
    required this.categoryCode,
    required this.title,
  }) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<SanPham>> _productsFuture;

  // *** SỬA LẠI HÀM NÀY ***
  @override
  void initState() {
    super.initState();
    // Gọi hàm API 1 tham số (không cần token)
    _productsFuture = ApiService.fetchProductsByCategory(widget.categoryCode);
  }

  // *** XÓA HÀM didChangeDependencies() ***
  // @override
  // void didChangeDependencies() { ... }

  // Hàm helper (Giữ nguyên)
  String getFullImageUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) {
      return 'https://via.placeholder.com/150'; // Ảnh mặc định
    }
    const String imageBaseUrl = 'http://10.0.2.2:8080';
    return '$imageBaseUrl$relativeUrl';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<SanPham>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Không tìm thấy sản phẩm nào."));
          }

          final products = snapshot.data!;

          // GridView (Giữ nguyên)
          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 0.7,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 3.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.network(
                        getFullImageUrl(product.hinhAnh),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                              'https://via.placeholder.com/150',
                              fit: BoxFit.cover
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        product.tenSP,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        '${product.gia.toStringAsFixed(0)} đ',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}