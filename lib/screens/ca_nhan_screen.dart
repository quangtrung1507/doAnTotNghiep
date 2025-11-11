import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'dang_nhap_screen.dart'; // Import màn hình đăng nhập

class CaNhanScreen extends StatelessWidget {
  // BƯỚC 1: XÓA GIÁ TRỊ CỐ ĐỊNH, CHỈ KHAI BÁO BIẾN
  // Bây giờ, widget này sẽ NHẬN trạng thái đăng nhập từ bên ngoài
  // thay vì tự quyết định.
  final bool isLoggedIn;

  // BƯỚC 2: SỬA LẠI CONSTRUCTOR ĐỂ YÊU CẦU THAM SỐ `isLoggedIn`
  const CaNhanScreen({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tài Khoản'),
        backgroundColor: AppColors.card,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      // Dùng biến `isLoggedIn` được truyền vào để quyết định giao diện
      body: isLoggedIn
          ? _buildLoggedInView() // Giao diện khi đã đăng nhập
          : _buildLoggedOutView(context), // Giao diện khi chưa đăng nhập
    );
  }

  // --- WIDGET CHO NGƯỜI DÙNG CHƯA ĐĂNG NHẬP ---
  Widget _buildLoggedOutView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Vui lòng đăng nhập để sử dụng đầy đủ tính năng',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: AppColors.textLight),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Mở màn hình đăng nhập
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DangNhapScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text('Đăng nhập / Đăng ký', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CHO NGƯỜI DÙNG ĐÃ ĐĂNG NHẬP ---
  // (Phần này giữ nguyên, không thay đổi)
  Widget _buildLoggedInView() {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: AppColors.card,
          child: Row(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('assets/images/avatar.png'),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Trung Nguyễn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('trung.nguyen@email.com', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildOptionItem(icon: Icons.receipt_long, title: 'Đơn hàng của tôi', onTap: () {}),
        _buildOptionItem(icon: Icons.location_on_outlined, title: 'Địa chỉ nhận hàng', onTap: () {}),
        _buildOptionItem(icon: Icons.payment_outlined, title: 'Thông tin thanh toán', onTap: () {}),
        const Divider(),
        _buildOptionItem(icon: Icons.logout, title: 'Đăng xuất', color: Colors.red, onTap: () {}),
      ],
    );
  }

  Widget _buildOptionItem({required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textDark),
      title: Text(title, style: TextStyle(color: color ?? AppColors.textDark)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
