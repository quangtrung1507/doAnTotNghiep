class SanPham {
  final String maSP;
  final String tenSP;
  final String moTa;
  final String hinhAnh;
  final String author;
  final String publisher;
  final double gia;
  final double importPrice;
  final String? promotionCode;
  final String? promotionName;
  final double? discountValue;
  final String maLSP;
  final String categoryName;
  final int stockQuantity;
  bool isFavorite;

  SanPham({
    required this.maSP,
    required this.tenSP,
    required this.moTa,
    required this.hinhAnh,
    required this.author,
    required this.publisher,
    required this.gia,
    required this.importPrice,
    this.promotionCode,
    this.promotionName,
    this.discountValue,
    required this.maLSP,
    required this.categoryName,
    required this.stockQuantity,
    this.isFavorite = false,
  });

  // lib/models/san_pham.dart

  factory SanPham.fromJson(Map<String, dynamic> json) {
    return SanPham(
      // Đảm bảo tất cả các trường String đều có '?? ''
      maSP: json['productCode'] ?? '',
      tenSP: json['productName'] ?? '',
      moTa: json['description'] ?? '',
      hinhAnh: json['image'] ?? '',
      author: json['author'] ?? '',
      publisher: json['publisher'] ?? '',

      // Đảm bảo các trường số có '?? 0'
      gia: (json['price'] as num?)?.toDouble() ?? 0.0,
      importPrice: (json['importPrice'] as num?)?.toDouble() ?? 0.0,

      // Các trường nullable (String?) thì có thể nhận null
      promotionCode: json['promotionCode'],
      promotionName: json['promotionName'],
      discountValue: (json['discountValue'] as num?)?.toDouble(),

      // Các trường String khác
      maLSP: json['categoryCode'] ?? '',
      categoryName: json['categoryName'] ?? '',
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productCode': maSP,
      'productName': tenSP,
      'description': moTa,
      'image': hinhAnh,
      'author': author,
      'publisher': publisher,
      'price': gia,
      'importPrice': importPrice,
      'promotionCode': promotionCode,
      'promotionName': promotionName,
      'discountValue': discountValue,
      'categoryCode': maLSP,
      'categoryName': categoryName,
      'stockQuantity': stockQuantity,
    };
  }
}
