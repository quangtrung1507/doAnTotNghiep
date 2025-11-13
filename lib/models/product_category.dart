// lib/models/product_category.dart

class ProductCategory {
  final String maLSP;     // categoryCode
  final String tenLSP;    // categoryName
  final String moTa;
  final String? mainCode; // Sẽ chứa 'book', 'modelKit', 'figure'...

  ProductCategory({
    required this.maLSP,
    required this.tenLSP,
    required this.moTa,
    this.mainCode,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      maLSP: json['categoryCode'] ?? json['category_code'] ?? '',
      tenLSP: json['categoryName'] ?? json['category_name'] ?? '',
      moTa: json['description'] ?? '',

      // ⬇️ ⬇️ ⬇️ SỬA DÒNG NÀY ⬇️ ⬇️ ⬇️
      // Đọc từ 'category_type' (từ SQL) thay vì 'main_code'
      mainCode: json['categoryType'] ?? json['category_type'],
    );
  }
}