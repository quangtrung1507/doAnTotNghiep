// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Các màn hình (Screens)
import 'screens/main_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/favorite_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/auth_screen.dart';

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

        // Màn hình khởi tạo
        home: const AppInitializer(),

        routes: {
          '/home': (context) => const MainScreen(),
          '/login': (context) => const AuthScreen(),
          '/register': (context) => const AuthScreen(),
          '/cart': (context) => const CartScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/favorites': (context) => const FavoriteScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/orders': (context) => const OrderTrackingScreen(),
        },

        // 🔧 SỬA Ở ĐÂY: dùng productCode thay vì maSP
        onGenerateRoute: (settings) {
          if (settings.name == '/product-detail') {
            final args = settings.arguments;
            if (args is String) {
              return MaterialPageRoute(
                builder: (context) => ProductDetailScreen(
                  productCode: args,   // dùng productCode
                ),
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
// WIDGET KHỞI TẠO
// -----------------------------------------------------
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.loadAuthToken();

      if (mounted && authProvider.isAuthenticated) {
        final customerCode = authProvider.customerCode;
        if (customerCode != null && customerCode.isNotEmpty) {
          print('Đã đăng nhập, đang tải dữ liệu cho $customerCode...');
          await Future.wait([
            context.read<FavoriteProvider>().fetchFavorites(customerCode),
            context.read<CartProvider>().fetchCart(customerCode),
          ]);
        }
      }
    } catch (e) {
      print("Lỗi khi khởi tạo App: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const MainScreen();
      },
    );
  }
}
