// lib/providers/cart_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<CartItem> get items => _items;

  // -----------------------------------------------------------------
  // 🔴 HÀM TẢI GIỎ HÀNG (ĐÃ VIẾT LẠI HOÀN TOÀN ĐỂ SỬA LỖI)
  // -----------------------------------------------------------------
  Future<void> fetchCart(String customerCode) async {
    if (customerCode.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      print('🛒 [CartProvider] Đang gọi... (Bước 1/2: Tải tất cả sản phẩm)');

      // BƯỚC 1: Lấy danh sách TẤT CẢ sản phẩm (để có giá/tên/ảnh)
      final allProductsList = await ApiService.fetchAllProducts();
      // Chuyển sang Map (giống danh bạ) để tra cứu nhanh bằng mã SP
      final Map<String, Product> allProductsMap = {
        for (var product in allProductsList) product.maSP: product
      };

      print('🛒 [CartProvider] Đang gọi... (Bước 2/2: Tải giỏ hàng thô)');

      // BƯỚC 2: Lấy giỏ hàng "thô" (chỉ ID và số lượng)
      // (Hàm này đã được sửa ở ApiService để trả về List<Map>)
      final List<Map<String, dynamic>> rawCart = await ApiService.fetchCart(customerCode);

      // BƯỚC 3: Gộp (merge) 2 danh sách
      final List<CartItem> fullCartItems = [];

      for (var rawItem in rawCart) {
        // Đọc product_code và quantity từ DB (giống ảnh DB của bạn)
        // Backend của bạn có thể dùng 'product_code' (có gạch dưới) hoặc 'productCode'
        final productCode = rawItem['product_code']?.toString() ?? rawItem['productCode']?.toString();
        final quantity = (rawItem['quantity'] as int?) ?? 1;

        if (productCode != null) {
          // Tìm sản phẩm đầy đủ trong Map
          final fullProduct = allProductsMap[productCode];

          if (fullProduct != null) {
            // Nếu tìm thấy, tạo CartItem hoàn chỉnh (có tên, giá, ảnh)
            fullCartItems.add(CartItem(product: fullProduct, quantity: quantity));
          } else {
            // Bỏ qua nếu sản phẩm trong giỏ hàng không còn tồn tại trong shop
            print('⚠️ [CartProvider] Bỏ qua item: không tìm thấy chi tiết cho $productCode');
          }
        }
      }

      // BƯỚC 4: Cập nhật UI
      _items = fullCartItems;
      print('✅ [CartProvider] Đã tải ${fullCartItems.length} món trong giỏ hàng (đã gộp).');

    } catch (e) {
      print('❌ [CartProvider] Lỗi fetchCart (đã sửa): $e');
      _items = []; // Xóa trắng nếu lỗi
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- (Các hàm còn lại giữ nguyên) ---

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  Future<void> addItem(Product product, String? customerCode) async {
    final existingItem = _items.firstWhere(
          (item) => item.product.maSP == product.maSP,
      orElse: () => CartItem(product: product, quantity: 0),
    );
    final bool isNewItem = (existingItem.quantity == 0);
    final newQuantity = existingItem.quantity + 1;

    if (isNewItem) {
      _items.add(CartItem(product: product, quantity: 1));
    } else {
      existingItem.quantity = newQuantity;
    }
    notifyListeners();

    if (customerCode != null && customerCode.isNotEmpty) {
      try {
        if (isNewItem) {
          await ApiService.addCartItem(customerCode, product.maSP, newQuantity);
        } else {
          await ApiService.updateCartQuantity(customerCode, product.maSP, newQuantity);
        }
      } catch (e) {
        print('❌ Lỗi API Add/Update Item: $e. Đang hoàn tác...');
        if (isNewItem) {
          _items.removeWhere((item) => item.product.maSP == product.maSP);
        } else {
          existingItem.quantity = newQuantity - 1;
        }
        notifyListeners();
        throw Exception('Thêm vào giỏ hàng thất bại: $e');
      }
    } else {
      print('Đã thêm (offline) ${product.tenSP}');
    }
  }

  Future<void> increaseQuantity(String maSP, String? customerCode) async {
    final item = _items.firstWhere((item) => item.product.maSP == maSP);
    item.quantity++;
    notifyListeners();
    if (customerCode != null && customerCode.isNotEmpty) {
      try {
        await ApiService.updateCartQuantity(customerCode, maSP, item.quantity);
      } catch (e) {
        print('❌ Lỗi API IncreaseQuantity: $e. Đang hoàn tác...');
        item.quantity--;
        notifyListeners();
      }
    }
  }

  Future<void> decreaseQuantity(String maSP, String? customerCode) async {
    final item = _items.firstWhere((item) => item.product.maSP == maSP);
    if (item.quantity > 1) {
      item.quantity--;
      notifyListeners();
      if (customerCode != null && customerCode.isNotEmpty) {
        try {
          await ApiService.updateCartQuantity(customerCode, maSP, item.quantity);
        } catch (e) {
          print('❌ Lỗi API DecreaseQuantity: $e. Đang hoàn tác...');
          item.quantity++;
          notifyListeners();
        }
      }
    } else {
      await removeItem(maSP, customerCode);
    }
  }

  Future<void> removeItem(String maSP, String? customerCode) async {
    final existingItemIndex = _items.indexWhere((item) => item.product.maSP == maSP);
    if (existingItemIndex == -1) return;
    final existingItem = _items[existingItemIndex];
    _items.removeAt(existingItemIndex);
    notifyListeners();
    if (customerCode != null && customerCode.isNotEmpty) {
      try {
        await ApiService.removeCartItem(customerCode, maSP);
      } catch (e) {
        print('❌ Lỗi API RemoveItem: $e. Đang hoàn tác...');
        _items.insert(existingItemIndex, existingItem);
        notifyListeners();
      }
    }
  }

  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + (item.product.gia * item.quantity));
  }

  int get itemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }
}