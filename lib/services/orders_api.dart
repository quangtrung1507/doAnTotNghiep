// lib/services/orders_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';
import 'api_service.dart' show ApiService;

/// API tối giản cho danh sách/chi tiết đơn (list; detail optional).
/// Không đụng tới ApiService cũ của bạn. Khi trả rỗng, màn hình sẽ fallback sang mock (OrderService).
class OrdersApi {
  static Map<String, String> _headers(String? token) => {
    'Accept': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  // Các đường dẫn ứng viên để khớp backend
  static final List<String> _listPaths = <String>[
    '/orders/my',          // v1/api/orders/my?customerCode=...
    '/orders',             // v1/api/orders?customerCode=...
    '/invoices/my',        // v1/api/invoices/my?customerCode=...
    '/invoices',           // v1/api/invoices?customerCode=...
  ];

  // -------- helpers --------
  static Uri _buildUri(String path, Map<String, String> qp) {
    // Tránh "//" thừa khi baseUrl đã có trailing slash
    final base = ApiService.baseUrl.endsWith('/')
        ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1)
        : ApiService.baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: qp.isEmpty ? null : qp);
  }

  static List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      if (body['data'] is List) return body['data'] as List;
      if (body['content'] is List) return body['content'] as List; // phòng trường hợp trả kiểu page
    }
    return const <dynamic>[];
  }

  static Map<String, dynamic> _extractMap(dynamic body) {
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    return <String, dynamic>{};
  }

  /// Lấy danh sách đơn hàng theo customerCode.
  /// - status: 'ALL' / null => không lọc; còn lại gửi kèm query `status`
  static Future<List<Order>> fetchMyOrders(
      String customerCode, {
        String? status,
        String? token,
      }) async {
    http.Response? last;

    // Chuẩn hoá status (upper) để tránh lệch BE
    final st = (status ?? '').toUpperCase();
    final sendStatus = st.isNotEmpty && st != 'ALL' ? st : null;

    for (final p in _listPaths) {
      final uri = _buildUri(p, {
        'customerCode': customerCode,
        if (sendStatus != null) 'status': sendStatus,
      });

      try {
        final resp = await http
            .get(uri, headers: _headers(token))
            .timeout(const Duration(seconds: 10));
        last = resp;

        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body);
          final data = _extractList(body);
          return data
              .whereType<Map<String, dynamic>>()
              .map(Order.fromJson)
              .toList();
        }

        if (resp.statusCode == 404) {
          // thử path tiếp theo
          continue;
        }

        if (resp.statusCode == 401 || resp.statusCode == 403) {
          // lỗi quyền → ném ra để màn hình hiển thị lỗi
          throw Exception('Không thể tải đơn hàng (HTTP ${resp.statusCode})');
        }

        // Các lỗi HTTP khác → ném ra (màn hình sẽ fallback mock trong catch của nó)
        throw Exception('Không thể tải đơn hàng (HTTP ${resp.statusCode})');
      } catch (_) {
        // timeout / json parse / network → thử path kế
        continue;
      }
    }

    // Không path nào dùng được: trả rỗng để màn dùng mock
    if (last == null) {
      // không connect được server: vẫn trả [] để màn hình fallback sang mock
      return <Order>[];
    }
    return <Order>[];
  }

  /// (Tuỳ chọn) Lấy chi tiết đơn theo mã – nếu bạn muốn dùng API thật thay vì mock.
  static Future<Order?> fetchOrderByCode(String orderCode, {String? token}) async {
    final candidates = <String>[
      '/orders/$orderCode',
      '/invoices/$orderCode',
    ];
    http.Response? last;

    for (final p in candidates) {
      final uri = _buildUri(p, const {});
      try {
        final resp = await http
            .get(uri, headers: _headers(token))
            .timeout(const Duration(seconds: 10));
        last = resp;

        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body);
          final data = _extractMap(body);
          return Order.fromJson(data);
        }
        if (resp.statusCode == 404) continue;
        if (resp.statusCode == 401 || resp.statusCode == 403) {
          throw Exception('Không thể tải chi tiết đơn (HTTP ${resp.statusCode})');
        }
        throw Exception('Không thể tải chi tiết đơn (HTTP ${resp.statusCode})');
      } catch (_) {
        continue;
      }
    }

    // Không path nào match → null (để UI hiển thị “không có dữ liệu”)
    if (last == null) return null;
    return null;
  }
}
