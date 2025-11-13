// lib/screens/home_content.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../utils/app_colors.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart'; // ⬇️ ⬇️ THÊM IMPORT NÀY ⬇️ ⬇️
import '../widgets/product_card.dart';

import 'main_category_products_screen.dart';



class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // ... (Code từ dòng 25 đến 304 giữ nguyên) ...
  // (Toàn bộ phần _loadProducts, _buildHeader, _buildCategoryGrid... không thay đổi)

  // ----- DATA -----
  late Future<List<Product>> _futureProducts;

  // 🌟 THÊM: Future cho categories (để tạo Grid động)
  late Future<List<ProductCategory>> _futureCategories;

  // ----- SEARCH -----
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Tải sản phẩm "Tất cả" VÀ tải danh mục cho Grid
    _futureProducts = _loadProducts();
    _futureCategories = ApiService.fetchAllCategories();
  }

  // ⬇️ ĐÃ SỬA: Hàm này giờ CHỈ tải TẤT CẢ sản phẩm
  Future<List<Product>> _loadProducts() async {
    try {
      return await ApiService.fetchAllProducts();
    } catch (e) {
      debugPrint('loadProducts error: $e');
      return <Product>[];
    }
  }

  Future<void> _reload() async {
    setState(() {
      _futureProducts = _loadProducts();
      _futureCategories = ApiService.fetchAllCategories(); // Tải lại categories
    });
    await _futureProducts;
  }

  Future<void> _doSearch(String q) async {
    final query = q.trim();
    setState(() {
      // ⬇️ SỬA: Tìm kiếm hoặc tải lại TẤT CẢ (không filter theo _currentCode)
      _futureProducts = query.isEmpty
          ? _loadProducts()
          : ApiService.searchProducts(query);
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildBannerSlider()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ⬇️ HÀM NÀY GIỜ SẼ DÙNG FutureBuilder
          SliverToBoxAdapter(child: _buildCategoryGrid(context)),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            sliver: SliverToBoxAdapter(
              // ⬇️ ĐÃ SỬA: Tiêu đề cố định
              child: _buildSectionTitle('Sản phẩm nổi bật'),
            ),
          ),
          SliverToBoxAdapter(child: _buildProducts()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ⬇️ ĐÃ SỬA: Tiêu đề cố định
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  // (Hàm _buildHeader giữ nguyên)
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm…',
                hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                suffixIcon: (_searchCtl.text.isEmpty)
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textLight),
                  onPressed: () {
                    _searchCtl.clear();
                    _reload();
                  },
                ),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _doSearch,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  // (Hàm _buildBannerSlider giữ nguyên)
  Widget _buildBannerSlider() {
    final items = [
      'lib/assets/5.jpg',
      'lib/assets/4.jpg',
      'lib/assets/3.jpg',
      'lib/assets/2.jpg',
      'lib/assets/1.jpg',
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: CarouselSlider(
          items: items.map((p) {
            return Image.asset(
              p,
              fit: BoxFit.cover,
              width: 1000,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
              ),
            );
          }).toList(),
          options: CarouselOptions(
            autoPlay: true,
            height: 160,
            viewportFraction: 1.0,
            autoPlayInterval: const Duration(seconds: 3),
            enlargeCenterPage: false,
            aspectRatio: 16 / 9,
          ),
        ),
      ),
    );
  }

  // (Hàm _buildCategoryGrid và _buildGridItem giữ nguyên)
  Widget _buildCategoryGrid(BuildContext context) {
    // ...
    // (Toàn bộ code từ dòng 223 đến 304 giữ nguyên)
    // ...
    final Map<String, String> labelMap = {
      'book': 'Sách',
      'modelKit': 'Mô hình',
      'figure': 'Figure',
      'calculator': 'Máy tính',
      'note': 'Sổ tay',
      'watch': 'Đồng hồ',
      'pen': 'Bút',
      'draw': 'Vẽ',
      'studentBook': 'Vở',
      'compaEke': 'Compa',
      'pencilEraser': 'Bút chì',
    };

    // Map tĩnh cho Icon
    final Map<String, IconData> iconMap = {
      'book': Icons.menu_book,
      'modelKit': Icons.build_circle_outlined,
      'figure': Icons.person_search_outlined,
      'calculator': Icons.calculate_outlined,
      'note': Icons.note_alt_outlined,
      'watch': Icons.watch_outlined,
      'pen': Icons.edit_outlined,
      'draw': Icons.palette_outlined,
      'studentBook': Icons.book_outlined,
      'compaEke': Icons.square_foot_outlined,
      'pencilEraser': Icons.edit_note_outlined,
    };

    // Map tĩnh cho Màu
    final Map<String, Color> colorMap = {
      'book': Colors.green.shade400,
      'modelKit': Colors.orange.shade400,
      'figure': Colors.blue.shade400,
      'calculator': Colors.teal.shade400,
      'note': Colors.indigo.shade400,
      'watch': Colors.lime.shade700,
      'pen': Colors.pink.shade300,
      'draw': Colors.purple.shade400,
      'studentBook': Colors.lightGreen.shade400,
      'compaEke': Colors.brown.shade400,
      'pencilEraser': Colors.blueGrey.shade400,
    };


    return FutureBuilder<List<ProductCategory>>(
      future: _futureCategories,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 100, child: Center(child: LinearProgressIndicator()));
        }

        final allCategories = snapshot.data ?? [];

        // 1. Lọc ra các 'mainCode' (category_type) duy nhất
        final Set<String> uniqueTypes = {};
        for (final cat in allCategories) {
          if (cat.mainCode != null) {
            uniqueTypes.add(cat.mainCode!);
          }
        }
        final List<String> categoryCodes = uniqueTypes.toList();

        // 2. Xây dựng GridView
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categoryCodes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final code = categoryCodes[index];
            final label = labelMap[code] ?? code; // Lấy tên, hoặc dùng code
            final icon = iconMap[code] ?? Icons.category; // Lấy icon, hoặc mặc định
            final color = colorMap[code] ?? Colors.grey; // Lấy màu, hoặc mặc định

            return _buildGridItem(
              label,
              icon,
              color,
                  () {
                // 3. TẤT CẢ CÁC NÚT ĐỀU LÀM VIỆC NÀY:
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MainCategoryProductsScreen(
                    mainCode: code, // Truyền 'book', 'pen', 'modelKit'...
                    title: label,
                  ),
                ));
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGridItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }


  // (Hàm _buildProducts)
  Widget _buildProducts() {
    // ⬇️ ⬇️ ⬇️ BẮT ĐẦU SỬA ⬇️ ⬇️ ⬇️
    // 1. Lấy cả 2 provider
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    // ⬆️ ⬆️ ⬆️ KẾT THÚC SỬA ⬆️ ⬆️ ⬆️

    return FutureBuilder<List<Product>>(
      future: _futureProducts,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 320,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
            Text('Lỗi tải sản phẩm: ${snap.error}', style: const TextStyle(color: Colors.red)),
          );
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Không có sản phẩm để hiển thị.'),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 260,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final p = items[i];
            return ProductCard(
              product: p,
              // ⬇️ ⬇️ ⬇️ SỬA LOGIC ONADD_TO_CART ⬇️ ⬇️ ⬇️
              onAddToCartPressed: () {
                // 2. Kiểm tra đăng nhập
                if (auth.isAuthenticated) {
                  // 3a. Đã đăng nhập: Thêm vào giỏ
                  cart.addItem(p);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã thêm "${p.tenSP}" vào giỏ hàng')),
                  );
                } else {
                  // 3b. Chưa đăng nhập: Chuyển đến trang Login
                  Navigator.of(context).pushNamed('/login');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng!')),
                  );
                }
              },
              // ⬆️ ⬆️ ⬆️ KẾT THÚC SỬA ⬆️ ⬆️ ⬆️
            );
          },
        );
      },
    );
  }
}

