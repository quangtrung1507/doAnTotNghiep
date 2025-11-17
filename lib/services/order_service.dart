// lib/services/order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';   // <-- Dùng ShipmentEvent từ đây
import 'api_service.dart' show ApiService;

class OrderService {
  /// Demo không có API chi tiết/track → bật mock
  static bool useMock = true;

  // ===== Endpoint thật (bật useMock=false để dùng) =====
  static Uri ordersUrl({String? status, String? customerCode}) {
    final base = '${ApiService.baseUrl}/orders';
    final q = <String, String>{};
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (customerCode != null && customerCode.isNotEmpty) q['customerCode'] = customerCode;
    return Uri.parse(base).replace(queryParameters: q.isEmpty ? null : q);
  }

  static Uri orderDetailUrl(String orderCode) =>
      Uri.parse('${ApiService.baseUrl}/orders/$orderCode');

  static Uri trackingUrl(String orderCode) =>
      Uri.parse('${ApiService.baseUrl}/orders/$orderCode/tracking');

  // ===== LIST ORDERS (fallback/mock nếu OrdersApi trả rỗng/lỗi) =====
  static Future<List<Order>> fetchOrders({
    String? token,
    String? customerCode,
    String? status,
  }) async {
    if (useMock) return _mockOrders(status: status, customerCode: customerCode);

    final url = ordersUrl(status: status, customerCode: customerCode);
    final headers = {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await http.get(url, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Lấy danh sách đơn hàng thất bại (HTTP ${resp.statusCode})');
    }
    final body = jsonDecode(resp.body);
    final List data = (body is Map && body['data'] is List) ? body['data'] : <dynamic>[];
    return data.whereType<Map<String, dynamic>>().map(Order.fromJson).toList();
  }

  // ===== ORDER DETAIL =====
  static Future<Order> fetchOrderDetail({
    required String orderCode,
    String? token,
  }) async {
    if (useMock) return _mockOrderDetail(orderCode);

    final url = orderDetailUrl(orderCode);
    final headers = {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final resp = await http.get(url, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Lấy chi tiết đơn hàng thất bại (HTTP ${resp.statusCode})');
    }
    final body = jsonDecode(resp.body);
    final Map data = (body is Map && body['data'] is Map) ? body['data'] : <String, dynamic>{};
    return Order.fromJson(Map<String, dynamic>.from(data));
  }

  // ===== SHIPMENT TRACKING =====
  static Future<List<ShipmentEvent>> fetchTracking({
    required String orderCode,
    String? token,
  }) async {
    if (useMock) {
      final carrier = 'GHN';
      final tracking = 'DEMO_$orderCode';
      return _mockTrackingByCarrier(carrier, tracking);
    }

    final url = trackingUrl(orderCode);
    final headers = {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final resp = await http.get(url, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Lấy hành trình vận chuyển thất bại (HTTP ${resp.statusCode})');
    }
    final body = jsonDecode(resp.body);
    final List data = (body is Map && body['data'] is List) ? body['data'] : <dynamic>[];
    return data.whereType<Map<String, dynamic>>().map(ShipmentEvent.fromJson).toList();
  }

  // ===================== MOCK DATA =====================

  static List<Order> _mockOrders({String? status, String? customerCode}) {
    OrderDetail d(String code, String name, int qty, double price, {String img = ''}) =>
        OrderDetail(productCode: code, productName: name, imageUrl: img, price: price, quantity: qty);

    final all = <Order>[
      Order(
        orderCode: 'ORD_0001',
        customerCode: customerCode ?? 'CUS_DEMO',
        address: '12A Nguyễn Văn Cừ, P.1, Q.5, TP.HCM',
        phoneNumber: '0900000001',
        paymentMethod: 'Cash',
        orderType: 'NORMAL',
        status: 'PENDING_SHIPMENT',
        note: null,
        orderDate: DateTime.now().subtract(const Duration(days: 1)),
        totalAmount: 230000, // 250k - 50k + 30k
        details: [
          d('SP0101', 'Romance Book 1', 1, 150000),
          d('SP0102', 'Romance Book 2', 1, 100000),
        ],
      ),
      Order(
        orderCode: 'ORD_0002',
        customerCode: customerCode ?? 'CUS_DEMO',
        address: '90 Trần Hưng Đạo, Mỹ Tho, Tiền Giang',
        phoneNumber: '0900000002',
        paymentMethod: 'Cash',
        orderType: 'NORMAL',
        status: 'UNPAID',
        note: null,
        orderDate: DateTime.now().subtract(const Duration(days: 2)),
        totalAmount: 150000,
        details: [
          d('SP0201', 'Manga Vol.1', 2, 60000),
        ],
      ),
      Order(
        orderCode: 'ORD_0003',
        customerCode: customerCode ?? 'CUS_DEMO',
        address: 'P.5, Mỹ Tho, Tiền Giang',
        phoneNumber: '0900000003',
        paymentMethod: 'Cash',
        orderType: 'NORMAL',
        status: 'IN_TRANSIT',
        note: null,
        orderDate: DateTime.now().subtract(const Duration(days: 5)),
        totalAmount: 330000,
        details: [
          d('SP1001', 'VPP Combo', 3, 100000),
        ],
      ),
      Order(
        orderCode: 'ORD_0004',
        customerCode: customerCode ?? 'CUS_DEMO',
        address: 'Quận 5, TP.HCM',
        phoneNumber: '0900000004',
        paymentMethod: 'Cash',
        orderType: 'NORMAL',
        status: 'DELIVERED',
        note: null,
        orderDate: DateTime.now().subtract(const Duration(days: 8)),
        totalAmount: 210000,
        details: [
          d('SP0501', 'Notebook A5', 2, 90000),
        ],
      ),
      Order(
        orderCode: 'ORD_0005',
        customerCode: customerCode ?? 'CUS_DEMO',
        address: 'Hà Nội',
        phoneNumber: '0900000005',
        paymentMethod: 'Cash',
        orderType: 'NORMAL',
        status: 'RETURNED',
        note: 'Sách lỗi in',
        orderDate: DateTime.now().subtract(const Duration(days: 10)),
        totalAmount: 250000,
        details: [
          d('SP0701', 'Horror Book', 1, 220000),
        ],
      ),
    ];

    if (status == null || status.isEmpty || status == 'ALL') return all;
    return all.where((o) => o.status.toUpperCase() == status.toUpperCase()).toList();
  }

  static Order _mockOrderDetail(String orderCode) {
    final all = _mockOrders();
    return all.firstWhere((e) => e.orderCode == orderCode, orElse: () => all.first);
  }

  static List<ShipmentEvent> _mockTrackingByCarrier(String _carrier, String code) {
    final now = DateTime.now();
    return [
      ShipmentEvent(time: now.subtract(const Duration(days: 2, hours: 6)), location: 'Kho TG', status: 'Tạo vận đơn ($code)'),
      ShipmentEvent(time: now.subtract(const Duration(days: 2)), location: 'Kho TG', status: 'Đã nhập kho'),
      ShipmentEvent(time: now.subtract(const Duration(days: 1, hours: 12)), location: 'TT phân loại HCM', status: 'Đang trung chuyển'),
      ShipmentEvent(time: now.subtract(const Duration(hours: 6)), location: 'Kho Q5', status: 'Xuất giao'),
    ];
  }
}
