// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';                 // 👈 THÊM
import '../utils/app_colors.dart';

// Import nội dung các tab
import 'home_content.dart';
import 'favorite_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'voucher_screen.dart';

// 👈 THÊM: Provider yêu thích
import '../providers/favorite_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Nếu tab 3 của bạn đã chuyển sang Voucher thì đổi CartScreen -> VoucherScreen
  final List<Widget Function()> _widgetBuilders = [
        () => const HomeContent(),
        () => const FavoriteScreen(),
        () => const VoucherScreen(),   // hoặc CartScreen nếu bạn vẫn dùng giỏ tại đây
        () => const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 👇 Helper: icon tim có badge số lượng
  Widget _buildFavoriteNavIcon(int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.favorite_rounded),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _widgetBuilders[_selectedIndex](),

      // BOTTOM BAR bo tròn giống design, chỉ icon
      bottomNavigationBar: Consumer<FavoriteProvider>(
        builder: (context, fav, _) {
          final favCount = fav.favoriteProducts.length;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                showSelectedLabels: false, // ❗ chỉ icon, không text
                showUnselectedLabels: false,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textLight,
                items: <BottomNavigationBarItem>[
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view_rounded),
                    label: 'Trang chủ',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildFavoriteNavIcon(favCount), // 👈 tim + badge
                    label: 'Yêu thích',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.local_offer_rounded),
                    label: 'Voucher',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded),
                    label: 'Tài khoản',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
