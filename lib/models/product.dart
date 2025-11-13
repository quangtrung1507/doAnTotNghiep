class Product {
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

  // ⬇️ ĐÃ SỬA: Đổi tên constructor
  Product({
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

  /// Hỗ trợ cả JSON phẳng và JSON lồng dạng { "productEntity": {...} }
  // ⬇️ ĐÃ SỬA: Đổi tên factory
  factory Product.fromJson(Map<String, dynamic> json) {
    final src = (json['productEntity'] is Map<String, dynamic>)
        ? (json['productEntity'] as Map<String, dynamic>)
        : json;

    String _s(String k) => (src[k] ?? '').toString();
    double _d(String k) {
      final v = src[k];
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }
    int _i(String k) {
      final v = src[k];
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    // ⬇️ ĐÃ SỬA: Gọi constructor 'Product'
    return Product(
      maSP: _s('productCode'),
      tenSP: _s('productName'),
      moTa: _s('description'),
      hinhAnh: _s('image'),
      author: _s('author'),
      publisher: _s('publisher'),
      gia: _d('price'),
      importPrice: _d('importPrice'),
      promotionCode: src['promotionCode']?.toString(),
      promotionName: src['promotionName']?.toString(),
      discountValue: (src['discountValue'] is num)
          ? (src['discountValue'] as num).toDouble()
          : double.tryParse(src['discountValue']?.toString() ?? ''),
      maLSP: _s('categoryCode'),
      categoryName: _s('categoryName'),
      stockQuantity: _i('stockQuantity'),
    );
  }

  Map<String, dynamic> toJson() => {
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