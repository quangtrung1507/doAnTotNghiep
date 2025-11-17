// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../providers/auth_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final String maSP;

  const ProductDetailScreen({Key? key, required this.maSP}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProductDetail();
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

  // Hàm kiểm tra đăng nhập (Đã sửa lỗi gõ nhầm)
  Future<bool> _checkLogin(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool isReallyLoggedIn = authProvider.isAuthenticated && authProvider.currentUser != null;

    if (isReallyLoggedIn) {
      return true;
    }

    final bool? shouldLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange),
            SizedBox(width: 10),
            Text("Cần đăng nhập"),
          ],
        ),
        content: const Text("Bạn cần đăng nhập tài khoản để thực hiện chức năng này."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Để sau", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Đăng nhập ngay"),
          ),
        ],
      ),
    );

    if (shouldLogin == true && context.mounted) {
      Navigator.of(context).pushNamed('/login');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đang tải...'), backgroundColor: AppColors.primary),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi'), backgroundColor: AppColors.primary),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Không tìm thấy'), backgroundColor: AppColors.primary),
        body: const Center(child: Text('Không tìm thấy sản phẩm.')),
      );
    }

    final String imageUrl = (_product!.hinhAnh.isNotEmpty &&
        (_product!.hinhAnh.startsWith('http') ||
            _product!.hinhAnh.startsWith('https')))
        ? _product!.hinhAnh
        : 'http://10.0.2.2:8080${_product!.hinhAnh}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_product!.tenSP),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Text(
                    _product!.tenSP,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(_product!.gia),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text('Mô tả sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _product!.moTa,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Nút thêm giỏ hàng (Đã sửa để khớp với Provider mới)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () async {
            final isLoggedIn = await _checkLogin(context);
            if (!isLoggedIn) return;

            if (context.mounted) {
              try {
                // Lấy AuthProvider
                final auth = Provider.of<AuthProvider>(context, listen: false);

                // Gọi hàm 'addItem' VỚI customerCode
                await Provider.of<CartProvider>(context, listen: false)
                    .addItem(_product!, auth.customerCode); // ⬅️ Phải là 'await'

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã thêm "${_product!.tenSP}" vào giỏ hàng!')),
                );
              } catch(e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                );
              }
            }
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Thêm vào giỏ hàng'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}