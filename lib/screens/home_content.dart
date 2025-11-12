import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../utils/app_colors.dart';
import '../models/san_pham.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_card.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // ----- FILTER NHÓM CHÍNH -----
  static const _filters = <Map<String, String>>[
    {'label': 'Tất cả', 'code': 'ALL'},
    {'label': 'Sách', 'code': 'SACH'},
    {'label': 'Đồ chơi', 'code': 'DOCHOI'},
    {'label': 'Lưu niệm', 'code': 'LUUNIEM'},
    {'label': 'Manga', 'code': 'MANGA'},
    {'label': 'VPP', 'code': 'VPP'},
  ];
  String _currentCode = 'ALL';

  // ----- DATA -----
  late Future<List<SanPham>> _futureProducts;

  // ----- SEARCH -----
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureProducts = _loadProducts();
  }

  Future<List<SanPham>> _loadProducts() async {
    try {
      if (_currentCode == 'ALL') {
        return await ApiService.fetchAllProducts();
      } else {
        return await ApiService.fetchProductsByMain(_currentCode);
      }
    } catch (e) {
      debugPrint('loadProducts error: $e');
      return <SanPham>[];
    }
  }

  Future<void> _reload() async {
    setState(() {
      _futureProducts = _loadProducts();
    });
    await _futureProducts;
  }

  Future<void> _doSearch(String q) async {
    final query = q.trim();
    setState(() {
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
          SliverToBoxAdapter(child: _buildFilterChips()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                _titleForCurrentFilter(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildProducts()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  String _titleForCurrentFilter() {
    final found = _filters.firstWhere((f) => f['code'] == _currentCode);
    return '🔎 ${found['label']}';
  }

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

  Widget _buildBannerSlider() {
    final items = [
      'assets/images/ngontinh/1.jpg',
      'assets/images/tieuthuyet/1.jpg',
      'assets/images/kinhdi/1.jpg',
      'assets/images/vientuong/1.jpg',
      'assets/images/trinhtham/1.jpg',
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
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final f = _filters[i];
          final sel = f['code'] == _currentCode;
          return ChoiceChip(
            label: Text(f['label']!),
            selected: sel,
            onSelected: (v) {
              if (!v) return;
              setState(() {
                _currentCode = f['code']!;
                _futureProducts = _loadProducts();
              });
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _filters.length,
      ),
    );
  }

  Widget _buildProducts() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return FutureBuilder<List<SanPham>>(
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
            padding: EdgeInsets.symmetric(horizontal: 16),
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
              sanPham: p,
              onAddToCartPressed: () {
                cart.addItem(p);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã thêm "${p.tenSP}" vào giỏ hàng')),
                );
              },
            );
          },
        );
      },
    );
  }
}
