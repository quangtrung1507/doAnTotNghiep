import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // <<< Đã xóa
import '../models/loai_san_pham.dart';
import '../services/api_service.dart';
// import '../providers/auth_provider.dart'; // <<< Đã xóa

// BẠN CẦN CHỈ ĐỊNH IMPORT NÀY SẼ LÀ PRODUCT_LIST_SCREEN
import './product_list_screen.dart'; // <<< ĐÃ SỬA: Đổi từ category_screen.dart sang product_list_screen.dart

// BỘ LỌC (GIẢI PHÁP 2: Hardcode)
const Map<String, List<String>> mainCategoryMapping = {
  'SACH': [
    'LSP01', 'LSP02', 'LSP03', 'LSP04', 'LSP05',
    'LSP06', 'LSP07', 'LSP08', 'LSP09', 'LSP10',
    'LSP18' // <<< ĐÃ THÊM: Studentbook vào nhóm SÁCH
  ],
  'DOCHOI': ['LSP11', 'LSP12'],
  'VPP': [
    'LSP13', // Calculator
    'LSP14', // Note
    // 'LSP15', // Watch - Tùy chọn: Nếu Watch không phải VPP, bạn có thể cân nhắc di chuyển hoặc tạo nhóm mới
    'LSP16', // Pen
    'LSP17', // Draw
    'LSP19', // CompaEke
    'LSP20'  // PencilEraser
  ],
  // Thêm các mã cho 'LUUNIEM', 'MANGA', 'UUDAI' nếu bạn đã định nghĩa
  'LUUNIEM': [], // Nếu có mã LSP cụ thể cho "Lưu niệm", thêm vào đây
  'MANGA': [],   // Nếu có mã LSP cụ thể cho "Manga", thêm vào đây
  'UUDAI': [],   // Nếu có mã LSP cụ thể cho "Ưu đãi", thêm vào đây
};


class BookCategoryListScreen extends StatefulWidget {
  final String mainCategoryCode; // Ví dụ: 'SACH', 'DOCHOI'
  final String title; // Ví dụ: 'Sách', 'Đồ chơi'

  const BookCategoryListScreen({
    Key? key,
    required this.mainCategoryCode,
    required this.title,
  }) : super(key: key);

  @override
  State<BookCategoryListScreen> createState() => _BookCategoryListScreenState();
}

class _BookCategoryListScreenState extends State<BookCategoryListScreen> {
  late Future<List<LoaiSanPham>> _allCategoriesFuture;

  @override
  void initState() {
    super.initState();
    // Gọi API fetchAllCategories để lấy TẤT CẢ danh mục
    _allCategoriesFuture = ApiService.fetchAllCategories();
  }

  // Hàm lọc danh sách các loại sản phẩm
  List<LoaiSanPham> _filterCategories(List<LoaiSanPham> allCategories) {
    // Lấy danh sách các mã LSP con (ví dụ: ['LSP01', 'LSP02', ...])
    // dựa trên mã danh mục chính (ví dụ: 'SACH')
    final codesToShow = mainCategoryMapping[widget.mainCategoryCode];

    if (codesToShow == null) {
      // Nếu mainCategoryCode không có trong map (ví dụ: 'MANGA' nhưng chưa có mã LSP nào)
      return [];
    }
    // Lọc danh sách đầy đủ các loại sản phẩm để chỉ giữ lại những loại có mã LSP
    // nằm trong danh sách codesToShow
    return allCategories.where((category) {
      return codesToShow.contains(category.maLSP);
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // Hiển thị tiêu đề động (ví dụ: "Sách", "Đồ chơi")
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<List<LoaiSanPham>>(
        future: _allCategoriesFuture, // Sử dụng Future để tải dữ liệu danh mục
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Hiển thị loading
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}")); // Hiển thị lỗi
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Không tìm thấy danh mục nào.")); // Không có dữ liệu
          }

          // Lọc danh sách đầy đủ các loại sản phẩm để có được các thể loại con của nhóm chính
          final categories = _filterCategories(snapshot.data!);

          if (categories.isEmpty) {
            return const Center(child: Text("Không tìm thấy danh mục con nào.")); // Không có danh mục con
          }

          // Hiển thị danh sách các loại sản phẩm con dưới dạng ListView
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (ctx, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      category.tenLSP.isNotEmpty ? category.tenLSP[0] : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                  title: Text(
                    category.tenLSP,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(category.moTa),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // <<< ĐÃ SỬA: Điều hướng đến ProductListScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductListScreen( // Thay CategoryScreen bằng ProductListScreen
                          categoryCode: category.maLSP, // Đảm bảo tên tham số đúng
                          title: category.tenLSP,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}