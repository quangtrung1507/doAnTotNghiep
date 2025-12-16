// lib/screens/voucher_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/coupon_model.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({Key? key}) : super(key: key);

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  late Future<List<CouponModel>> _futureCoupons;
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _futureCoupons = ApiService.fetchCoupons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Voucher',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<CouponModel>>(
        future: _futureCoupons,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi tải coupon: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Không có coupon khả dụng.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: items.length,
            itemBuilder: (_, i) => _couponCard(items[i]),
          );
        },
      ),
    );
  }

  Widget _couponCard(CouponModel c) {
    final typeText = (c.promotionTypeCode == 'PT_01')
        ? 'Giảm ${(c.value * 100).toStringAsFixed(0)}%'
        : 'Giảm ${_currency.format(c.value)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.local_offer_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.couponCode,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c.couponName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  typeText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
