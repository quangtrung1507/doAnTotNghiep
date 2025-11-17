// lib/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderCode;
  const OrderDetailScreen({super.key, required this.orderCode});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  late Future<Order> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchOrderDetails(widget.orderCode);
  }

  String _normalizeImg(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final u = '${ApiService.baseUrl}$url';
    // sửa // thành /
    return u.replaceAll('//', '/').replaceFirst(':/', '://');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đơn ${widget.orderCode}')),
      body: FutureBuilder<Order>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('Lỗi: ${snap.error ?? "Không có dữ liệu"}'));
          }
          final o = snap.data!;

          // Tạm tính từ chi tiết
          final subtotal = o.details.fold<double>(0.0, (s, d) => s + d.price * d.quantity);

          // Nếu header không trả shippingFee, giả sử 0
          final shipping = 0.0;

          // Giảm giá suy luận: subtotal - finalAmount (nếu finalAmount < subtotal)
          final double discount =
          (subtotal - o.totalAmount).clamp(0, double.infinity).toDouble();

          final total = o.totalAmount; // finalAmount từ server

          // Tìm voucher dùng: ưu tiên ở header, nếu trống thì check chi tiết
          final usedPromo = o.promotionCode ??
              (o.details.firstWhere(
                      (d) => (d.promotionCode ?? '').isNotEmpty,
                  orElse: () => o.details.isNotEmpty
                      ? o.details.first
                      : OrderDetail(
                      productCode: '',
                      productName: '',
                      imageUrl: '',
                      price: 0,
                      quantity: 0))
                  .promotionCode);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _statusCard(o),
              const SizedBox(height: 12),
              _addressCard(o),
              const SizedBox(height: 12),
              if ((usedPromo ?? '').isNotEmpty) _promoCard(code: usedPromo!, name: o.promotionName),
              if ((usedPromo ?? '').isNotEmpty) const SizedBox(height: 12),
              _itemsCard(o),
              const SizedBox(height: 12),
              _totalCard(
                subtotal: subtotal,
                discount: discount,
                shipping: shipping,
                total: total,
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _statusCard(Order o) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long),
        title: Text(_vnStatus(o.status), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Tạo lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(o.orderDate)}'),
      ),
    );
  }

  Widget _addressCard(Order o) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.location_on_outlined),
        title: const Text('Địa chỉ nhận hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${o.address}\nSĐT: ${o.phoneNumber}'),
      ),
    );
  }

  Widget _promoCard({required String code, String? name}) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.card_giftcard),
        title: Text('Đã áp dụng voucher: $code',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: name == null || name.isEmpty ? null : Text(name),
      ),
    );
  }

  Widget _itemsCard(Order o) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...o.details.map((d) {
              final img = _normalizeImg(d.imageUrl);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: (img.isNotEmpty)
                    ? Image.network(
                  img, width: 52, height: 52, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 52, height: 52,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image),
                  ),
                )
                    : Container(width: 52, height: 52, color: Colors.grey.shade200, child: const Icon(Icons.image)),
                title: Text(d.productName),
                subtitle: Text('SL: ${d.quantity} • Đơn giá: ${_currency.format(d.price)}'),
                trailing: Text(_currency.format(d.price * d.quantity),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _totalCard({
    required double subtotal,
    required double discount,
    required double shipping,
    required double total,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _row('Tạm tính', _currency.format(subtotal)),
            _row('Giảm giá', '- ${_currency.format(discount)}', valueColor: Colors.red),
            _row('Phí vận chuyển', _currency.format(shipping)),
            const Divider(),
            _row('Tổng thanh toán', _currency.format(total),
                isBold: true, valueColor: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k),
          Text(v,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor,
              )),
        ],
      ),
    );
  }

  String _vnStatus(String s) {
    switch (s) {
      case 'UNPAID':
        return 'Chưa thanh toán';
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'PENDING_SHIPMENT':
        return 'Chờ vận chuyển';
      case 'IN_TRANSIT':
        return 'Đã vận chuyển';
      case 'DELIVERED':
        return 'Đã giao';
      case 'NEED_REVIEW':
        return 'Cần đánh giá';
      case 'RETURNED':
        return 'Trả hàng';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return s;
    }
  }
}
