// lib/screens/main_screen.dart (Đã sửa lỗi treo)
import 'package:flutter/material.dart';

// Import NỘI DUNG của các tab
import 'home_content.dart';
import 'favorite_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // ⬇️ ⬇️ ⬇️ THAY ĐỔI QUAN TRỌNG ⬇️ ⬇️ ⬇️
  // Chúng ta KHÔNG dùng 'static' VÀ KHÔNG khởi tạo chúng ngay lập tức
  // Chúng ta sẽ dùng một danh sách các "hàm xây dựng" (builders)
  // để đảm bảo các tab chỉ được tạo KHI CẦN
  final List<Widget Function()> _widgetBuilders = [
        () => HomeContent(),
        () => FavoriteScreen(),
        () => CartScreen(),
        () => ProfileScreen(),
  ];
  // ⬆️ ⬆️ ⬆️ KẾT THÚC THAY ĐỔI ⬆️ ⬆️ ⬆️

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ⬇️ ⬇️ ⬇️ THAY ĐỔI QUAN TRỌNG ⬇️ ⬇️ ⬇️
      // BỎ DÙNG IndexedStack (thứ tải cả 4 tab)
      // Dùng cách đơn giản này để nó CHỈ TẢI 1 TAB (tab đang chọn)
      body: Center(
        child: _widgetBuilders[_selectedIndex](), // Chỉ build widget của tab hiện tại
      ),
      // ⬆️ ⬆️ ⬆️ KẾT THÚC THAY ĐỔI ⬆️ ⬆️ ⬆️

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
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}