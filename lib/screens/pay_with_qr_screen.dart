import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // ✅ THÊM: Clipboard

import '../config/payment_config.dart';
import '../services/api_service.dart';
import '../services/qr_payment_service.dart';
import '../utils/app_colors.dart';
import 'order_detail_screen.dart';

class PayWithQrScreen extends StatefulWidget {
  final String orderCode;
  final int amount;

  const PayWithQrScreen({
    super.key,
    required this.orderCode,
    required this.amount,
  });

  @override
  State<PayWithQrScreen> createState() => _PayWithQrScreenState();
}

class _PayWithQrScreenState extends State<PayWithQrScreen> {
  Timer? _pollTimer;
  Timer? _countdownTimer;

  bool _checking = false;
  bool _paid = false;
  bool _expired = false;

  static const int _timeoutSec = 10 * 60; // 10 phút
  int _remainSec = _timeoutSec;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ================= COPY HELPERS =================
  void _copyToClipboard(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã copy $label')),
    );
  }

  Widget _copyableInfoRow(String label, String value, {String? copyValue}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _copyToClipboard(label, copyValue ?? value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: SelectableText(
                      value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Copy',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () => _copyToClipboard(label, copyValue ?? value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // =================================================

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_paid || _expired) return;

      if (_remainSec <= 0) {
        setState(() => _expired = true);
        _pollTimer?.cancel();
        _countdownTimer?.cancel();

        // ✅ auto hủy đơn khi hết 10 phút
        try {
          await ApiService.cancelOrder(widget.orderCode);
        } catch (_) {}

        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hết thời gian thanh toán'),
            content: const Text('Đơn hàng quá 10 phút chưa thanh toán nên hệ thống đã hủy.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        if (mounted) Navigator.pop(context, false);
        return;
      }

      setState(() => _remainSec--);
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkPaid();
    });
    _checkPaid();
  }

  Future<void> _checkPaid() async {
    if (_checking || _paid || _expired) return;

    setState(() => _checking = true);
    try {
      final transfers = await ApiService.fetchTransfersByOrder(widget.orderCode);
      final hasPaid = transfers.isNotEmpty;

      if (hasPaid && mounted) {
        setState(() => _paid = true);
        _pollTimer?.cancel();
        _countdownTimer?.cancel();

        // ✅ vào hóa đơn
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderCode: widget.orderCode),
          ),
        );
      }
    } catch (_) {
      // im lặng, lần sau check tiếp
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  String _formatRemain() {
    final m = (_remainSec ~/ 60).toString().padLeft(2, '0');
    final s = (_remainSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final qrUri = QrPaymentService.buildSepayQrImageUrl(
      amount: widget.amount,
      orderCode: widget.orderCode, // bắt buộc chứa ORD...
    );

    final progress = 1 - (_remainSec / _timeoutSec);

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán Sepay')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              _expired
                  ? 'Đã hết thời gian thanh toán'
                  : _paid
                  ? 'Đã thanh toán ✅'
                  : 'Waiting for your transfer • Còn ${_formatRemain()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),

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

          // ✅ ĐỔI: row có thể copy (bấm dòng hoặc bấm icon)
          _copyableInfoRow('BANK', PaymentConfig.bank),
          _copyableInfoRow('ACCOUNT NUMBER', PaymentConfig.acc),
          _copyableInfoRow('TRANSFER CONTENT', widget.orderCode),
          _copyableInfoRow(
            'TOTAL PRICE',
            currency.format(widget.amount),
            copyValue: widget.amount.toString(), // ✅ copy số cho nhanh
          ),

          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: (_expired || _paid) ? null : _checkPaid,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _checking
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text('Tôi đã chuyển khoản xong (Kiểm tra)'),
          ),
        ],
      ),
    );
  }

  // (giữ lại nếu bạn còn chỗ khác dùng, không thì có thể xóa)
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
