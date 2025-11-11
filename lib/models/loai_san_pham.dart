import 'san_pham.dart';

class LoaiSanPham {
  final String maLSP;
  final String tenLSP;
  final String moTa;
  final String? hinhAnh;
  final List<SanPham> danhSachSanPham;

  LoaiSanPham({
    required this.maLSP,
    required this.tenLSP,
    required this.moTa,
    this.hinhAnh,
    required this.danhSachSanPham,
  });

  factory LoaiSanPham.fromJson(Map<String, dynamic> json) {
    return LoaiSanPham(
      maLSP: json['categoryCode'] ?? '',
      tenLSP: json['categoryName'] ?? '',
      moTa: json['description'] ?? '',
      hinhAnh: (json['productList'] != null && json['productList'].isNotEmpty)
          ? json['productList'][0]['image'] // Lấy hình của sản phẩm đầu tiên làm ảnh đại diện danh mục
          : null,
      danhSachSanPham: (json['productList'] as List<dynamic>?)
          ?.map((e) => SanPham.fromJson(e))
          .toList() ??
          [],
    );
  }
}
