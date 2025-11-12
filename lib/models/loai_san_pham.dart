class LoaiSanPham {
  final String maLSP;     // categoryCode
  final String tenLSP;    // categoryName
  final String moTa;
  final String? mainCode; // SACH/DOCHOI/LUUNIEM/MANGA/VPP

  LoaiSanPham({
    required this.maLSP,
    required this.tenLSP,
    required this.moTa,
    this.mainCode,
  });

  factory LoaiSanPham.fromJson(Map<String, dynamic> json) {
    return LoaiSanPham(
      maLSP: json['categoryCode'] ?? json['category_code'] ?? '',
      tenLSP: json['categoryName'] ?? json['category_name'] ?? '',
      moTa: json['description'] ?? '',
      mainCode: json['mainCode'] ?? json['main_code'],
    );
  }
}
