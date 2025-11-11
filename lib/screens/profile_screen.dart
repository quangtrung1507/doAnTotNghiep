// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // Đảm bảo import AuthProvider của bạn
import '../widgets/custom_list_tile.dart'; // Chúng ta sẽ tạo widget này sau

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

          if (!authProvider.isAuthenticated || user == null) {
            // Trường hợp chưa đăng nhập hoặc không có thông tin user
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bạn chưa đăng nhập.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/login');
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
                // Phần thông tin người dùng
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

                // Các tùy chọn tài khoản
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
                    // TODO: Điều hướng đến màn hình chỉnh sửa thông tin cá nhân
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang được phát triển.')),
                    );
                  },
                ),
                CustomListTile(
                  icon: Icons.shopping_bag,
                  title: 'Đơn hàng của tôi',
                  onTap: () {
                    // TODO: Điều hướng đến màn hình danh sách đơn hàng
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang được phát triển.')),
                    );
                  },
                ),
                CustomListTile(
                  icon: Icons.favorite,
                  title: 'Sản phẩm yêu thích',
                  onTap: () {
                    // TODO: Điều hướng đến màn hình sản phẩm yêu thích
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang được phát triển.')),
                    );
                  },
                ),
                CustomListTile(
                  icon: Icons.lock_reset,
                  title: 'Đổi mật khẩu',
                  onTap: () {
                    // TODO: Điều hướng đến màn hình đổi mật khẩu
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang được phát triển.')),
                    );
                  },
                ),
                CustomListTile(
                  icon: Icons.settings,
                  title: 'Cài đặt chung',
                  onTap: () {
                    // TODO: Điều hướng đến màn hình cài đặt chung
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang được phát triển.')),
                    );
                  },
                ),

                const Divider(thickness: 1, height: 30),

                // Nút đăng xuất
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Hiển thị dialog xác nhận trước khi đăng xuất
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
                        await authProvider.logout();
                        // Sau khi đăng xuất, điều hướng về màn hình đăng nhập
                        Navigator.of(context).pushReplacementNamed('/login');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bạn đã đăng xuất thành công.')),
                        );
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