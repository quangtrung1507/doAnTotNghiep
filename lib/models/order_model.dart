class OrderDetail {
  final String productCode;
  final String productName;
  final String imageUrl;
  final double price;
  final int quantity;

  OrderDetail({
    required this.productCode,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      productCode: json['productCode'] ?? '',
      productName: json['productName'] ?? 'Sản phẩm không rõ',
      imageUrl: json['imageUrl'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
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
  final double totalAmount;
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
    required this.details,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var detailsList = json['details'] as List? ?? [];
    List<OrderDetail> orderDetails = detailsList.map((i) => OrderDetail.fromJson(i)).toList();

    return Order(
      orderCode: json['orderCode'] ?? '',
      customerCode: json['customerCode'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      orderType: json['orderType'] ?? '',
      status: json['status'] ?? 'UNKNOWN',
      note: json['note'],
      orderDate: DateTime.parse(json['orderDate']),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      details: orderDetails,
    );
  }
}