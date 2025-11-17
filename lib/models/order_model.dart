// lib/models/order_model.dart
import 'product.dart';

class OrderDetail {
  final String productCode;
  final String productName;
  final String imageUrl;
  final double price;      // unit price
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
    String pCode  = (json['productCode'] ?? json['product_code'] ?? '').toString();
    String pName  = (json['productName'] ?? json['product_name'] ?? '').toString();
    String pImg   = (json['imageUrl'] ?? json['image'] ?? '').toString();
    double pPrice = (json['unitPrice'] as num?)
        ?.toDouble() ??
        (json['price'] as num?)
            ?.toDouble() ??
        (json['unit_price'] as num?)
            ?.toDouble() ??
        0.0;

    // Nếu BE nhét cả productEntity
    if (json['productEntity'] is Map) {
      try {
        final p = Product.fromJson(Map<String, dynamic>.from(json['productEntity']));
        pCode  = p.maSP.isNotEmpty ? p.maSP   : pCode;
        pName  = p.tenSP.isNotEmpty ? p.tenSP : (pName.isEmpty ? 'Sản phẩm' : pName);
        pImg   = p.hinhAnh.isNotEmpty ? p.hinhAnh : pImg;
        pPrice = p.gia > 0 ? p.gia : pPrice;
      } catch (_) {}
    }

    return OrderDetail(
      productCode: pCode,
      productName: pName.isEmpty ? 'Sản phẩm không rõ' : pName,
      imageUrl: pImg,
      price: pPrice,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      promotionCode: (json['promotionCode'] ?? json['promotion_code'])?.toString(),
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
  final String status;
  final String? note;
  final DateTime orderDate;
  final double totalAmount;      // finalAmount nếu có
  final String? promotionCode;   // ở header (nếu có)
  final String? promotionName;   // ở header (nếu có)
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
      cusCode = (json['customerEntity']['customer_code'] ?? cusCode).toString();
    }

    String orderStatus = (json['status'] ?? json['orderStatus'] ?? 'PENDING').toString();
    final bool? statusBool = json['status'] is bool ? json['status'] as bool : null;
    final bool? isPaidBool = json['isPaid'] is bool ? json['isPaid'] as bool : null;
    if (statusBool == false) orderStatus = 'CANCELLED';
    else if (statusBool == true && isPaidBool == false) orderStatus = 'PENDING';
    else if (isPaidBool == true) orderStatus = 'DELIVERED';

    final createdStr = (json['createdDate'] ?? json['orderDate'] ?? '').toString();
    final created = createdStr.isNotEmpty ? DateTime.parse(createdStr) : DateTime.now();

    final total = (json['finalAmount'] as num?)?.toDouble() ??
        (json['totalAmount'] as num?)?.toDouble() ??
        0.0;

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
      promotionCode: (json['promotionCode'] ?? json['promotion_code'])?.toString(),
      promotionName: (json['promotionName'] ?? json['promotion_name'])?.toString(),
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
      details: details ?? this.details,
    );
  }
}

/// Hành trình (nếu dùng)
class ShipmentEvent {
  final DateTime time;
  final String location;
  final String status;

  ShipmentEvent({required this.time, required this.location, required this.status});

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
      location: (json['location'] ?? json['hub'] ?? json['place'] ?? '').toString(),
      status: (json['status'] ?? json['event'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() =>
      {'time': time.toIso8601String(), 'location': location, 'status': status};
}
