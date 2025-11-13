// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';     // ⬅️ MỚI: Để xóa giỏ hàng
import '../providers/favorite_provider.dart'; // ⬅️ MỚI: Để xóa yêu thích
import '../widgets/custom_list_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản của tôi'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          // Kiểm tra nếu chưa đăng nhập hoặc user null
          if (!authProvider.isAuthenticated || user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bạn chưa đăng nhập.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Chuyển sang trang login, xóa stack cũ
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                    child: const Text('Đăng nhập ngay'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blueGrey.shade100,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.username,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                const Divider(thickness: 1, height: 30),

                Text(
                  'Cài đặt tài khoản',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
                const SizedBox(height: 10),
                CustomListTile(
                  icon: Icons.edit,
                  title: 'Thông tin cá nhân',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang được phát triển.')),
                    );
                  },
                ),
                CustomListTile(
                  icon: Icons.shopping_bag,
                  title: 'Đơn hàng của tôi',
                  onTap: () {
                    Navigator.of(context).pushNamed('/orders');
                  },
                ),
                CustomListTile(
                  icon: Icons.favorite,
                  title: 'Sản phẩm yêu thích',
                  onTap: () {
                    Navigator.of(context).pushNamed('/favorites');
                  },
                ),
                CustomListTile(
                  icon: Icons.lock_reset,
                  title: 'Đổi mật khẩu',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang được phát triển.')),
                    );
                  },
                ),
                CustomListTile(
                  icon: Icons.settings,
                  title: 'Cài đặt chung',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang được phát triển.')),
                    );
                  },
                ),

                const Divider(thickness: 1, height: 30),

                // NÚT ĐĂNG XUẤT (ĐÃ SỬA LOGIC)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xác nhận đăng xuất'),
                          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Hủy'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Đăng xuất'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        // 🔴 BƯỚC QUAN TRỌNG: XÓA DỮ LIỆU TRONG RAM
                        // Dùng listen: false để không gây lỗi khi đang build
                        Provider.of<FavoriteProvider>(context, listen: false).clearFavorites();

                        // Nếu CartProvider của bạn chưa có hàm clearCart(), hãy thêm vào nhé
                        try {
                          Provider.of<CartProvider>(context, listen: false).clearCart();
                        } catch(e) {
                          // Bỏ qua nếu chưa làm hàm clearCart, nhưng nên làm nhé!
                        }

                        // Sau khi dọn dẹp xong mới Logout
                        await authProvider.logout();

                        if(context.mounted) {
                          // Dùng pushNamedAndRemoveUntil để xóa sạch lịch sử điều hướng
                          // Ngăn người dùng bấm Back để quay lại trang Profile
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bạn đã đăng xuất thành công.')),
                          );
                        }
                      }
                    },
                    icon: authProvider.isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.logout),
                    label: authProvider.isLoading
                        ? const Text('Đang đăng xuất...')
                        : const Text('Đăng xuất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}