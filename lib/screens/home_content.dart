// lib/screens/home_content.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../utils/app_colors.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/product_card.dart';

import 'main_category_products_screen.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // ----- DATA -----
  late Future<List<Product>> _futureProducts;
  late Future<List<ProductCategory>> _futureCategories;

  // ✅ cache list sản phẩm để search local (không phụ thuộc backend search)
  List<Product> _allProducts = [];
  bool _hasLoadedAll = false;

  // ----- SEARCH -----
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureProducts = _loadProducts();
    _futureCategories = ApiService.fetchAllCategories();
  }

  Future<List<Product>> _loadProducts() async {
    try {
      final list = await ApiService.fetchAllProducts();
      _allProducts = list; // ✅ cache để search local
      _hasLoadedAll = true;
      return list;
    } catch (e) {
      debugPrint('loadProducts error: $e');
      _allProducts = [];
      _hasLoadedAll = true;
      return <Product>[];
    }
  }

  Future<void> _reload() async {
    setState(() {
      _futureProducts = _loadProducts();
      _futureCategories = ApiService.fetchAllCategories();
    });
    await _futureProducts;
  }

  // ====== SEARCH LOCAL ======
  String _norm(String s) => s.toLowerCase().trim();

  bool _matchName(Product p, String q) {
    final name = _norm(p.tenSP);

    if (q.isEmpty) return true;

    // match theo cả chuỗi
    if (name.contains(q)) return true;

    // match theo từng từ (AND)
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.length <= 1) return false;
    return tokens.every((t) => name.contains(t));
  }

  Future<void> _doSearch(String q) async {
    final query = _norm(q);

    // ✅ đảm bảo đã có cache
    if (!_hasLoadedAll) {
      await _loadProducts(); // chỉ gọi lần đầu nếu chưa load
    }

    final filtered = query.isEmpty
        ? _allProducts
        : _allProducts.where((p) => _matchName(p, query)).toList();

    setState(() {
      _futureProducts = Future.value(filtered);
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
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(child: _buildCategoryStrip(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            sliver: SliverToBoxAdapter(
              child: _buildSectionTitle('Products'),
            ),
          ),
          SliverToBoxAdapter(child: _buildProducts()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context); // 👈 LẤY CART
    final cartCount = cart.items.length; // 👈 SỐ LƯỢNG TRONG GIỎ

    final username = (auth.currentUser?.username ?? '').trim();
    final customerCode = (auth.customerCode ?? '').trim();

    // Ưu tiên hiện username, nếu chưa có thì fallback về customerCode, cuối cùng là "bạn"
    final greetingName =
    username.isNotEmpty ? username : (customerCode.isNotEmpty ? customerCode : 'bạn');

    final top = MediaQuery.of(context).padding.top;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------- Hàng avatar + greeting + icon giỏ --------
          Row(
            children: [
              // avatar tròn
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Text chào
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Xin chào,',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      greetingName.isEmpty ? 'Khám phá sách hôm nay nhé' : greetingName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Icon giỏ hàng trong khung tròn + BADGE
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    if (cartCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            cartCount > 9 ? '9+' : '$cartCount',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // -------- Thanh search + nút search tròn --------
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtl,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search for books',
                    hintStyle: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _doSearch,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              // Nút search tròn màu primary
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () => _doSearch(_searchCtl.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= BANNER =================

  Widget _buildBannerSlider() {
    final items = [
      'lib/assets/5.jpg',
      'lib/assets/4.jpg',
      'lib/assets/3.jpg',
      'lib/assets/2.jpg',
      'lib/assets/1.jpg',
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CarouselSlider(
          items: items.map((p) {
            return Image.asset(
              p,
              fit: BoxFit.cover,
              width: 1000,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image,
                  size: 48,
                  color: Colors.grey,
                ),
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

  // ================= CATEGORY STRIP =================

  Widget _buildCategoryStrip(BuildContext context) {
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
    final Map<String, IconData> iconMap = {
      'book': Icons.menu_book_rounded,
      'modelKit': Icons.directions_car_filled_rounded,
      'figure': Icons.toys_rounded,
      'calculator': Icons.calculate_rounded,
      'note': Icons.note_alt_rounded,
      'watch': Icons.watch_rounded,
      'pen': Icons.edit_rounded,
      'draw': Icons.brush_rounded,
      'studentBook': Icons.book_outlined,
      'compaEke': Icons.square_foot_rounded,
      'pencilEraser': Icons.edit_note_rounded,
    };

    return FutureBuilder<List<ProductCategory>>(
      future: _futureCategories,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 90,
            child: Center(child: LinearProgressIndicator()),
          );
        }

        final allCategories = snapshot.data ?? [];
        final Set<String> uniqueTypes = {};
        for (final cat in allCategories) {
          if (cat.mainCode != null) {
            uniqueTypes.add(cat.mainCode!);
          }
        }
        final List<String> categoryCodes = uniqueTypes.toList();

        return SizedBox(
          height: 90,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: categoryCodes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final code = categoryCodes[index];
              final label = labelMap[code] ?? code;
              final icon = iconMap[code] ?? Icons.category_rounded;

              return _buildCategoryItem(
                label: label,
                icon: icon,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MainCategoryProductsScreen(
                        mainCode: code,
                        title: label,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TIÊU ĐỀ SECTION =================

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  // ================= GRID SẢN PHẨM =================

  Widget _buildProducts() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context); // listen: true để tự rebuild

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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Lỗi tải sản phẩm: ${snap.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Không có sản phẩm để hiển thị.'),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 260,
          ),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int i) {
            final p = items[i];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                      productCode: p.maSP,
                    ),
                  ),
                );
              },
              child: ProductCard(
                product: p,
                onAddToCartPressed: () async {
                  try {
                    await cart.addItem(p, auth.customerCode);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã thêm "${p.tenSP}" vào giỏ hàng'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
