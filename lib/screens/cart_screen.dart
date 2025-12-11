// lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  String _normalizeImg(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;

    // ApiService.baseUrl = http://host:8080/v1/api
    final api = ApiService.baseUrl;
    final cutIndex = api.indexOf('/v1/api');
    final root = cutIndex == -1 ? api : api.substring(0, cutIndex);
    final u = '$root$url'; // -> http://host:8080/uploads/...

    return u.replaceAll('//', '/').replaceFirst(':/', '://');
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final customerCode = auth.customerCode;

    final List<CartItem> items = cart.items;

    // 👉 Tổng tiền của TOÀN BỘ giỏ hàng
    final double totalAll = items.fold<double>(
      0.0,
          (sum, e) => sum + e.price * e.quantity,
    );

    return Scaffold(
      // ✅ nền đồng bộ với Home / Profile / Favorite
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        title: const Text(
          'Giỏ Hàng',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),

      body: Container(
        color: AppColors.background,
        child: items.isEmpty
            ? const Center(
          child: Text(
            'Giỏ hàng của bạn đang trống',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
        )
            : Column(
          children: [
            // ---- Header đơn giản: số lượng sản phẩm ----
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  const Text(
                    'Giỏ hàng của bạn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${items.length} sản phẩm',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),

            // ----------------- DANH SÁCH SẢN PHẨM -----------------
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final img = _normalizeImg(item.imageUrl);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // hình
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              img,
                              width: 60,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 80,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // thông tin + +/- + xoá
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currency.format(item.price),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        // nút trừ
                                        InkWell(
                                          onTap: () async {
                                            await cart.decreaseQuantity(
                                              item.productCode,
                                              customerCode,
                                            );
                                          },
                                          borderRadius:
                                          BorderRadius.circular(20),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors
                                                    .grey.shade400,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.remove,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // nút cộng
                                        InkWell(
                                          onTap: () async {
                                            await cart.increaseQuantity(
                                              item.productCode,
                                              customerCode,
                                            );
                                          },
                                          borderRadius:
                                          BorderRadius.circular(20),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors
                                                    .grey.shade400,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // nút xoá
                                    IconButton(
                                      onPressed: () async {
                                        await cart.removeItem(
                                          item.productCode,
                                          customerCode,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ----------------- TỔNG VÀ NÚT THANH TOÁN -----------------
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng:',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currency.format(totalAll),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  onPressed: () {
                    if (!auth.isAuthenticated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bạn cần đăng nhập để thanh toán',
                          ),
                        ),
                      );
                      return;
                    }

                    // 👉 Thanh toán TOÀN BỘ giỏ, không chọn từng sản phẩm
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CheckoutScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Thanh Toán',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
