// lib/screens/order_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../services/orders_api.dart';      // lấy LIST từ OrdersApi (real)
import '../services/order_service.dart';   // fallback mock nếu rỗng/lỗi
import '../models/order_model.dart';
import '../utils/app_colors.dart';
import 'order_detail_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late Future<List<Order>> _futureOrders;

  // Bộ lọc trạng thái (client)
  static const _statusFilters = <String, String>{
    'ALL': 'Tất cả',
    'UNPAID': 'Chưa thanh toán',
    'PENDING_SHIPMENT': 'Chờ vận chuyển',
    'IN_TRANSIT': 'Đã vận chuyển',
    'DELIVERED': 'Đã giao',
    'NEED_REVIEW': 'Cần đánh giá',
    'RETURNED': 'Trả hàng',
    'CANCELLED': 'Đã hủy',
    'PENDING': 'Chờ xác nhận',
  };
  String _selectedStatus = 'ALL';

  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _futureOrders = _fetchOrders();
  }

  Future<List<Order>> _fetchOrders() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final code = auth.customerCode;
      final token = auth.authToken;

      if (code == null || code.isEmpty) {
        throw Exception('Vui lòng đăng nhập để xem đơn hàng.');
      }

      debugPrint('[OrderTracking] fetch for $code, status=$_selectedStatus');

      // 1) gọi real
      final real = await OrdersApi.fetchMyOrders(
        code,
        status: _selectedStatus,
        token: token,
      );
      debugPrint('[OrderTracking] real=${real.length}');

      // 2) nếu real có → dùng real
      if (real.isNotEmpty) return real;

      // 3) nếu real rỗng → fallback mock (demo)
      final mock = await OrderService.fetchOrders(
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
        customerCode: code,
      );
      debugPrint('[OrderTracking] mock=${mock.length}');
      return mock;
    } catch (e) {
      debugPrint('[OrderTracking] error: $e, fallback mock');
      final auth = Provider.of<AuthProvider>(context, listen: false);
      return OrderService.fetchOrders(
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
        customerCode: auth.customerCode,
      );
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _futureOrders = _fetchOrders();
    });
    await _futureOrders;
  }

  String _formatDateTime(DateTime dt) =>
      DateFormat('dd/MM/yyyy HH:mm').format(dt);

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'UNPAID':
        return Colors.deepOrange;
      case 'PENDING':
      case 'PENDING_SHIPMENT':
        return Colors.orange;
      case 'IN_TRANSIT':
        return Colors.blue;
      case 'DELIVERED':
        return Colors.green;
      case 'NEED_REVIEW':
        return Colors.teal;
      case 'RETURNED':
        return Colors.purple;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
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
        return 'Không rõ';
    }
  }

  List<Order> _applyFilter(List<Order> list) {
    if (_selectedStatus == 'ALL') return list;
    return list.where((o) => o.status.toUpperCase() == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đơn Hàng Của Tôi'),
        backgroundColor: AppColors.card,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _onRefresh),
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: _futureOrders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('[OrderTracking] waiting...');
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('[OrderTracking] error screen: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lỗi: ${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _onRefresh, child: const Text('Thử lại')),
                  ],
                ),
              ),
            );
          }

          final all = snapshot.data ?? [];
          final filtered = _applyFilter(all);

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: Column(
              children: [
                // dải chip lọc trạng thái
                SizedBox(
                  height: 52,
                  child: ListView(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    scrollDirection: Axis.horizontal,
                    children: _statusFilters.entries.map((e) {
                      final selected = _selectedStatus == e.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(e.value),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedStatus = e.key;
                              _futureOrders = _fetchOrders();
                            });
                          },
                          selectedColor:
                          AppColors.primary.withOpacity(0.15),
                          labelStyle: TextStyle(
                            color: selected
                                ? AppColors.primary
                                : Colors.black87,
                            fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: (filtered.isEmpty)
                      ? const Center(child: Text('Chưa có đơn hàng.'))
                      : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final order = filtered[i];
                      return Card(
                        margin:
                        const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(
                                    orderCode: order.orderCode),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Mã Đơn: ${order.orderCode}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                            order.status)
                                            .withOpacity(0.15),
                                        borderRadius:
                                        BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _getStatusText(order.status),
                                        style: TextStyle(
                                          color: _getStatusColor(
                                              order.status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    'Ngày đặt: ${_formatDateTime(order.orderDate)}'),
                                Text(
                                    'Tổng tiền: ${_currency.format(order.totalAmount)}'),
                                Text('Địa chỉ: ${order.address}'),
                                Text('SĐT: ${order.phoneNumber}'),
                                const Divider(height: 20),

                                // hiển thị từng dòng sản phẩm
                                ...order.details
                                    .map(_buildOrderDetailItem)
                                    .toList(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderDetailItem(OrderDetail d) {
    final imageUrl = d.imageUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              imageUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${d.productName} (SL: ${d.quantity})',
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            _currency.format(d.price * d.quantity),
            style:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
