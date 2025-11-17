// lib/screens/order_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // 🔴 THÊM IMPORT ĐỂ FORMAT NGÀY
import '../providers/auth_provider.dart';
import '../services/api_service.dart'; // 🔴 SỬA: Gọi API Service trực tiếp
import '../models/order_model.dart';   // 🔴 SỬA: Dùng Model mới
import '../utils/app_colors.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // 🔴 SỬA: Dùng FutureBuilder để quản lý state
  late Future<List<Order>> _futureOrders;

  @override
  void initState() {
    super.initState();
    // Gọi hàm tải đơn hàng ngay khi mở
    _futureOrders = _fetchOrders();
  }

  // 🔴 SỬA: Hàm này giờ sẽ trả về Future<List<Order>>
  Future<List<Order>> _fetchOrders() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.customerCode != null) {
        // Gọi thẳng API Service
        print("Đang tải đơn hàng cho: ${authProvider.customerCode}");
        final orders = await ApiService.fetchMyOrders(authProvider.customerCode!);
        print("Tải thành công ${orders.length} đơn hàng.");
        return orders;
      } else {
        throw Exception('Vui lòng đăng nhập để xem đơn hàng.');
      }
    } catch (e) {
      // Ném lỗi ra để FutureBuilder bắt
      print("Lỗi _fetchOrders: $e");
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Hàm refresh (gọi lại API)
  Future<void> _onRefresh() async {
    setState(() {
      _futureOrders = _fetchOrders();
    });
    await _futureOrders; // Chờ cho đến khi tải xong
  }

  // (Các hàm helper định dạng)
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.orange;
      case 'DELIVERED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return 'Chờ xác nhận';
      case 'DELIVERED': return 'Đã giao';
      case 'CANCELLED': return 'Đã hủy';
      default: return 'Không rõ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đơn Hàng Của Tôi'),
        backgroundColor: AppColors.card,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh, // Gọi hàm refresh
          ),
        ],
      ),
      // 🔴 SỬA: Dùng FutureBuilder để hiển thị
      body: FutureBuilder<List<Order>>(
        future: _futureOrders,
        builder: (context, snapshot) {
          // Khi đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Khi có lỗi
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lỗi: ${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _onRefresh,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Khi thành công
          final myOrders = snapshot.data ?? [];
          if (myOrders.isEmpty) {
            return const Center(child: Text('Bạn chưa có đơn hàng nào.'));
          }

          // Hiển thị ListView
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: myOrders.length,
              itemBuilder: (context, index) {
                final order = myOrders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      // TODO: Mở trang Chi tiết đơn hàng (nếu có)
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mã Đơn: ${order.orderCode}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(order.status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getStatusText(order.status), // Hiển thị chữ Việt
                                  style: TextStyle(
                                    color: _getStatusColor(order.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Ngày đặt: ${_formatDateTime(order.orderDate)}'),
                          Text('Tổng tiền: ${order.totalAmount.toStringAsFixed(0)}đ'),
                          Text('Địa chỉ: ${order.address}'),
                          Text('SĐT: ${order.phoneNumber}'),
                          const Divider(height: 20),

                          // Hiển thị TẤT CẢ sản phẩm trong đơn hàng
                          ...order.details.map((detail) => _buildOrderDetailItem(detail)).toList(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Widget helper để hiển thị chi tiết sản phẩm
  Widget _buildOrderDetailItem(OrderDetail detail) {
    final String imageUrl = (detail.imageUrl.isNotEmpty &&
        (detail.imageUrl.startsWith('http') ||
            detail.imageUrl.startsWith('httpsF')))
        ? detail.imageUrl
        : 'http://10.0.2.2:8080${detail.imageUrl}'; // Giả sử ảnh cần host

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Image.network(
            imageUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${detail.productName} (SL: ${detail.quantity})',
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${(detail.price * detail.quantity).toStringAsFixed(0)}đ',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }
}