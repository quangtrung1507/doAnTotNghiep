// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Các màn hình của bạn
import 'screens/main_screen.dart'; // <<< THAY THẾ CHO home_screen.dart nếu MainScreen chứa Tabs
// import 'screens/home_screen.dart'; // Vẫn giữ nếu HomeScreen là một tab con trong MainScreen
import 'screens/dang_nhap_screen.dart';
import 'screens/dang_ky_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/thanh_toan_screen.dart';
// import 'screens/book_category_list_screen.dart'; // Không cần import ở đây nữa
import 'screens/favorite_screen.dart';
import 'screens/profile_screen.dart'; // Vẫn giữ ProfileScreen

// Các Providers của bạn
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorite_provider.dart';

void main() {
  runApp(const BookStoreApp());
}

class BookStoreApp extends StatelessWidget {
  const BookStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Nhà Sách Flutter',
        theme: ThemeData(
          colorScheme: ColorScheme.light(
            primary: Colors.brown.shade300,
            secondary: Colors.amber.shade300,
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black87),
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Sử dụng `home` để luôn bắt đầu từ `MainScreen`
        home: const MainScreen(), // <<< Đặt MainScreen làm màn hình chính

        routes: {
          // '/': (context) => const HomeScreen(), // Không cần thiết nếu MainScreen quản lý HomeScreen
          '/login': (context) => const DangNhapScreen(),
          '/register': (context) => const DangKyScreen(),
          '/cart': (context) => const CartScreen(),
          '/checkout': (context) => const ThanhToanScreen(),

          // *** SỬA Ở ĐÂY: Vô hiệu hóa route này ***
          // Dòng này sẽ gây lỗi vì BookCategoryListScreen giờ cần tham số
          // '/book-categories': (context) => const BookCategoryListScreen(),

          '/favorites': (context) => const FavoriteScreen(),
          '/profile': (context) => const ProfileScreen(), // ProfileScreen vẫn là một route riêng
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/product-detail') {
            final String maSP = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) {
                return ProductDetailScreen(maSP: maSP);
              },
            );
          }
          // Nếu bạn muốn dùng Navigator.pushNamed cho book-categories,
          // bạn sẽ phải xử lý nó ở đây giống như product-detail.
          // Nhưng vì chúng ta đã dùng MaterialPageRoute, nên không cần.
          return null;
        },
      ),
    );
  }
}