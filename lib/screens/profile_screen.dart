// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/custom_list_tile.dart';
import '../utils/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Tài khoản của tôi',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          // ===== TRƯỜNG HỢP CHƯA ĐĂNG NHẬP =====
          if (!authProvider.isAuthenticated || user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Bạn chưa đăng nhập.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                            (route) => false,
                      );
                    },
                    child: const Text('Đăng nhập ngay'),
                  ),
                ],
              ),
            );
          }

          // ===== ĐÃ ĐĂNG NHẬP =====
          return Column(
            children: [
              // ---------- PHẦN CUỘN ĐƯỢC ----------
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AVATAR + TÊN + EMAIL
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: const CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  size: 52,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user.username,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      const Divider(
                        thickness: 1,
                        height: 30,
                        color: Color(0xFFE0E0E0),
                      ),

                      const Text(
                        'Tài khoản',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Đơn hàng của tôi
                      CustomListTile(
                        icon: Icons.shopping_bag,
                        title: 'Đơn hàng của tôi',
                        onTap: () {
                          Navigator.of(context).pushNamed('/orders');
                        },
                      ),

                      // Yêu thích
                      CustomListTile(
                        icon: Icons.favorite,
                        title: 'Sản phẩm yêu thích',
                        onTap: () {
                          Navigator.of(context).pushNamed('/favorites');
                        },
                      ),

                      // ✅ THÊM: Giỏ hàng
                      CustomListTile(
                        icon: Icons.shopping_cart_rounded,
                        title: 'Giỏ hàng',
                        onTap: () {
                          Navigator.of(context).pushNamed('/cart');
                        },
                      ),

                      const SizedBox(height: 16),
                      const Divider(
                        thickness: 1,
                        height: 30,
                        color: Color(0xFFE0E0E0),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------- NÚT ĐĂNG XUẤT Ở DƯỚI CÙNG ----------
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Xác nhận đăng xuất'),
                            content: const Text(
                              'Bạn có chắc chắn muốn đăng xuất không?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Đăng xuất'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          // Xoá yêu thích + giỏ hàng local
                          Provider.of<FavoriteProvider>(context, listen: false)
                              .clearFavorites();
                          try {
                            Provider.of<CartProvider>(context, listen: false)
                                .clearCart();
                          } catch (_) {}

                          await authProvider.logout();

                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                                  (route) => false,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bạn đã đăng xuất thành công.'),
                              ),
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
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
