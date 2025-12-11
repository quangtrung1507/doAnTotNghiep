// lib/services/promotion_service.dart
import 'dart:convert';
import 'package:bookstore/models/promotion_model.dart';
import 'package:http/http.dart' as http;

import '../models/promotion_model.dart';
import 'api_service.dart' show ApiService;

class PromotionService {
  // -> http://<host>:8080/v1/api/promotions
  static Uri _url() => Uri.parse('${ApiService.baseUrl}/promotions');

  static Future<List<PromotionModel>> fetchActivePromotions({String? token}) async {
    final url = _url();
    final headers = <String, String>{
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    // Log để debug host/path thực tế
    print('[PromotionService] GET $url');

    final resp = await http.get(url, headers: headers);
    print('[PromotionService] status=${resp.statusCode}');

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      print('[PromotionService] body=${resp.body}');
      throw Exception('Không tải được voucher (HTTP ${resp.statusCode})');
    }

    final body = jsonDecode(resp.body);
    final List data =
    (body is Map && body['data'] is List) ? body['data'] as List : const [];

    final promos = data
        .whereType<Map<String, dynamic>>()
        .map((e) => PromotionModel.fromJson(e))
        .toList();

    // Nếu có trường status boolean thì lọc true; nếu không có thì giữ nguyên
    final haveBool =
        promos.any((x) => x.status == true) || promos.any((x) => x.status == false);
    return haveBool ? promos.where((x) => x.status == true).toList() : promos;
  }
}
