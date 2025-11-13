// lib/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import 'order_tracking_screen.dart'; // <--- THÊM IMPORT NÀY

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diaChiController = TextEditingController();
  final _sdtController = TextEditingController();
  final _ghiChuController = TextEditingController();
  String _phuongThucThanhToan = 'COD';
  bool _isLoading = false;

  @override
  void dispose() {
    _diaChiController.dispose();
    _sdtController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      final customerCode = authProvider.customerCode;
      if (customerCode == null) {
        throw Exception('Lỗi: Người dùng không hợp lệ. Vui lòng đăng nhập lại.');
      }

      await ApiService.createOrder(
        customerCode: customerCode,
        cartItems: cartProvider.items,
        address: _diaChiController.text,
        phoneNumber: _sdtController.text,
        paymentMethod: _phuongThucThanhToan,
        note: _ghiChuController.text,
      );

      cartProvider.clearCart();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Thành công!'),
            content: const Text('Bạn đã đặt hàng thành công. Chúng tôi sẽ liên hệ với bạn sớm nhất.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(ctx).pop(); // Đóng dialog
                  // <--- ĐIỀU HƯỚNG MỚI: Đến màn hình theo dõi đơn hàng ---
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                  );
                  // ----------------------------------------------------
                },
              )
            ],
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Có lỗi xảy ra!'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              )
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final tongTienHang = cartProvider.totalPrice;
    final phiVanChuyen = 30000.0;
    final tongThanhToan = tongTienHang + phiVanChuyen;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông Tin Thanh Toán'),
        backgroundColor: AppColors.card,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông tin giao hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _sdtController,
                        decoration: const InputDecoration(labelText: 'Số điện thoại'),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _diaChiController,
                        decoration: const InputDecoration(labelText: 'Địa chỉ'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập địa chỉ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _ghiChuController,
                        decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Thanh toán khi nhận hàng (COD)'),
                      value: 'COD',
                      groupValue: _phuongThucThanhToan,
                      onChanged: (value) {
                        setState(() {
                          _phuongThucThanhToan = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Chuyển khoản ngân hàng'),
                      value: 'BANK',
                      groupValue: _phuongThucThanhToan,
                      onChanged: (value) {
                        setState(() {
                          _phuongThucThanhToan = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền hàng:'),
                Text('${tongTienHang.toStringAsFixed(0)}đ'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Phí vận chuyển:'),
                Text('${phiVanChuyen.toStringAsFixed(0)}đ'),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${tongThanhToan.toStringAsFixed(0)}đ',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading) ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
                    : const Text('Đặt Hàng', style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}