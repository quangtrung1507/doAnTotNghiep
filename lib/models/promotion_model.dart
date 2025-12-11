// lib/models/promotion_model.dart
class PromotionModel {
  final int id;
  final String promotionCode;
  final String promotionName;
  final double value;
  final String? promotionTypeCode;
  final String? promotionTypeName;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool status;

  PromotionModel({
    required this.id,
    required this.promotionCode,
    required this.promotionName,
    required this.value,
    required this.status,
    this.promotionTypeCode,
    this.promotionTypeName,
    this.startDate,
    this.endDate,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      // Backend trả Timestamp -> thường là chuỗi ISO
      return DateTime.tryParse(v.toString());
    }

    return PromotionModel(
      id: json['id'] ?? 0,
      promotionCode: json['promotionCode'] ?? '',
      promotionName: json['promotionName'] ?? '',
      value: _toDouble(json['value']),
      promotionTypeCode: json['promotionTypeCode'],
      promotionTypeName: json['promotionTypeName'],
      startDate: _toDate(json['startDate']),
      endDate: _toDate(json['endDate']),
      status: json['status'] == null ? true : json['status'] as bool,
    );
  }

  /// true nếu là % (PT_01) – bạn chỉnh theo DB nếu khác
  bool get isPercent {
    final code = promotionTypeCode?.toUpperCase() ?? '';
    final name = (promotionTypeName ?? '').toLowerCase();
    return code == 'PT_01' || name.contains('%') || name.contains('percent');
  }
}
