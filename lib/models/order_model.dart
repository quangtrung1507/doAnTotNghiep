// lib/models/order_model.dart
import 'product.dart';

class OrderDetail {
  final String productCode;
  final String productName;
  final String imageUrl;
  final double price; // unit price
  final int quantity;
  final String? promotionCode;

  OrderDetail({
    required this.productCode,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.promotionCode,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    String pCode =
    (json['productCode'] ?? json['product_code'] ?? '').toString();
    String pName =
    (json['productName'] ?? json['product_name'] ?? '').toString();
    String pImg = (json['imageUrl'] ?? json['image'] ?? '').toString();
    double pPrice =
        (json['unitPrice'] as num?)?.toDouble() ??
            (json['price'] as num?)?.toDouble() ??
            (json['unit_price'] as num?)?.toDouble() ??
            0.0;

    // Nếu BE nhét cả productEntity
    if (json['productEntity'] is Map) {
      try {
        final p =
        Product.fromJson(Map<String, dynamic>.from(json['productEntity']));
        pCode = p.maSP.isNotEmpty ? p.maSP : pCode;
        pName = p.tenSP.isNotEmpty
            ? p.tenSP
            : (pName.isEmpty ? 'Sản phẩm' : pName);
        pImg = p.hinhAnh.isNotEmpty ? p.hinhAnh : pImg;
        pPrice = p.gia > 0 ? p.gia : pPrice;
      } catch (_) {}
    }

    return OrderDetail(
      productCode: pCode,
      productName: pName.isEmpty ? 'Sản phẩm không rõ' : pName,
      imageUrl: pImg,
      price: pPrice,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      promotionCode:
      (json['promotionCode'] ?? json['promotion_code'])?.toString(),
    );
  }

  OrderDetail copyWith({
    String? productCode,
    String? productName,
    String? imageUrl,
    double? price,
    int? quantity,
    String? promotionCode,
  }) {
    return OrderDetail(
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      promotionCode: promotionCode ?? this.promotionCode,
    );
  }
}

class Order {
  final String orderCode;
  final String customerCode;
  final String address;
  final String phoneNumber;
  final String paymentMethod;
  final String orderType;

  /// Chuẩn hoá status về 1 trong các giá trị:
  /// 'pending', 'confirmed', 'preparing', 'shipping',
  /// 'delivered', 'cancelled', 'returned'
  final String status;

  final String? note;
  final DateTime orderDate;
  final double totalAmount; // finalAmount nếu có

  /// Khuyến mãi tổng đơn – dạng cũ (nếu có)
  final String? promotionCode;
  final String? promotionName;

  /// 🔴 MỚI: mã VIP theo loại khách hàng (nếu BE trả về)
  final String? promotionCustomerCode;

  /// 🔴 MỚI: mã coupon nhập tay (nếu BE trả về)
  final String? couponCode;

  final List<OrderDetail> details;

  Order({
    required this.orderCode,
    required this.customerCode,
    required this.address,
    required this.phoneNumber,
    required this.paymentMethod,
    required this.orderType,
    required this.status,
    this.note,
    required this.orderDate,
    required this.totalAmount,
    this.promotionCode,
    this.promotionName,
    this.promotionCustomerCode,
    this.couponCode,
    required this.details,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final List rawDetails =
        (json['orderDetailList'] as List?) ??
            (json['details'] as List?) ??
            <dynamic>[];

    final details = rawDetails
        .whereType<Map<String, dynamic>>()
        .map(OrderDetail.fromJson)
        .toList();

    String cusCode = (json['customerCode'] ?? '').toString();
    if (json['customerEntity'] is Map) {
      cusCode =
          (json['customerEntity']['customer_code'] ?? cusCode).toString();
    }

    // =========================
    // Chuẩn hoá trạng thái đơn
    // =========================
    String normalizeStatus(String? raw) {
      var s = (raw ?? '').trim().toLowerCase().replaceAll(' ', '_');

      switch (s) {
      // chờ xác nhận
        case 'pending':
        case 'pending_confirmation':
          return 'pending';

      // đã xác nhận
        case 'confirmed':
          return 'confirmed';

      // đang chuẩn bị
        case 'pending_shipment': // kiểu cũ
        case 'preparing':
        case 'processing': // enum PROCESSING
          return 'preparing';

      // đang giao hàng
        case 'in_transit': // kiểu cũ
        case 'shipping':
          return 'shipping';

      // đã giao
        case 'delivered':
          return 'delivered';

      // đã trả hàng
        case 'returned':
          return 'returned';

      // đã hủy
        case 'cancelled':
        case 'canceled':
          return 'cancelled';

        default:
          return '';
      }
    }

    dynamic rawStatusField =
        json['orderStatus'] ?? json['order_status'] ?? json['status'];

    String orderStatus = '';

    // 1) Nếu BE trả chuỗi → chuẩn hoá trực tiếp
    if (rawStatusField is String && rawStatusField.isNotEmpty) {
      orderStatus = normalizeStatus(rawStatusField);
    }

    // 2) Nếu chưa ra được → fallback kiểu cũ bool status + isPaid
    if (orderStatus.isEmpty) {
      final bool? statusBool = rawStatusField is bool
          ? rawStatusField
          : (json['status'] is bool ? json['status'] as bool : null);
      final bool? isPaidBool =
      json['isPaid'] is bool ? json['isPaid'] as bool : null;

      if (statusBool == false) {
        orderStatus = 'cancelled';
      } else if (isPaidBool == true) {
        orderStatus = 'delivered';
      } else {
        orderStatus = 'pending';
      }
    }

    // 3) Nếu vì lý do gì đó vẫn rỗng → mặc định pending
    if (orderStatus.isEmpty) {
      orderStatus = 'pending';
    }

    final createdStr =
    (json['createdDate'] ?? json['orderDate'] ?? '').toString();
    final created =
    createdStr.isNotEmpty ? DateTime.parse(createdStr) : DateTime.now();

    final total = (json['finalAmount'] as num?)?.toDouble() ??
        (json['totalAmount'] as num?)?.toDouble() ??
        0.0;

    // 🔴 Đọc tất cả khả năng cho các field mã giảm giá
    final promoCode = (json['promotionCode'] ??
        json['promotion_code'] ??
        json['voucherCode'] ??
        json['voucher_code'])
        ?.toString();

    final promoName =
    (json['promotionName'] ?? json['promotion_name'])?.toString();

    final promoCustomerCode = (json['promotionCustomerCode'] ??
        json['promotion_customer_code'] ??
        json['customerPromotionCode'] ??
        json['customer_promotion_code'])
        ?.toString();

    final couponCode =
    (json['couponCode'] ?? json['coupon_code'])?.toString();

    return Order(
      orderCode: (json['orderCode'] ?? json['order_code'] ?? '').toString(),
      customerCode: cusCode,
      address: (json['address'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      paymentMethod: (json['paymentMethod'] ?? 'UNKNOWN').toString(),
      orderType: (json['orderType'] ?? 'UNKNOWN').toString(),
      status: orderStatus,
      note: json['note']?.toString(),
      orderDate: created,
      totalAmount: total,
      promotionCode: promoCode,
      promotionName: promoName,
      promotionCustomerCode: promoCustomerCode,
      couponCode: couponCode,
      details: details,
    );
  }

  Order copyWith({
    String? orderCode,
    String? customerCode,
    String? address,
    String? phoneNumber,
    String? paymentMethod,
    String? orderType,
    String? status,
    String? note,
    DateTime? orderDate,
    double? totalAmount,
    String? promotionCode,
    String? promotionName,
    String? promotionCustomerCode,
    String? couponCode,
    List<OrderDetail>? details,
  }) {
    return Order(
      orderCode: orderCode ?? this.orderCode,
      customerCode: customerCode ?? this.customerCode,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      note: note ?? this.note,
      orderDate: orderDate ?? this.orderDate,
      totalAmount: totalAmount ?? this.totalAmount,
      promotionCode: promotionCode ?? this.promotionCode,
      promotionName: promotionName ?? this.promotionName,
      promotionCustomerCode:
      promotionCustomerCode ?? this.promotionCustomerCode,
      couponCode: couponCode ?? this.couponCode,
      details: details ?? this.details,
    );
  }
}

/// Hành trình (nếu dùng)
class ShipmentEvent {
  final DateTime time;
  final String location;
  final String status;

  ShipmentEvent({
    required this.time,
    required this.location,
    required this.status,
  });

  factory ShipmentEvent.fromJson(Map<String, dynamic> json) {
    final timeRaw = json['time'] ?? json['timestamp'] ?? json['createdAt'];
    DateTime parsed;
    if (timeRaw is int) {
      parsed = DateTime.fromMillisecondsSinceEpoch(timeRaw);
    } else {
      parsed = DateTime.tryParse(timeRaw.toString()) ?? DateTime.now();
    }
    return ShipmentEvent(
      time: parsed,
      location:
      (json['location'] ?? json['hub'] ?? json['place'] ?? '').toString(),
      status: (json['status'] ?? json['event'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() =>
      {'time': time.toIso8601String(), 'location': location, 'status': status};
}
