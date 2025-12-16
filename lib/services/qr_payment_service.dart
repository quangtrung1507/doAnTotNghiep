import 'package:flutter/foundation.dart';
import '../config/payment_config.dart';

class QrPaymentService {
  /// Build URL ảnh QR Sepay (qr.sepay.vn)
  /// - amount: số tiền
  /// - orderCode: nội dung chuyển khoản (bắt buộc có ORD... để backend match)
  static Uri buildSepayQrImageUrl({
    required int amount,
    required String orderCode,
  }) {
    final bank = PaymentConfig.bank;
    final acc = PaymentConfig.acc;
    final template = PaymentConfig.template;

    final v = DateTime.now().millisecondsSinceEpoch; // tránh cache

    final url =
        'https://qr.sepay.vn/img'
        '?acc=${Uri.encodeQueryComponent(acc)}'
        '&bank=${Uri.encodeQueryComponent(bank)}'
        '&amount=$amount'
        '&des=${Uri.encodeQueryComponent(orderCode)}'
        '&template=${Uri.encodeQueryComponent(template)}'
        '&v=$v';

    if (kDebugMode) debugPrint('[SEPAY_QR] $url');
    return Uri.parse(url);
  }
}
