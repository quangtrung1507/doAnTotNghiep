import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../utils/app_colors.dart';
import '../widgets/product_card.dart';
import '../models/san_pham.dart';
import '../services/api_service.dart';
import './book_category_list_screen.dart';

// Đây là widget chỉ chứa phần nội dung của trang chủ
class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Future<List<SanPham>> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = ApiService.fetchAllProducts();
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ trả về phần nội dung, không có Scaffold hay BottomNavigationBar
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildBannerSlider(),
          const SizedBox(height: 16),
          _buildCategoryGrid(),
          const SizedBox(height: 16),
          buildSectionTitle('📚 Sách bán chạy'),
          buildProductList(),
          buildSectionTitle('🧸 Đồ chơi'),
          buildProductList(),
          buildSectionTitle('🖊 Văn phòng phẩm'),
          buildProductList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- TẤT CẢ CÁC HÀM BUILD GIAO DIỆN CỦA BẠN ĐỀU NẰM Ở ĐÂY ---
  // ---------------- HEADER ----------------
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery
          .of(context)
          .padding
          .top + 8, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sách, đồ chơi...',
                hintStyle: const TextStyle(
                    color: AppColors.textLight, fontSize: 14),
                prefixIcon: const Icon(
                    Icons.search, color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- BANNER ----------------
  Widget _buildBannerSlider() {
    final bannerItems = [
      'lib/data/ngontinh/1.jpg',
      'lib/data/tieuthuyet/1.jpg',
      'lib/data/kinhdi/1.jpg',
      'lib/data/vientuong/1.jpg',
      'lib/data/trinhtham/1.jpg',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: CarouselSlider(
          items: bannerItems.map((path) =>
              Image.asset(path, fit: BoxFit.cover, width: 1000)).toList(),
          options: CarouselOptions(
            autoPlay: true,
            height: 160,
            viewportFraction: 1.0,
          ),
        ),
      ),
    );
  }

  // ---------------- DANH MỤC ----------------
  Widget _buildCategoryGrid() {
    final categories = [
      {'icon': Icons.menu_book, 'name': 'Sách', 'color': Colors.blue},
      {'icon': Icons.toys, 'name': 'Đồ chơi', 'color': Colors.orange},
      {'icon': Icons.card_giftcard, 'name': 'Lưu niệm', 'color': Colors.green},
      {'icon': Icons.face, 'name': 'Manga', 'color': Colors.pinkAccent},
      {'icon': Icons.create, 'name': 'VPP', 'color': Colors.purple},
      {'icon': Icons.local_offer, 'name': 'Ưu đãi', 'color': Colors.teal},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          return InkWell(
            onTap: () {
              if (index == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BookCategoryListScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Chức năng cho "${category['name']}" sắp ra mắt!'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: (category['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: category['color'] as Color,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  category['name'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- SECTION TITLE ----------------
  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------- DANH SÁCH SẢN PHẨM ----------------
  Widget buildProductList() {
    return FutureBuilder<List<SanPham>>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 260, child: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return SizedBox(
              height: 260, child: Center(child: Text('Lỗi tải sản phẩm')));
        } else {
          final products = snapshot.data ?? [];
          return SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 170,
                  child: ProductCard(
                    sanPham: products[index],
                    onAddToCartPressed: () {},
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }
}