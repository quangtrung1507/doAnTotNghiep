import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/payment_config.dart';
import '../services/qr_payment_service.dart';
import '../utils/app_colors.dart';

class PayWithQrScreen extends StatelessWidget {
  final String orderCode;
  final int amount; // số tiền tính sẵn (đã trừ voucher + cộng ship)

  const PayWithQrScreen({
    super.key,
    required this.orderCode,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final qrUri = QrPaymentService.buildVietQrImageUrl(
      amount: amount,
      orderCode: orderCode,
      template: 'compact2',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán QR')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Image.network(
                qrUri.toString(),
                width: 260,
                height: 260,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2, size: 200),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text('Ngân hàng: ${PaymentConfig.bankBin} • STK: ${PaymentConfig.accountNo}')),
          Center(child: Text('Chủ TK: ${PaymentConfig.accountName.toUpperCase()}')),
          const SizedBox(height: 8),
          Center(child: Text('Nội dung: Thanh toán đơn $orderCode')),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Số tiền: ${currency.format(amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Tôi đã chuyển khoản xong'),
            ),
          ),
        ],
      ),
    );
  }
}
