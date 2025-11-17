// lib/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // ... (Tất cả biến, controller, initState, dispose, hàm load địa chỉ... giữ nguyên) ...
  final _formKey = GlobalKey<FormState>();
  final _diaChiController = TextEditingController();
  final _sdtController = TextEditingController();
  final _ghiChuController = TextEditingController();
  String _phuongThucThanhToan = 'COD';
  bool _isLoading = false;
  bool _isLoadingProvinces = true;
  bool _isLoadingDistricts = false;
  bool _isLoadingWards = false;
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _wards = [];
  Map<String, dynamic>? _selectedProvince;
  Map<String, dynamic>? _selectedDistrict;
  Map<String, dynamic>? _selectedWard;
  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }
  @override
  void dispose() {
    _diaChiController.dispose();
    _sdtController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }
  Future<void> _loadProvinces() async {
    try {
      final provinces = await ApiService.fetchProvinces();
      setState(() { _provinces = provinces; _isLoadingProvinces = false; });
    } catch (e) {
      setState(() { _isLoadingProvinces = false; });
      _showErrorDialog(e.toString());
    }
  }
  Future<void> _loadDistricts(int provinceId) async {
    setState(() { _isLoadingDistricts = true; _districts = []; _wards = []; _selectedDistrict = null; _selectedWard = null; });
    try {
      final districts = await ApiService.fetchDistricts(provinceId);
      setState(() { _districts = districts; _isLoadingDistricts = false; });
    } catch (e) {
      setState(() { _isLoadingDistricts = false; });
      _showErrorDialog(e.toString());
    }
  }
  Future<void> _loadWards(int districtId) async {
    setState(() { _isLoadingWards = true; _wards = []; _selectedWard = null; });
    try {
      final wards = await ApiService.fetchWards(districtId);
      setState(() { _wards = wards; _isLoadingWards = false; });
    } catch (e) {
      setState(() { _isLoadingWards = false; });
    }
  }

  // -----------------------------------------------------
  // 🔴 SỬA LẠI LOGIC HÀM _submitOrder
  // -----------------------------------------------------
  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (cartProvider.items.isEmpty) {
      _showErrorDialog('Giỏ hàng của bạn đang trống.');
      return;
    }

    _formKey.currentState!.save();
    setState(() { _isLoading = true; });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final customerCode = authProvider.customerCode;
      if (customerCode == null) {
        throw Exception('Lỗi: Người dùng không hợp lệ. Vui lòng đăng nhập lại.');
      }

      final String street = _diaChiController.text;
      final String ward = _selectedWard?['WardName'] ?? '';
      final String district = _selectedDistrict?['DistrictName'] ?? '';
      final String province = _selectedProvince?['ProvinceName'] ?? '';
      final String fullAddress = "$street, $ward, $district, $province";

      // BƯỚC 1: TẠO ĐƠN HÀNG (Nếu lỗi sẽ văng ra catch)
      await ApiService.createOrder(
        customerCode: customerCode,
        cartItems: cartProvider.items,
        address: fullAddress,
        phoneNumber: _sdtController.text,
        paymentMethod: _phuongThucThanhToan == 'COD' ? 'Cash' : 'QR',
        note: _ghiChuController.text,
      );

      // BƯỚC 2: XÓA GIỎ HÀNG (Local)
      cartProvider.clearCart();

      // BƯỚC 3: XÓA GIỎ HÀNG (Server) - Bọc trong try...catch riêng
      try {
        await ApiService.clearCartOnServer(customerCode);
      } catch (e) {
        // Lỗi 404 này là bình thường (vì server đã tự xóa) -> Lờ nó đi
        print('Lỗi dọn dẹp giỏ hàng (bỏ qua): $e');
      }

      // BƯỚC 4: HIỂN THỊ THÀNH CÔNG (Vì bước 1 đã qua)
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Thành công!'),
            content: const Text('Bạn đã đặt hàng thành công.'),
            actions: [
              TextButton(
                child: const Text('Xem đơn hàng'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                  );
                },
              )
            ],
          ),
        );
      }
    } catch (e) {
      // Chỉ có lỗi từ 'createOrder' mới nhảy vào đây
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Có lỗi xảy ra!'),
          content: Text(message.replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(ctx).pop(),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Toàn bộ code UI (build, _buildGhnDropdown, bottomNavigationBar) giữ nguyên) ...
    final cartProvider = Provider.of<CartProvider>(context);
    final tongTienHang = cartProvider.totalPrice;
    final phiVanChuyen = 30000.0;
    final tongThanhToan = tongTienHang + phiVanChuyen;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông Tin Thanh Toán'),
        backgroundColor: AppColors.card,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông tin giao hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _sdtController,
                        decoration: const InputDecoration(labelText: 'Số điện thoại'),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildGhnDropdown(
                        label: 'Tỉnh/Thành phố',
                        hint: 'Chọn Tỉnh/Thành',
                        isLoading: _isLoadingProvinces,
                        items: _provinces,
                        displayKey: 'ProvinceName',
                        selectedValue: _selectedProvince,
                        onChanged: (value) {
                          setState(() {
                            _selectedProvince = value;
                            _selectedDistrict = null;
                            _selectedWard = null;
                          });
                          if (value != null) {
                            _loadDistricts(value['ProvinceID']);
                          }
                        },
                      ),
                      _buildGhnDropdown(
                        label: 'Quận/Huyện',
                        hint: 'Chọn Quận/Huyện',
                        isLoading: _isLoadingDistricts,
                        items: _districts,
                        displayKey: 'DistrictName',
                        selectedValue: _selectedDistrict,
                        onChanged: (value) {
                          setState(() {
                            _selectedDistrict = value;
                            _selectedWard = null;
                          });
                          if (value != null) {
                            _loadWards(value['DistrictID']);
                          }
                        },
                      ),
                      _buildGhnDropdown(
                        label: 'Phường/Xã',
                        hint: 'Chọn Phường/Xã',
                        isLoading: _isLoadingWards,
                        items: _wards,
                        displayKey: 'WardName',
                        selectedValue: _selectedWard,
                        onChanged: (value) {
                          setState(() {
                            _selectedWard = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _diaChiController,
                        decoration: const InputDecoration(labelText: 'Địa chỉ (Số nhà, tên đường)'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập địa chỉ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _ghiChuController,
                        decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Thanh toán khi nhận hàng (COD)'),
                      value: 'COD',
                      groupValue: _phuongThucThanhToan,
                      onChanged: (value) {
                        setState(() {
                          _phuongThucThanhToan = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Chuyển khoản ngân hàng'),
                      value: 'BANK',
                      groupValue: _phuongThucThanhToan,
                      onChanged: (value) {
                        setState(() {
                          _phuongThucThanhToan = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền hàng:'),
                Text('${tongTienHang.toStringAsFixed(0)}đ'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Phí vận chuyển:'),
                Text('${phiVanChuyen.toStringAsFixed(0)}đ'),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${tongThanhToan.toStringAsFixed(0)}đ',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading) ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
                    : const Text('Đặt Hàng', style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGhnDropdown({
    required String label,
    required String hint,
    required bool isLoading,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic>? selectedValue,
    required String displayKey,
    required void Function(Map<String, dynamic>?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<Map<String, dynamic>>(
        value: selectedValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: isLoading
              ? const Padding(padding: EdgeInsets.all(10.0), child: CircularProgressIndicator(strokeWidth: 2))
              : null,
        ),
        hint: Text(hint),
        onChanged: (isLoading || items.isEmpty) ? null : onChanged,
        validator: (value) => (value == null) ? 'Vui lòng chọn $label' : null,
        items: items.map((item) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: item,
            child: Text(item[displayKey]),
          );
        }).toList(),
      ),
    );
  }
}