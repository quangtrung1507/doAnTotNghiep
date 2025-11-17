// lib/models/promotion.dart

class Promotion {
  final int id;
  final String promotionCode;
  final String promotionName;
  final double value; // 0.05 hoặc 200000
  final String promotionTypeCode; // PT_01 / PT_02 ...
  final String promotionTypeName;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool status; // true: active

  Promotion({
    required this.id,
    required this.promotionCode,
    required this.promotionName,
    required this.value,
    required this.promotionTypeCode,
    required this.promotionTypeName,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  static String _str(dynamic v) => (v ?? '').toString();
  static double _numToDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime? _date(dynamic v) {
    if (v == null || v.toString().isEmpty) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  static bool _toBoolFlexible(Map<String, dynamic> json) {
    dynamic b = json['status'] ?? json['isActive'] ?? json['active'] ?? json['enabled'];
    if (b == null) return true; // không có trường => mặc định true để không lọc nhầm
    if (b is bool) return b;
    final s = b.toString().toLowerCase().trim();
    return s == 'true' || s == '1' || s == 'active' || s == 'enabled';
  }

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: int.tryParse(_str(json['id'] ?? json['promotionId'])) ?? 0,
      promotionCode: _str(json['promotionCode'] ?? json['promotion_code']),
      promotionName: _str(json['promotionName'] ?? json['promotion_name'] ?? json['name']),
      value: _numToDouble(json['value'] ?? json['amount'] ?? json['discountValue']),
      promotionTypeCode: _str(json['promotionTypeCode'] ?? json['promotion_type_code'] ?? json['typeCode']),
      promotionTypeName: _str(json['promotionTypeName'] ?? json['promotion_type_name'] ?? json['typeName']),
      startDate: _date(json['startDate'] ?? json['start_date']),
      endDate: _date(json['endDate'] ?? json['end_date']),
      status: _toBoolFlexible(json),
    );
  }

  bool get isPercent =>
      promotionTypeCode.toUpperCase() == 'PT_01' ||
          promotionTypeName.toLowerCase().contains('percent') ||
          promotionTypeName.toLowerCase().contains('%');

  bool get isAmount =>
      promotionTypeCode.toUpperCase() == 'PT_02' ||
          promotionTypeName.toLowerCase().contains('amount') ||
          promotionTypeName.toLowerCase().contains('tiền');
}
