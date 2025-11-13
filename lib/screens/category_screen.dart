import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <<< Đã import
import '../models/product.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart'; // <<< Đã import

class CategoryScreen extends StatefulWidget {
  final String maLSP;
  final String tenLSP;

  const CategoryScreen({super.key, required this.maLSP, required this.tenLSP});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  // *** BẮT ĐẦU SỬA ***
  // 1. Chuyển Future thành nullable (có thể rỗng)
  Future<List<Product>>? _futureProducts;
  // 2. Thêm cờ (flag) để đảm bảo chỉ chạy 1 lần
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    // 3. KHÔNG gọi Provider.of(context) ở đây
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 4. Chỉ chạy logic này 1 LẦN DUY NHẤT
    if (_isInit) {
      // 5. Lấy token từ AuthProvider (an toàn)
      final authToken = Provider.of<AuthProvider>(context, listen: false).authToken;

      // 6. Gọi API và gán cho Future
      _futureProducts = ApiService.fetchProductsByCategory(widget.maLSP);

      // 7. Đặt cờ thành false để không chạy lại
      _isInit = false;
    }
    // *** KẾT THÚC SỬA ***
  }

  // Hàm helper để lấy URL ảnh đầy đủ
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
        title: Text(widget.tenLSP),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<List<Product>>(
        future: _futureProducts, // 8. Dùng Future ở đây
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
                  // 🔜 Điều hướng sang trang chi tiết sản phẩm
                  Navigator.of(context).pushNamed(
                    '/product-detail',
                    arguments: sp.maSP,
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
                            getFullImageUrl(sp.hinhAnh),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.network(
                                  'https://via.placeholder.com/150',
                                  fit: BoxFit.cover,
                                ),
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