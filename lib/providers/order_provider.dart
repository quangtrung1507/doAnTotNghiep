// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _myOrders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Order> get myOrders => _myOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyOrders(String customerCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myOrders = await ApiService.fetchMyOrders(customerCode);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// Bạn có thể thêm các hàm khác như:
// - fetchOrderDetails(String orderCode)
// - cancelOrder(String orderCode) (nếu backend hỗ trợ)
}