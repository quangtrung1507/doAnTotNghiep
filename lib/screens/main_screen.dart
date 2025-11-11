// lib/screens/main_screen.dart (Phiên bản cuối cùng, đã gộp)
import 'package:flutter/material.dart';

// Import NỘI DUNG của các tab
import 'home_content.dart'; // <<< Đã sửa: Import nội dung trang chủ
import 'favorite_screen.dart'; // Màn hình Yêu thích
import 'cart_screen.dart'; // Màn hình Giỏ hàng
import 'profile_screen.dart'; // Màn hình Tài khoản
// import 'cart_screen.dart'; // <<< Xóa dòng lặp lại này

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Index của tab hiện tại

  // Danh sách các widget/màn hình tương ứng với các tab
  // *** SỬA Ở ĐÂY: Xóa "const" ***
  static final List<Widget> _widgetOptions = <Widget>[
    HomeContent(),
    FavoriteScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dùng IndexedStack để giữ trạng thái các tab (không bị tải lại)
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Yêu thích',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Giỏ hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent, // (Màu này từ tệp main_screen cũ)
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}