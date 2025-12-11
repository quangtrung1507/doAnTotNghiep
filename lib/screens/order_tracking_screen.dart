import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../providers/auth_provider.dart';
import 'order_detail_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  bool _loading = true;
  String? _error;
  List<Order> _allOrders = [];

  // tab filter: ALL, hoặc 1 trong các trạng thái: pending, confirmed, preparing, shipping, delivered, cancelled, returned
  String _tab = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 👉 Lấy customerCode từ AuthProvider
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final customerCode = auth.customerCode;

      if (customerCode == null || customerCode.isEmpty) {
        setState(() {
          _loading = false;
          _error =
          'Không xác định được khách hàng.\nVui lòng đăng nhập lại.';
          _allOrders = [];
        });
        return;
      }

      // 👉 Gọi getAll từ backend
      final list = await ApiService.fetchAllOrders();

      // 👉 Lọc lại theo customerCode hiện tại
      final myOrders =
      list.where((o) => o.customerCode == customerCode).toList();

      if (!mounted) return;
      setState(() {
        _allOrders = myOrders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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

  String _vnStatus(String s) {
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

  Color _statusColor(String s) {
    final v = s.toLowerCase().replaceAll(' ', '_');
    switch (v) {
      case 'pending':
      case 'pending_confirmation':
      case 'unpaid':
        return Colors.blue;

      case 'confirmed':
        return Colors.indigo;

      case 'preparing':
      case 'processing':
      case 'pending_shipment':
        return Colors.deepPurple;

      case 'shipping':
      case 'in_transit':
        return Colors.teal;

      case 'delivered':
        return Colors.green;

      case 'returned':
        return Colors.orange;

      case 'cancelled':
      case 'canceled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  /// Có được hủy đơn không?
  /// ✅ Chỉ cho hủy khi đơn còn ở trạng thái CHỜ XÁC NHẬN
  bool _canCancelOrder(Order o) {
    final st = o.status.toLowerCase().replaceAll(' ', '_');
    return st == 'pending' ||
        st == 'pending_confirmation' ||
        st == 'unpaid';
  }

  List<Order> get _filteredOrders {
    if (_tab == 'ALL') return _allOrders;
    final key = _tab.toLowerCase();

    return _allOrders.where((o) {
      final st = o.status.toLowerCase().replaceAll(' ', '_');

      if (key == 'pending') {
        return st == 'pending' ||
            st == 'pending_confirmation' ||
            st == 'unpaid';
      }

      if (key == 'preparing') {
        return st == 'preparing' ||
            st == 'processing' ||
            st == 'pending_shipment';
      }

      if (key == 'shipping') {
        return st == 'shipping' || st == 'in_transit';
      }

      // các tab khác match chính xác
      return st == key;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn Hàng Của Tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusTabs(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null)
                ? Center(
              child: Text(
                _error!.replaceAll('Exception: ', ''),
                textAlign: TextAlign.center,
              ),
            )
                : (orders.isEmpty)
                ? const Center(child: Text('Chưa có đơn hàng nào'))
                : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: orders.length,
                itemBuilder: (ctx, i) {
                  final o = orders[i];
                  return _buildOrderCard(o);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statusChip('Tất cả', 'ALL'),
            const SizedBox(width: 8),
            _statusChip('Chờ xác nhận', 'pending'),
            const SizedBox(width: 8),
            _statusChip('Đã xác nhận', 'confirmed'),
            // ❌ BỎ tab "Đang chuẩn bị"
            const SizedBox(width: 8),
            _statusChip('Đang giao hàng', 'shipping'),
            const SizedBox(width: 8),
            _statusChip('Đã giao hàng', 'delivered'),
            const SizedBox(width: 8),
            _statusChip('Đã hủy', 'cancelled'),
            const SizedBox(width: 8),
            _statusChip('Đã trả hàng', 'returned'),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, String value) {
    final selected = _tab == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary.withOpacity(0.15),
      onSelected: (_) {
        setState(() => _tab = value);
      },
    );
  }

  Future<void> _onCancelOrder(Order o) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Text(
            'Bạn có chắc chắn muốn hủy đơn ${o.orderCode} không?\n\n'
                'Lưu ý: Không thể hủy nếu đơn đã/đang giao.'),
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

    try {
      await ApiService.cancelOrder(o.orderCode);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy đơn hàng')),
      );

      // reload list
      await _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Widget _buildOrderCard(Order o) {
    final detailLines = o.details;

    // 🔹 Tìm mã voucher đã dùng (nếu có)
    String? usedPromoCode = o.promotionCode;
    if ((usedPromoCode == null || usedPromoCode.isEmpty) &&
        detailLines.isNotEmpty) {
      try {
        final withPromo = detailLines.firstWhere(
              (d) => (d.promotionCode ?? '').isNotEmpty,
        );
        usedPromoCode = withPromo.promotionCode;
      } catch (_) {
        // không có promotionCode ở detail nào
      }
    }

    // 🔹 Hiển thị loại thanh toán (map sang tiếng Việt)
    String paymentLabel;
    switch (o.paymentMethod) {
      case 'Cash':
        paymentLabel = 'Thanh toán khi nhận hàng (COD)';
        break;
      case 'QR':
        paymentLabel = 'Chuyển khoản QR';
        break;
      default:
        paymentLabel = o.paymentMethod; // fallback nếu BE trả dạng khác
        break;
    }

    // ✅ Dùng hàm _canCancelOrder ở trên
    final canCancel = _canCancelOrder(o);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: mã đơn + status
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mã Đơn: ${o.orderCode}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(o.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _vnStatus(o.status),
                    style: TextStyle(
                      color: _statusColor(o.status),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(o.orderDate)}',
            ),
            Text('Tổng tiền: ${_currency.format(o.totalAmount)}'),
            Text('Địa chỉ: ${o.address}'),
            Text('SDT: ${o.phoneNumber}'),
            if (usedPromoCode != null && usedPromoCode.isNotEmpty)
              Text('Voucher: $usedPromoCode'),
            Text('Thanh toán: $paymentLabel'),
            const SizedBox(height: 8),
            const Divider(),

            // Danh sách sản phẩm trong đơn
            Column(
              children: detailLines.map(_buildOrderDetailItem).toList(),
            ),

            const SizedBox(height: 8),

            // 🔹 Hàng nút hành động: Xem chi tiết + Hủy đơn (nếu được phép)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderDetailScreen(orderCode: o.orderCode),
                      ),
                    );
                    // sau khi quay lại, load lại để cập nhật status
                    await _loadOrders();
                  },
                  child: const Text('Xem chi tiết'),
                ),
                if (canCancel) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () => _onCancelOrder(o),
                    child: const Text('Hủy đơn'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailItem(OrderDetail d) {
    final img = _normalizeImg(d.imageUrl);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (img.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                img,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, size: 18),
                ),
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.image, size: 18),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${d.productName} (SL: ${d.quantity})',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _currency.format(d.price * d.quantity),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
