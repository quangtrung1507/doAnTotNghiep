import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../utils/app_colors.dart';

class ThanhToanScreen extends StatefulWidget {
  const ThanhToanScreen({super.key});

  @override
  State<ThanhToanScreen> createState() => _ThanhToanScreenState();
}

class _ThanhToanScreenState extends State<ThanhToanScreen> {
  // Biến để lưu trữ phương thức thanh toán được chọn
  String _phuongThucThanhToan = 'COD'; // Mặc định là COD

  @override
  Widget build(BuildContext context) {
    final tongTienHang = CartService.totalPrice;
    final phiVanChuyen = 30000.0; // Tạm thời cố định phí vận chuyển
    final tongThanhToan = tongTienHang + phiVanChuyen;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông Tin Thanh Toán'),
        backgroundColor: AppColors.card,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thông tin giao hàng
            const Text('Thông tin giao hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: const [
                    TextField(decoration: InputDecoration(labelText: 'Họ và tên')),
                    SizedBox(height: 10),
                    TextField(decoration: InputDecoration(labelText: 'Số điện thoại')),
                    SizedBox(height: 10),
                    TextField(decoration: InputDecoration(labelText: 'Địa chỉ')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Phương thức thanh toán
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
      // 3. Phần tổng kết và nút đặt hàng
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
                onPressed: () {
                  // TODO: Sau này sẽ xử lý logic đặt hàng ở đây
                  // Bây giờ chỉ hiển thị thông báo
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Thành công!'),
                      content: const Text('Bạn đã đặt hàng thành công. Chúng tôi sẽ liên hệ với bạn sớm nhất.'),
                      actions: [
                        TextButton(
                          child: const Text('OK'),
                          onPressed: () {
                            Navigator.of(ctx).pop(); // Đóng dialog
                          },
                        )
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Đặt Hàng', style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}