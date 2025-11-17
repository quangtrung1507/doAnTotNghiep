// lib/screens/checkout_screen.dart
import 'package:bookstore/screens/order_detail_screen.dart';
import 'package:bookstore/screens/pay_with_qr_screen.dart';
import 'package:bookstore/screens/pay_with_qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../models/promotion.dart';
import '../services/promotion_service.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // ======= Giữ nguyên các biến cũ của bạn =======
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

  // ======= MỚI: Voucher =======
  bool _loadingPromotions = false;
  List<Promotion> _promotions = [];
  Promotion? _selectedPromotion;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _loadPromotions();
  }

  @override
  void dispose() {
    _diaChiController.dispose();
    _sdtController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  // ======= GHN: Tỉnh/Huyện/Xã (giữ y chang) =======
  Future<void> _loadProvinces() async {
    try {
      final provinces = await ApiService.fetchProvinces();
      setState(() {
        _provinces = provinces;
        _isLoadingProvinces = false;
      });
    } catch (e) {
      setState(() => _isLoadingProvinces = false);
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _loadDistricts(int provinceId) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _wards = [];
      _selectedDistrict = null;
      _selectedWard = null;
    });
    try {
      final districts = await ApiService.fetchDistricts(provinceId);
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });
    } catch (e) {
      setState(() => _isLoadingDistricts = false);
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _loadWards(int districtId) async {
    setState(() {
      _isLoadingWards = true;
      _wards = [];
      _selectedWard = null;
    });
    try {
      final wards = await ApiService.fetchWards(districtId);
      setState(() {
        _wards = wards;
        _isLoadingWards = false;
      });
    } catch (e) {
      setState(() => _isLoadingWards = false);
      _showErrorDialog(e.toString());
    }
  }

  // ======= PROMOTIONS (Voucher) =======
  Future<void> _loadPromotions() async {
    setState(() => _loadingPromotions = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.authToken;
      // thử PromotionService (đa đường dẫn); có token nếu server yêu cầu
      final list = await PromotionService.fetchActivePromotions(token: token);
      setState(() {
        _promotions = list;
      });
    } catch (_) {
      // fallback sang ApiService (một đường dẫn cố định)
      try {
        final list = await ApiService.fetchActivePromotions();
        setState(() {
          _promotions = list.where((x) => x.status == true).toList();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải voucher: ${e.toString()}')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loadingPromotions = false);
    }
  }

  // ======= TÍNH TIỀN (có voucher) =======
  double _calcDiscount(double merchandiseTotal) {
    if (_selectedPromotion == null) return 0.0;

    // PT_01 = Percent, PT_02 = Amount (theo BE của bạn)
    if (_selectedPromotion!.promotionTypeCode == 'PT_01') {
      final percent = _selectedPromotion!.value; // ví dụ 0.05 = 5%
      return (merchandiseTotal * percent).clamp(0, merchandiseTotal);
    } else if (_selectedPromotion!.promotionTypeCode == 'PT_02') {
      final amount = _selectedPromotion!.value; // ví dụ 200000
      return amount.clamp(0, merchandiseTotal);
    }
    return 0.0;
  }

  // ======= ĐẶT HÀNG =======
  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (cartProvider.items.isEmpty) {
      _showErrorDialog('Giỏ hàng của bạn đang trống.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final customerCode = authProvider.customerCode;
      if (customerCode == null || customerCode.isEmpty) {
        throw Exception('Lỗi: Người dùng không hợp lệ. Vui lòng đăng nhập lại.');
      }

      final String street = _diaChiController.text;
      final String ward = _selectedWard?['WardName'] ?? '';
      final String district = _selectedDistrict?['DistrictName'] ?? '';
      final String province = _selectedProvince?['ProvinceName'] ?? '';
      final String fullAddress = "$street, $ward, $district, $province";

      // Tính tiền để truyền sang QR (nếu cần)
      final cart = Provider.of<CartProvider>(context, listen: false);
      final double merchandise = cart.totalPrice;
      final double discount = _calcDiscount(merchandise);
      final double ship = 30000.0;
      final double grandTotal = (merchandise - discount + ship).clamp(0, double.infinity);

      // 🔥 TẠO ĐƠN – NHẬN LẠI orderCode
      final String orderCode = await ApiService.createOrder(
        customerCode: customerCode,
        cartItems: cartProvider.items,
        address: fullAddress,
        phoneNumber: _sdtController.text,
        paymentMethod: _phuongThucThanhToan == 'COD' ? 'Cash' : 'QR',
        note: _ghiChuController.text,
        promotionCode: _selectedPromotion?.promotionCode, // ✅ truyền voucher nếu có
      );

      // Xóa giỏ local
      cartProvider.clearCart();
      // Best-effort xóa server
      try { await ApiService.clearCartOnServer(customerCode); } catch (_) {}

      if (!mounted) return;

      // 👉 Điều hướng ngay theo phương thức thanh toán
      if (_phuongThucThanhToan == 'BANK') {
        // sang QR thật để hoàn tất
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PayWithQrScreen(
              orderCode: orderCode,
              amount: grandTotal.round(),

            ),
          ),
        );
      } else {
        // COD: xem chi tiết đơn vừa tạo
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderCode: orderCode),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Có lỗi xảy ra!'),
        content: Text(message.replaceAll('Exception: ', '')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  // ======= UI =======
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final tongTienHang = cartProvider.totalPrice;
    final giamGia = _calcDiscount(tongTienHang);
    final phiVanChuyen = 30000.0;
    final tongThanhToan = (tongTienHang - giamGia + phiVanChuyen).clamp(0, double.infinity);

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
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Vui lòng nhập số điện thoại'
                            : null,
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
                        onChanged: (value) => setState(() => _selectedWard = value),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _diaChiController,
                        decoration: const InputDecoration(labelText: 'Địa chỉ (Số nhà, tên đường)'),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Vui lòng nhập địa chỉ'
                            : null,
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
                      onChanged: (value) => setState(() => _phuongThucThanhToan = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Chuyển khoản ngân hàng'),
                      value: 'BANK',
                      groupValue: _phuongThucThanhToan,
                      onChanged: (value) => setState(() => _phuongThucThanhToan = value!),
                    ),
                  ],
                ),
              ),

              // ======= VOUCHER =======
              const SizedBox(height: 16),
              const Text('Voucher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.card_giftcard),
                  title: const Text('Chọn voucher'),
                  subtitle: Text(_selectedPromotion == null
                      ? 'Chưa chọn'
                      : '${_selectedPromotion!.promotionCode} • ${_selectedPromotion!.promotionName}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openVoucherBottomSheet,
                ),
              ),
            ],
          ),
        ),
      ),

      // ======= TỔNG KẾT + ĐẶT HÀNG =======
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('Tổng tiền hàng:', '${tongTienHang.toStringAsFixed(0)}đ'),
            _row('Giảm giá:', '- ${giamGia.toStringAsFixed(0)}đ'),
            _row('Phí vận chuyển:', '${phiVanChuyen.toStringAsFixed(0)}đ'),
            const Divider(height: 24),
            _row(
              'Tổng thanh toán:',
              '${tongThanhToan.toStringAsFixed(0)}đ',
              isBold: true,
              valueColor: AppColors.primary,
              fontSize: 20,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20, height: 20,
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

  // ======= Helper UI =======
  Widget _row(String k, String v, {bool isBold = false, Color? valueColor, double? fontSize}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k),
        Text(
          v,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
            fontSize: fontSize,
          ),
        ),
      ],
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
              ? const Padding(
            padding: EdgeInsets.all(10.0),
            child: SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
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

  void _openVoucherBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        if (_loadingPromotions) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
        if (_promotions.isEmpty) {
          return const SizedBox(height: 200, child: Center(child: Text('Chưa có voucher khả dụng')));
        }
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 8),
                const Text('Chọn voucher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: _promotions.length,
                    itemBuilder: (_, i) {
                      final p = _promotions[i];
                      final selected = _selectedPromotion?.promotionCode == p.promotionCode;
                      final typeText = (p.promotionTypeCode == 'PT_01')
                          ? '${(p.value * 100).toStringAsFixed(0)}%'
                          : '${p.value.toStringAsFixed(0)}đ';

                      return ListTile(
                        leading: const Icon(Icons.card_giftcard),
                        title: Text('${p.promotionCode} • $typeText'),
                        subtitle: Text(p.promotionName),
                        trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
                        onTap: () {
                          setState(() => _selectedPromotion = p);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }
}
