// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Các màn hình (Screens)
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/product_detail_screen.dart'; // 👈 QUAN TRỌNG: Phải import file này
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),

        // ProxyProvider cho Favorite (như đã sửa trước đó)
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

        // Màn hình khởi động
        home: const AppInitializer(),

        // Định nghĩa các đường dẫn tĩnh
        routes: {
          '/home': (context) => const MainScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/cart': (context) => const CartScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/favorites': (context) => const FavoriteScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/orders': (context) => const OrderTrackingScreen(),
        },

        // 🔴 QUAN TRỌNG: Xử lý đường dẫn động (có tham số)
        onGenerateRoute: (settings) {
          // Khi gọi '/product-detail'
          if (settings.name == '/product-detail') {
            // Lấy tham số (Mã SP) được gửi kèm
            final args = settings.arguments;

            // Kiểm tra nếu args là String thì mới mở trang
            if (args is String) {
              return MaterialPageRoute(
                builder: (context) {
                  return ProductDetailScreen(maSP: args);
                },
              );
            }
            // Nếu không có mã SP -> Báo lỗi
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Lỗi: Không có mã sản phẩm')),
              ),
            );
          }
          return null; // Các route khác để mặc định
        },
      ),
    );
  }
}

// Widget Khởi tạo (Giữ nguyên như cũ)
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).loadAuthToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading && !auth.isAuthenticated) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return const MainScreen();
      },
    );
  }
}