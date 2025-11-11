import 'san_pham.dart';

class GioHangItem {
  final SanPham sanPham;
  int soLuong;

  GioHangItem({
    required this.sanPham,
    this.soLuong = 1, // Mặc định khi thêm vào giỏ là 1 sản phẩm
  });
}