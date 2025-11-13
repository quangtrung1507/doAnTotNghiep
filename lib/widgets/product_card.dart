// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';
import '../providers/favorite_provider.dart';
import '../providers/auth_provider.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onAddToCartPressed;

  const ProductCard({
    Key? key,
    required this.product,
    this.onAddToCartPressed,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isAddedToCart = false;

  // Hàm kiểm tra đăng nhập
  Future<bool> _checkLogin(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Phải có Token VÀ User data thì mới tính là Login xịn
    bool isReallyLoggedIn = authProvider.isAuthenticated && authProvider.currentUser != null;

    if (isReallyLoggedIn) return true;

    final bool? shouldLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.lock, color: Colors.orange), SizedBox(width: 8), Text("Yêu cầu đăng nhập")]),
        content: const Text("Bạn cần đăng nhập để lưu sản phẩm vào danh sách của bạn."),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Hủy")),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Đăng nhập")),
        ],
      ),
    );

    if (shouldLogin == true && context.mounted) {
      Navigator.of(context).pushNamed('/login');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = (widget.product.hinhAnh.isNotEmpty &&
        (widget.product.hinhAnh.startsWith('http') || widget.product.hinhAnh.startsWith('https')))
        ? widget.product.hinhAnh
        : 'http://10.0.2.2:8080${widget.product.hinhAnh}';

    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Lấy provider (chỉ đọc)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Card(
      color: AppColors.card,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Cắt gọn hình ảnh thừa
      child: InkWell(
        // 1. SỰ KIỆN NHẤN VÀO TOÀN BỘ THẺ -> XEM CHI TIẾT
        onTap: () {
          Navigator.of(context).pushNamed(
            '/product-detail',
            arguments: widget.product.maSP,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHẦN HÌNH ẢNH (Chứa nút Tim) ---
            Expanded(
              child: Stack(
                children: [
                  // Ảnh nền
                  Positioned.fill(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                    ),
                  ),

                  // 2. NÚT YÊU THÍCH (Góc trên phải)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Consumer<FavoriteProvider>(
                      builder: (context, favoriteProvider, child) {
                        final bool isFav = favoriteProvider.isFavorite(widget.product.maSP);

                        // Dùng IconButton: Nó tự động chặn sự kiện nhấn xuyên qua -> Không bị nhảy trang detail
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.grey,
                            ),
                            onPressed: () async {
                              // --- LOGIC LƯU DB Ở ĐÂY ---

                              // Bước 1: Check Login
                              final isLoggedIn = await _checkLogin(context);
                              if (!isLoggedIn) return;

                              // Bước 2: Gọi Provider để lưu vào DB
                              // authProvider.customerCode chính là ID tài khoản của bạn
                              favoriteProvider.toggleFavorite(widget.product, authProvider.customerCode);

                              if(context.mounted) {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isFav ? "Đã xóa khỏi yêu thích" : "Đã lưu vào yêu thích"),
                                      duration: const Duration(seconds: 1),
                                    )
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // --- PHẦN THÔNG TIN (Chứa nút Giỏ hàng) ---
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.tenSP,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Giá tiền
                      Text(
                        currencyFormatter.format(widget.product.gia),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),

                      // 3. NÚT GIỎ HÀNG NHỎ
                      IconButton(
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: _isAddedToCart
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.add_shopping_cart, color: AppColors.primary),
                        onPressed: () async {
                          // --- LOGIC LƯU GIỎ HÀNG ---

                          // Bước 1: Check Login
                          final isLoggedIn = await _checkLogin(context);
                          if (!isLoggedIn) return;

                          if (_isAddedToCart) return;

                          // Bước 2: Gọi callback để thêm vào giỏ (Callback này sẽ gọi API)
                          if (widget.onAddToCartPressed != null) widget.onAddToCartPressed!();

                          setState(() => _isAddedToCart = true);
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setState(() => _isAddedToCart = false);
                          });
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}