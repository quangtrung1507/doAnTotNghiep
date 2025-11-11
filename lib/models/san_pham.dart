class SanPham {
  final String maSP;
  final String tenSP;
  final String moTa;
  final String hinhAnh;
  final double gia;
  final String maLSP;
  bool isFavorite;

  SanPham({
    required this.maSP,
    required this.tenSP,
    required this.moTa,
    required this.hinhAnh,
    required this.gia,
    required this.maLSP,
    this.isFavorite = false,
  });

  factory SanPham.fromJson(Map<String, dynamic> json) {
    return SanPham(
      maSP: json['productCode'] ?? '',
      tenSP: json['productName'] ?? '',
      moTa: json['description'] ?? '',
      hinhAnh: json['image'] ?? '',
      gia: (json['price'] ?? 0).toDouble(),
      maLSP: json['categoryCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productCode': maSP,
      'productName': tenSP,
      'description': moTa,
      'image': hinhAnh,
      'price': gia,
      'categoryCode': maLSP,
    };
  }
}
