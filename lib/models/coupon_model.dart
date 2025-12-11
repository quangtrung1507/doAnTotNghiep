// lib/models/coupon_model.dart
class CouponModel {
  final int id;
  final String couponCode;
  final String couponName;
  final String description;
  final double value;
  final String? promotionTypeCode;
  final String? promotionTypeName;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool status;

  CouponModel({
    required this.id,
    required this.couponCode,
    required this.couponName,
    required this.description,
    required this.value,
    required this.status,
    this.promotionTypeCode,
    this.promotionTypeName,
    this.startDate,
    this.endDate,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return CouponModel(
      id: json['id'] ?? 0,
      couponCode: json['couponCode'] ?? '',
      couponName: json['couponName'] ?? '',
      description: json['description'] ?? '',
      value: _toDouble(json['value']),
      startDate: _toDate(json['startDate']),
      endDate: _toDate(json['endDate']),
      status: json['status'] == null ? true : json['status'] as bool,
      promotionTypeCode: json['promotionTypeCode'],
      promotionTypeName: json['promotionTypeName'],
    );
  }

  /// true nếu là giảm tiền mặt
  bool get isMoneyOff {
    final name = (promotionTypeName ?? '').toLowerCase();
    return name.contains('cash') ||
        name.contains('money') ||
        name.contains('amount');
  }
}
