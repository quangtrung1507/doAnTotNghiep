// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import './checkout_screen.dart'; // ✅ SỬA: import relative đúng
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/favorite_provider.dart';
import '../models/cart_item.dart'; // ✅ THÊM: để tạo CartItem tạm cho Buy Now

class ProductDetailScreen extends StatefulWidget {
  final String productCode;
  final Product? initialProduct; // optional

  const ProductDetailScreen({
    super.key,
    required this.productCode,
    this.initialProduct,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Product> _future;
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // tab: overview | details | author
  String _currentTab = 'overview';

  // số lượng, mặc định = 1, luôn hiển thị
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _future = _loadProduct();
  }

  Future<Product> _loadProduct() async {
    if (widget.initialProduct != null) {
      // KHÔNG set isFavorite ở đây, dùng FavoriteProvider để kiểm tra
      return widget.initialProduct!;
    }
    final p = await ApiService.fetchProductByCode(widget.productCode);
    // p.isFavorite không đáng tin vì API không trả, nên cũng không set state tại đây
    return p;
  }

  String _normalizeImg(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;

    final api = ApiService.baseUrl; // http://host:port/v1/api
    final cutIndex = api.indexOf('/v1/api');
    final root = cutIndex == -1 ? api : api.substring(0, cutIndex);
    final u = '$root$url';
    return u.replaceAll('//', '/').replaceFirst(':/', '://');
  }

  void _changeTab(String key) {
    setState(() => _currentTab = key);
  }

  void _incQty() {
    setState(() => _quantity++);
  }

  void _decQty() {
    if (_quantity <= 1) return;
    setState(() => _quantity--);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Center(
              child: Text('Lỗi tải sản phẩm: ${snap.error ?? "Không có dữ liệu"}'),
            ),
          );
        }

        final product = snap.data!;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textDark),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // 👉 icon giỏ hàng + badge số lượng (lấy từ CartProvider)
              Consumer<CartProvider>(
                builder: (context, cart, _) {
                  final count = cart.items.length; // nếu khác thì đổi cho đúng
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/cart');
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
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
                          if (count > 0)
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
                                  count > 9 ? '9+' : '$count',
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
                  );
                },
              ),
            ],
          ),
          body: _buildBody(product),
          bottomNavigationBar: _buildBottomBar(product),
        );
      },
    );
  }

  // ================= BODY =================

  Widget _buildBody(Product p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 140), // chừa chỗ cho bottom bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopCard(p),
          const SizedBox(height: 20),
          _buildTabs(p), // ✅ truyền product xuống để thao tác favorite
          const SizedBox(height: 16),
          _buildTabContent(p),
        ],
      ),
    );
  }

  /// Ảnh + khối tên dạng L ngang (giống design, chỉ hiển thị tên sách)
  Widget _buildTopCard(Product p) {
    final imgUrl = _normalizeImg(p.hinhAnh);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ảnh sách
          Container(
            width: 110,
            height: 150,
            margin: const EdgeInsets.all(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: imgUrl.isEmpty
                  ? Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 40),
              )
                  : Image.network(
                imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),
          ),
          // Khối chữ nối liền – L ngang
          Expanded(
            child: Container(
              height: 150,
              padding: const EdgeInsets.only(
                right: 16,
                top: 20,
                bottom: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  p.tenSP,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TABS =================

  Widget _buildTabs(Product p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _tabButton('overview', 'Overview'),
        const SizedBox(width: 12),
        _tabButton('details', 'Details'),
        const SizedBox(width: 12),
        _tabButton('author', 'Author'),
        const Spacer(),
        _buildFavoriteButton(p),
      ],
    );
  }

  Widget _tabButton(String key, String label) {
    final bool selected = _currentTab == key;
    return GestureDetector(
      onTap: () => _changeTab(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.textLight.withOpacity(0.3),
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  // ✅ Nút yêu thích: dùng FavoriteProvider giống ngoài Home, KHÔNG dùng biến cục bộ
  Widget _buildFavoriteButton(Product p) {
    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, _) {
        final auth = context.read<AuthProvider>();
        final customerCode = auth.customerCode;

        final isFavorite = favoriteProvider.isFavorite(p.maSP);

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            if (customerCode == null || customerCode.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bạn cần đăng nhập để dùng danh sách yêu thích'),
                ),
              );
              return;
            }

            try {
              await favoriteProvider.toggleFavorite(p, customerCode);
              // Không cần setState, Provider đã notifyListeners nên UI tự rebuild
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi cập nhật yêu thích: $e')),
              );
            }
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : AppColors.textDark,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabContent(Product p) {
    switch (_currentTab) {
      case 'details':
        return _buildDetailsTab(p);
      case 'author':
        return _buildAuthorTab(p);
      case 'overview':
      default:
        return _buildOverviewTab(p);
    }
  }

  Widget _buildOverviewTab(Product p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About book',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          p.moTa.isEmpty ? 'Chưa có mô tả cho sản phẩm này.' : p.moTa,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsTab(Product p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin chi tiết',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _detailRow('Thể loại', p.categoryName),
              const Divider(height: 18),
              _detailRow('Mã sản phẩm', p.maSP),
              const Divider(height: 18),
              _detailRow('Kho còn', p.stockQuantity.toString()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorTab(Product p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Author',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            p.author.isEmpty ? 'Đang cập nhật' : p.author,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  // ================= BOTTOM BAR =================

  Widget _buildBottomBar(Product p) {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price + quantity selector (luôn hiện)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currency.format(p.gia),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _circleIconButton(
                      icon: Icons.remove,
                      onTap: _decQty,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _circleIconButton(
                      icon: Icons.add,
                      onTap: _incQty,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () async {
                      if (_quantity < 1) {
                        setState(() => _quantity = 1);
                      }
                      for (var i = 0; i < _quantity; i++) {
                        await cart.addItem(p, auth.customerCode);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                            Text('Đã thêm $_quantity "${p.tenSP}" vào giỏ hàng'),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Thêm vào giỏ',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    // ✅ SỬA: Mua ngay -> sang Checkout luôn, không add vào giỏ
                    onPressed: () async {
                      if (_quantity < 1) {
                        setState(() => _quantity = 1);
                      }

                      final customerCode = auth.customerCode;
                      if (customerCode == null || customerCode.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bạn cần đăng nhập để mua ngay')),
                        );
                        Navigator.pushNamed(context, '/login');
                        return;
                      }

                      final buyNowItem = CartItem(product: p, quantity: _quantity);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(
                            buyNow: true,
                            buyNowItems: [buyNowItem],
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Mua ngay',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.textLight.withOpacity(0.4)),
        ),
        child: Icon(icon, size: 18, color: AppColors.textDark),
      ),
    );
  }
}
