import 'package:flutter/material.dart';
import '../models/loai_san_pham.dart';
import '../services/api_service.dart';
import './product_list_screen.dart';

class BookCategoryListScreen extends StatefulWidget {
  /// mainCategoryCode: SACH / DOCHOI / LUUNIEM / MANGA / VPP
  final String mainCategoryCode;
  final String title;

  const BookCategoryListScreen({
    super.key,
    required this.mainCategoryCode,
    required this.title,
  });

  @override
  State<BookCategoryListScreen> createState() => _BookCategoryListScreenState();
}

class _BookCategoryListScreenState extends State<BookCategoryListScreen> {
  late Future<List<LoaiSanPham>> _subCatsFuture;

  @override
  void initState() {
    super.initState();
    // ❗ Không dùng /categories/by-main (JSON lặp)
    // → Lấy toàn bộ /categories rồi lọc client-side theo mainCategoryCode
    _subCatsFuture = _loadSubCategories();
  }

  Future<List<LoaiSanPham>> _loadSubCategories() async {
    final all = await ApiService.fetchAllCategories();
    return _filterCategoriesForMain(all, widget.mainCategoryCode);
  }

  /// Mapping theo tên danh mục (categoryName) → nhóm chính.
  List<LoaiSanPham> _filterCategoriesForMain(List<LoaiSanPham> all, String main) {
    final m = main.toUpperCase();
    bool nameHas(LoaiSanPham c, List<String> keys) {
      final n = c.tenLSP.toLowerCase();
      return keys.any((k) => n.contains(k));
    }

    switch (m) {
      case 'SACH':
        return all.where((c) => nameHas(c, [
          'romance','horror','fantasy','business','drama','biography','cook','poetry','art','architecture'
        ])).toList();
      case 'DOCHOI':
        return all.where((c) => nameHas(c, ['modelkit','figure'])).toList();
      case 'LUUNIEM':
        return all.where((c) => nameHas(c, ['watch','gift'])).toList();
      case 'MANGA':
        return all.where((c) => nameHas(c, ['manga'])).toList();
      case 'VPP':
        return all.where((c) => nameHas(c, [
          'calculator','note','pen','draw','studentbook','compa','pencil','eraser'
        ])).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<LoaiSanPham>>(
        future: _subCatsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snap.error}'));
          }
          final cats = snap.data ?? [];
          if (cats.isEmpty) {
            return const Center(child: Text('Không tìm thấy danh mục con nào.'));
          }

          return ListView.builder(
            itemCount: cats.length,
            itemBuilder: (_, i) {
              final c = cats[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      c.tenLSP.isNotEmpty ? c.tenLSP[0] : '?',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  title: Text(c.tenLSP, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(c.moTa),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductListScreen(
                          categoryCode: c.maLSP,
                          title: c.tenLSP,
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
