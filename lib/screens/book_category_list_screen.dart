import 'package:flutter/material.dart';
import '../data/sample_data.dart'; // Biến 'categories' từ file này đã sẵn sàng để dùng
import './category_screen.dart';

class BookCategoryListScreen extends StatelessWidget {
  const BookCategoryListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ SỬA LỖI: Chúng ta không cần dòng "final categories = categories;" nữa.
    // Chúng ta sẽ sử dụng trực tiếp biến "categories" đã được import.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thể Loại Sách'),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        // Sử dụng trực tiếp biến 'categories' từ file sample_data
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
                  (category['name'] as String)[0],
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              title: Text(
                category['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(category['desc'] as String), // Tôi đã bỏ comment dòng này ra để hiển thị mô tả
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryScreen(
                      maLSP: category['code'] as String,
                      tenLSP: category['name'] as String,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}