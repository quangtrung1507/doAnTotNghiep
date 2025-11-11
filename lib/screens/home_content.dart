// lib/screens/home_content.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart'; // <<< ĐÃ THÊM DÒNG NÀY
import '../utils/app_colors.dart';
import '../widgets/product_card.dart';
import '../models/san_pham.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart'; // <<< ĐÃ THÊM DÒNG NÀY
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
          _buildCategoryGrid(), // <<< HÀM NÀY ĐÃ ĐƯỢC SỬA BÊN DƯỚI
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
          // BIỂU TƯỢNG MENU (NẾU CẦN, BẠN CÓ THỂ BỎ NẾU KHÔNG DÙNG)
          // IconButton(
          //   icon: const Icon(Icons.menu, color: AppColors.card),
          //   onPressed: () {
          //     // Xử lý khi nhấn nút menu
          //     Scaffold.of(context).openDrawer(); // Mở Drawer nếu có
          //   },
          // ),
          const SizedBox(width: 12), // Giữ khoảng cách nếu không có menu
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
      'assets/images/ngontinh/1.jpg', // <<< ĐÃ THAY ĐỔI ĐƯỜNG DẪN: BẠN CẦN DI CHUYỂN ẢNH VÀO THƯ MỤC assets/images/
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
          items: bannerItems.map((path) {
            return Image.asset(
              path,
              fit: BoxFit.cover,
              width: 1000,
              errorBuilder: (context, error, stackTrace) => Container(
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
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
          ),
        ),
      ),
    );
  }

  // ---------------- DANH MỤC (ĐÃ SỬA) ----------------
  Widget _buildCategoryGrid() {
    // *** SỬA Ở ĐÂY: Thêm mã (code) cho từng danh mục chính ***
    final categories = [
      {'icon': Icons.menu_book, 'name': 'Sách', 'color': Colors.blue, 'code': 'SACH'},
      {'icon': Icons.toys, 'name': 'Đồ chơi', 'color': Colors.orange, 'code': 'DOCHOI'},
      {'icon': Icons.card_giftcard, 'name': 'Lưu niệm', 'color': Colors.green, 'code': 'LUUNIEM'},
      {'icon': Icons.face, 'name': 'Manga', 'color': Colors.pinkAccent, 'code': 'MANGA'},
      {'icon': Icons.create, 'name': 'VPP', 'color': Colors.purple, 'code': 'VPP'},
      {'icon': Icons.local_offer, 'name': 'Ưu đãi', 'color': Colors.teal, 'code': 'UUDAI'},
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
              // *** SỬA Ở ĐÂY: Kiểm tra và điều hướng ***
              // (Chúng ta sẽ tạm thời điều hướng tất cả,
              // bạn có thể thêm lại logic "sắp ra mắt" nếu muốn)

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookCategoryListScreen(
                    // Truyền tham số mà màn hình kia yêu cầu
                    mainCategoryCode: category['code'] as String,
                    title: category['name'] as String,
                  ),
                ),
              );
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
    // Lấy instance của CartProvider, listen: false vì chúng ta chỉ gọi hàm
    final cartProvider = Provider.of<CartProvider>(context, listen: false); // <<< ĐÃ THÊM DÒNG NÀY

    return FutureBuilder<List<SanPham>>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 260, child: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          // Hiển thị lỗi rõ ràng hơn
          return SizedBox(
              height: 260,
              child: Center(child: Text('Lỗi tải sản phẩm: ${snapshot.error}')));
        } else {
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const SizedBox(
              height: 260,
              child: Center(
                child: Text(
                  'Không có sản phẩm nào để hiển thị.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }
          return SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final sanPham = products[index]; // Lấy sản phẩm hiện tại
                return SizedBox(
                  width: 170,
                  child: ProductCard(
                    sanPham: sanPham,
                    // TRUYỀN HÀM THÊM VÀO GIỎ HÀNG THỰC TẾ
                    onAddToCartPressed: () {
                      cartProvider.addItem(sanPham);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã thêm "${sanPham.tenSP}" vào giỏ hàng!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
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