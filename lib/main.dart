// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Các màn hình (Screens)
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/favorite_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/order_tracking_screen.dart';

// Các Providers
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/order_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BookStoreApp());
}

class BookStoreApp extends StatelessWidget {
  const BookStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 🔴 QUAN TRỌNG: Phải dùng 'lazy: false' cho AuthProvider
        // Để nó được tạo ngay lập tức và AppInitializer có thể gọi
        ChangeNotifierProvider(create: (_) => AuthProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),

        ChangeNotifierProxyProvider<AuthProvider, FavoriteProvider>(
          create: (context) => FavoriteProvider(),
          update: (context, auth, previousProvider) {
            final provider = previousProvider ?? FavoriteProvider();
            provider.updateAuth(auth.isAuthenticated);
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Nhà Sách Flutter',
        theme: ThemeData(
          // (ThemeData của bạn giữ nguyên)
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

        home: const AppInitializer(),

        routes: {
          // (routes của bạn giữ nguyên)
          '/home': (context) => const MainScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/cart': (context) => const CartScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/favorites': (context) => const FavoriteScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/orders': (context) => const OrderTrackingScreen(),
        },

        onGenerateRoute: (settings) {
          // (onGenerateRoute của bạn giữ nguyên)
          if (settings.name == '/product-detail') {
            final args = settings.arguments;
            if (args is String) {
              return MaterialPageRoute(
                builder: (context) {
                  return ProductDetailScreen(maSP: args);
                },
              );
            }
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Lỗi: Không có mã sản phẩm')),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}

// -----------------------------------------------------
// 🔴 WIDGET KHỞI TẠO (ĐÃ SỬA HOÀN CHỈNH) 🔴
// -----------------------------------------------------
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  // Biến để theo dõi quá trình tải
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    // Gọi hàm tải dữ liệu khi widget vừa được tạo
    _initializationFuture = _initializeApp();
  }

  /// Hàm tải dữ liệu chính khi khởi động App
  Future<void> _initializeApp() async {
    // Dùng context.read an toàn hơn trong initState/async
    final authProvider = context.read<AuthProvider>();

    try {
      // Bước 1: Tải Token và User từ bộ nhớ máy
      await authProvider.loadAuthToken();

      // Kiểm tra nếu người dùng đã đăng nhập từ trước
      if (mounted && authProvider.isAuthenticated) {
        final customerCode = authProvider.customerCode;
        if (customerCode != null && customerCode.isNotEmpty) {

          print('Đã đăng nhập, đang tải dữ liệu cho $customerCode...');

          // Bước 2: Tải đồng thời Giỏ hàng và Yêu thích
          // (Chạy song song 2 API để tiết kiệm thời gian)
          await Future.wait([
            // Tải Yêu thích
            context.read<FavoriteProvider>().fetchFavorites(customerCode),

            // Tải Giỏ hàng
            context.read<CartProvider>().fetchCart(customerCode),
          ]);
        }
      }
    } catch (e) {
      // Nếu có lỗi (ví dụ: mất mạng), cứ in ra và tiếp tục vào app
      print("Lỗi khi khởi tạo App: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dùng FutureBuilder để hiển thị màn hình Loading
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // KHI ĐANG TẢI (Auth, Cart, Fav): Hiển thị vòng xoay
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // KHI TẢI XONG: Vào màn hình chính
        // (Lúc này MainScreen sẽ tự động hiển thị đúng
        // dựa trên dữ liệu đã được tải vào các Provider)
        return const MainScreen();
      },
    );
  }
}