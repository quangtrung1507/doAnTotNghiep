import 'dart:io';
import 'package:flutter/foundation.dart';

import '../config/payment_config.dart';

class QrPaymentService {
  /// Dựng URL ảnh QR của VietQR (img.vietqr.io)
  ///
  /// - [amount]: số tiền (đ), ví dụ 105000
  /// - [orderCode]: mã đơn để đổ vào nội dung chuyển khoản (addInfo)
  /// - [template]: 'compact', 'compact2', 'qr_only'... (tùy thích)
  static Uri buildVietQrImageUrl({
    required int amount,
    required String orderCode,
    String template = 'compact2',
  }) {
    final bank = PaymentConfig.bankBin;   // một số bank dùng mã ngắn: vcb, mb, tpbank...
    final acct = PaymentConfig.accountNo;

    // Với img.vietqr.io, “bank” thường là mã ngắn (vcb, mb, tpbank,...)
    // Nếu bạn dùng BIN (970436) mà không ra ảnh, đổi bank = 'vcb'
    final bankId = _normalizeBankId(bank);

    final addInfo = 'Thanh toan don $orderCode';
    final nowTick = DateTime.now().millisecondsSinceEpoch.toString(); // tránh cache

    final url =
        'https://img.vietqr.io/image/$bankId-$acct-$template.jpg'
        '?amount=$amount'
        '&addInfo=${Uri.encodeComponent(addInfo)}'
        '&accountName=${Uri.encodeComponent(PaymentConfig.accountName)}'
        '&v=$nowTick';

    if (kDebugMode) {
      debugPrint('[QR] $url');
    }
    return Uri.parse(url);
  }

  /// Nếu bạn đang nhập BIN (970436) thì map thử sang mã viết tắt của VietQR
  static String _normalizeBankId(String input) {
    final s = input.trim().toLowerCase();
    // Map nhanh một vài bank phổ biến; thêm nếu cần
    const bin2Code = {
      '970436': 'vcb',   // Vietcombank
      '970422': 'mb',    // MB Bank
      '970407': 'vtb',   // VietinBank
      '970423': 'bidv',  // BIDV
    };
    const knownCodes = {'vcb','mb','vtb','bidv','tpbank','acb','techcombank','vib','vpbank','hdbank','shb','ocb','scb','agribank'};

    if (bin2Code.containsKey(s)) return bin2Code[s]!;
    if (knownCodes.contains(s)) return s;
    // fallback: cứ trả về input (trường hợp bạn đã truyền đúng code bank)
    return s;
  }
}
