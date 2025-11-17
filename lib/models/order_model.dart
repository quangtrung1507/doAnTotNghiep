// lib/models/order_model.dart
import 'product.dart'; // Import Product model

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

  // 🔴 SỬA HÀM fromJson ĐỂ ĐỌC "productEntity" TỪ "InvoiceDetailEntity"
  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    String pCode = json['productCode'] ?? '';
    String pName = json['productName'] ?? 'Sản phẩm không rõ';
    String pImg = json['imageUrl'] ?? '';
    // Backend Java dùng 'unitPrice'
    double pPrice = (json['unitPrice'] as num?)?.toDouble() ?? 0.0;

    // Kiểm tra nếu Backend trả về object 'productEntity' (tốt hơn)
    if (json['productEntity'] != null && json['productEntity'] is Map) {
      try {
        final product = Product.fromJson(json['productEntity']);
        pCode = product.maSP;
        pName = product.tenSP;
        pImg = product.hinhAnh;
        pPrice = product.gia;
      } catch (e) {
        print("Lỗi parse productEntity lồng trong OrderDetail: $e");
      }
    }

    return OrderDetail(
      productCode: pCode,
      productName: pName,
      imageUrl: pImg,
      price: pPrice,
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
  final String status; // Trạng thái (Pending, Delivered...)
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

  // 🔴 SỬA LẠI HÀM 'fromJson' ĐỂ KHỚP VỚI 'InvoiceEntity.java'
  factory Order.fromJson(Map<String, dynamic> json) {
    // 1. Đọc danh sách chi tiết (Backend dùng 'orderDetailList')
    var detailsList = json['orderDetailList'] as List? ?? [];
    List<OrderDetail> orderDetails = detailsList.map((i) => OrderDetail.fromJson(i)).toList();

    // 2. Đọc mã khách hàng (Backend lồng trong 'customerEntity')
    String cusCode = json['customerCode'] ?? '';
    if (json['customerEntity'] != null && json['customerEntity'] is Map) {
      cusCode = json['customerEntity']['customer_code'] ?? cusCode;
    }

    // 3. Xử lý Trạng thái (Backend dùng Boolean 'status' và 'isPaid')
    String orderStatus = "UNKNOWN";
    bool? statusBool = json['status'] as bool?; // true
    bool? isPaidBool = json['isPaid'] as bool?; // false

    if (statusBool == false) {
      orderStatus = "CANCELLED"; // Giả sử status=false là 'CANCELLED'
    } else if (isPaidBool == true) {
      orderStatus = "DELIVERED"; // Giả sử isPaid=true là 'Đã giao'
    } else if (statusBool == true && isPaidBool == false) {
      // Đây là trường hợp của bạn: status=1 (true) và isPaid=0 (false)
      orderStatus = "PENDING"; // Đang chờ xác nhận/thanh toán
    }

    return Order(
      orderCode: json['orderCode'] ?? '',
      customerCode: cusCode,
      address: json['address'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'UNKNOWN',
      orderType: json['orderType'] ?? 'UNKNOWN',
      status: orderStatus, // Dùng status đã xử lý
      note: json['note'],
      // 🔴 SỬA LỖI: Đọc 'createdDate' (camelCase) mà Spring Boot trả về
      orderDate: DateTime.parse(json['createdDate']),
      // 🔴 SỬA LỖI: Đọc 'finalAmount'
      totalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      details: orderDetails,
    );
  }
}