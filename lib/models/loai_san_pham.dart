// 1. Xóa import 'san_pham.dart' vì model này không còn chứa sản phẩm nữa.
// import 'san_pham.dart';

class LoaiSanPham {
  final String maLSP;
  final String tenLSP;
  final String moTa;
  // 2. Xóa hinhAnh và danhSachSanPham.
  // API danh mục của bạn (dựa trên bảng SQL) không chứa các trường này.

  LoaiSanPham({
    required this.maLSP,
    required this.tenLSP,
    required this.moTa,
  });

  // 3. Đơn giản hóa hàm factory FromJson
  factory LoaiSanPham.fromJson(Map<String, dynamic> json) {
    return LoaiSanPham(
      maLSP: json['categoryCode'] ?? '',
      tenLSP: json['categoryName'] ?? '',
      moTa: json['description'] ?? '',
      // Xóa toàn bộ logic 'productList' và 'hinhAnh' cũ
    );
  }
}