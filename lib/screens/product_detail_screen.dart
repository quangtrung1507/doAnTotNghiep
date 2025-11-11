import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thư viện để định dạng số và tiền tệ
import 'package:provider/provider.dart'; // Import Provider
import '../models/san_pham.dart';
import '../providers/cart_provider.dart'; // Import CartProvider
import '../services/api_service.dart'; // Import ApiService để lấy chi tiết sản phẩm
import '../utils/app_colors.dart';

class ProductDetailScreen extends StatefulWidget { // Chuyển từ StatelessWidget sang StatefulWidget
  final String maSP; // Nhận mã sản phẩm thay vì toàn bộ đối tượng SanPham

  const ProductDetailScreen({Key? key, required this.maSP}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  SanPham? _product; // Dữ liệu sản phẩm sẽ được tải
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProductDetail(); // Bắt đầu tải dữ liệu khi màn hình được tạo
  }

  Future<void> _fetchProductDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _product = await ApiService.fetchProductByCode(widget.maSP);
    } catch (e) {
      _errorMessage = 'Không thể tải chi tiết sản phẩm: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Đang tải...'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lỗi'),
          backgroundColor: AppColors.primary,
        ),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Không tìm thấy'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(child: Text('Không tìm thấy sản phẩm.')),
      );
    }

    // Nếu sản phẩm đã tải thành công
    final String imageUrl = (_product!.hinhAnh.isNotEmpty &&
        (_product!.hinhAnh.startsWith('http') ||
            _product!.hinhAnh.startsWith('https')))
        ? _product!.hinhAnh
        : 'http://10.0.2.2:8080${_product!.hinhAnh}'; // Sử dụng _product!

    return Scaffold(
      appBar: AppBar(
        title: Text(_product!.tenSP), // Tên sản phẩm trên AppBar
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hình ảnh sản phẩm
            Image.network(
              imageUrl,
              height: 300,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
              const SizedBox(
                height: 300,
                child: Center(child: Icon(Icons.image_not_supported, size: 50)),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Tên sản phẩm
                  Text(
                    _product!.tenSP,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark, // Thêm textDark nếu bạn có
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3. Giá sản phẩm
                  Text(
                    currencyFormatter.format(_product!.gia),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  // 4. Mô tả sản phẩm
                  const Text(
                    'Mô tả sản phẩm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _product!.moTa,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: AppColors.textDark, // Sử dụng textDark cho màu chữ
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 5. Nút "Thêm vào giỏ hàng" ở dưới cùng
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () {
            // Sử dụng Provider để thêm sản phẩm vào giỏ
            Provider.of<CartProvider>(context, listen: false).addItem(_product!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã thêm "${_product!.tenSP}" vào giỏ hàng!')),
            );
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Thêm vào giỏ hàng'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white, // Sửa thành foregroundColor
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}