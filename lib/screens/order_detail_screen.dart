// lib/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';
import '../models/product.dart';
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

  /// Cache future sản phẩm theo productCode để không gọi API trùng
  final Map<String, Future<Product?>> _productFutures = {};

  /// Đang gọi API huỷ không
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchOrderDetails(widget.orderCode);
  }

  Future<Product?> _getProduct(String code) {
    if (code.isEmpty) return Future.value(null);
    return _productFutures.putIfAbsent(code, () async {
      try {
        return await ApiService.fetchProductByCode(code);
      } catch (_) {
        return null;
      }
    });
  }

  String _normalizeImg(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;

    // ApiService.baseUrl = http://host:port/v1/api
    final api = ApiService.baseUrl;
    final cutIndex = api.indexOf('/v1/api');
    final root = cutIndex == -1 ? api : api.substring(0, cutIndex);
    final u = '$root$url'; // -> http://host:port/uploads/...

    return u.replaceAll('//', '/').replaceFirst(':/', '://');
  }

  /// Chỉ cho phép huỷ khi đơn CHƯA vận chuyển / giao / huỷ / trả
  bool _canCancelOrder(Order o) {
    final v = o.status.toLowerCase().replaceAll(' ', '_');
    switch (v) {
      case 'shipping':
      case 'in_transit':
      case 'delivered':
      case 'returned':
      case 'cancelled':
      case 'canceled':
        return false;
      default:
        return true;
    }
  }

  Future<void> _onCancelOrderPressed(Order o) async {
    if (_cancelling) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc muốn hủy đơn hàng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _cancelling = true);

    try {
      await ApiService.cancelOrder(widget.orderCode);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy đơn hàng thành công')),
      );

      // Trả về true cho màn trước biết để reload list
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hủy đơn thất bại: ${e.toString().replaceAll('Exception: ', '')}',
          ),
        ),
      );
    }
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
            return Center(
              child: Text('Lỗi: ${snap.error ?? "Không có dữ liệu"}'),
            );
          }
          final o = snap.data!;

          // Tạm tính = tổng tiền hàng từ chi tiết (dùng giá BE trả về)
          final subtotal = o.details.fold<double>(
            0.0,
                (s, d) => s + d.price * d.quantity,
          );

          // Tổng thanh toán: dùng totalAmount từ server
          final double total = o.totalAmount;

          // Giảm giá = chênh lệch giữa tạm tính và tổng thanh toán
          final double discount =
          (subtotal - total).clamp(0, double.infinity).toDouble();

          // ✅ Chuẩn bị text hiển thị mã giảm giá đã dùng (VIP + coupon + fallback)
          final voucherSummary = _buildVoucherSummary(o);
          final hasVoucher = voucherSummary.isNotEmpty;

          return Column(
            children: [
              // Nội dung chi tiết đơn
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _statusCard(o),
                    const SizedBox(height: 12),
                    _addressCard(o),
                    const SizedBox(height: 12),
                    if (hasVoucher) ...[
                      _promoCard(summary: voucherSummary),
                      const SizedBox(height: 12),
                    ],
                    _itemsCard(o),
                    const SizedBox(height: 12),
                    _totalCard(
                      subtotal: subtotal,
                      discount: discount,
                      total: total,
                      voucherSummary: voucherSummary,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Nút HỦY ĐƠN (nếu còn được huỷ)
              if (_canCancelOrder(o))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                      _cancelling ? null : () => _onCancelOrderPressed(o),
                      child: Text(
                        _cancelling ? 'Đang hủy...' : 'Hủy đơn hàng',
                      ),
                    ),
                  ),
                ),
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
        title: Text(
          _vnStatus(o.status),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Tạo lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(o.orderDate)}',
        ),
      ),
    );
  }

  Widget _addressCard(Order o) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.location_on_outlined),
        title: const Text(
          'Địa chỉ nhận hàng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${o.address}\nSĐT: ${o.phoneNumber}'),
      ),
    );
  }

  /// Card hiển thị mã giảm giá đã dùng (gộp VIP + coupon)
  Widget _promoCard({required String summary}) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.card_giftcard),
        title: const Text(
          'Mã giảm giá đã dùng',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(summary),
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
            const Text(
              'Sản phẩm',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...o.details.map((d) {
              return FutureBuilder<Product?>(
                future: _getProduct(d.productCode),
                builder: (ctx, snap) {
                  String name = d.productName;
                  String imgUrl = d.imageUrl;
                  double price = d.price;

                  final product = snap.data;
                  if (product != null) {
                    if (name.isEmpty) name = product.tenSP;
                    if (imgUrl.isEmpty) imgUrl = product.hinhAnh;
                    if (price <= 0) price = product.gia;
                  }

                  final img =
                  imgUrl.isNotEmpty ? _normalizeImg(imgUrl) : '';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: (img.isNotEmpty)
                        ? Image.network(
                      img,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 52,
                        height: 52,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image),
                      ),
                    )
                        : Container(
                      width: 52,
                      height: 52,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image),
                    ),
                    title: Text(name),
                    subtitle: Text(
                      'SL: ${d.quantity} • Đơn giá: ${_currency.format(price)}',
                    ),
                    trailing: Text(
                      _currency.format(price * d.quantity),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Có thêm dòng Mã giảm giá (nếu có)
  Widget _totalCard({
    required double subtotal,
    required double discount,
    required double total,
    String? voucherSummary,
  }) {
    final hasVoucher = (voucherSummary ?? '').isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _row('Tạm tính', _currency.format(subtotal)),
            if (hasVoucher)
              _row(
                'Mã giảm giá',
                voucherSummary!,
              ),
            _row(
              'Giảm giá',
              '- ${_currency.format(discount)}',
              valueColor: Colors.red,
            ),
            const Divider(),
            _row(
              'Tổng thanh toán',
              _currency.format(total),
              isBold: true,
              valueColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
      String k,
      String v, {
        bool isBold = false,
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k),
          Text(
            v,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Ghép text hiển thị mã giảm giá:
  /// - VIP: promotionCustomerCode
  /// - Coupon: couponCode
  /// - Fallback: promotionCode + promotionName (kiểu cũ) + mã ở chi tiết
  String _buildVoucherSummary(Order o) {
    final parts = <String>[];

    // 1) VIP / hạng khách hàng
    if (o.promotionCustomerCode != null &&
        o.promotionCustomerCode!.trim().isNotEmpty) {
      parts.add('VIP: ${o.promotionCustomerCode}');
    }

    // 2) Coupon
    if (o.couponCode != null && o.couponCode!.trim().isNotEmpty) {
      parts.add('Coupon: ${o.couponCode}');
    }

    // 3) Nếu đơn cũ chỉ có promotionCode/promotionName ở header
    final headerCode = (o.promotionCode ?? '').trim();
    final headerName = (o.promotionName ?? '').trim();
    if (headerCode.isNotEmpty || headerName.isNotEmpty) {
      final headerText = (headerCode.isNotEmpty && headerName.isNotEmpty)
          ? '$headerCode • $headerName'
          : (headerCode.isNotEmpty ? headerCode : headerName);
      if (headerText.isNotEmpty) {
        parts.add(headerText);
      }
    }

    // 4) Nếu chi tiết có promotionCode riêng
    final detailCodes = o.details
        .map((d) => d.promotionCode)
        .where((c) => c != null && c!.trim().isNotEmpty)
        .map((c) => c!.trim())
        .toSet();

    for (final c in detailCodes) {
      if (!parts.contains(c) && !parts.any((p) => p.contains(c))) {
        parts.add(c);
      }
    }

    return parts.join(' • ');
  }

  String _vnStatus(String s) {
    // Cho phép nhiều kiểu status khác nhau giống bên OrderTrackingScreen
    final v = s.toLowerCase().replaceAll(' ', '_');
    switch (v) {
      case 'pending':
      case 'pending_confirmation':
      case 'unpaid':
        return 'Chờ xác nhận';

      case 'confirmed':
        return 'Đã xác nhận';

      case 'preparing':
      case 'processing':
      case 'pending_shipment':
        return 'Đang chuẩn bị';

      case 'shipping':
      case 'in_transit':
        return 'Đang giao hàng';

      case 'delivered':
        return 'Đã giao hàng';

      case 'returned':
        return 'Đã trả hàng';

      case 'cancelled':
      case 'canceled':
        return 'Đã hủy';

      default:
        return s;
    }
  }
}
