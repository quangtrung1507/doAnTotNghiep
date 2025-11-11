// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/san_pham.dart';
import '../utils/app_colors.dart';
import '../providers/favorite_provider.dart';

class ProductCard extends StatelessWidget {
  final SanPham sanPham;
  final VoidCallback? onAddToCartPressed;

  const ProductCard({
    Key? key,
    required this.sanPham,
    this.onAddToCartPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String imageUrl = (sanPham.hinhAnh.isNotEmpty &&
        (sanPham.hinhAnh.startsWith('http') ||
            sanPham.hinhAnh.startsWith('https'
            )))
        ? sanPham.hinhAnh
        : 'http://10.0.2.2:8080${sanPham.hinhAnh}';

    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/product-detail',
          arguments: sanPham.maSP,
        );
      },
      child: Card(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        shadowColor: Colors.black12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  // Nút yêu thích
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<FavoriteProvider>( // Lắng nghe FavoriteProvider
                      builder: (context, favoriteProvider, child) {
                        final bool isFav = favoriteProvider.isFavorite(sanPham.maSP);
                        return GestureDetector(
                          onTap: () {
                            // <<< ĐÃ SỬA DÒNG NÀY: TRUYỀN TOÀN BỘ ĐỐI TƯỢNG SANPHAM
                            favoriteProvider.toggleFavorite(sanPham);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFav
                                      ? 'Đã xóa "${sanPham.tenSP}" khỏi yêu thích!'
                                      : 'Đã thêm "${sanPham.tenSP}" vào yêu thích!',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : AppColors.textDark,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                sanPham.tenSP,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormatter.format(sanPham.gia),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    color: AppColors.primary,
                    onPressed: onAddToCartPressed,
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