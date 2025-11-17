// lib/config/payment_config.dart
/// NHẬP THÔNG TIN NGÂN HÀNG CỦA BẠN Ở ĐÂY (theo VietQR/NAPAS)
class PaymentConfig {
  /// BIN của ngân hàng (VD: Vietcombank = 970436, MB = 970422,…)
  static String bankBin = '970436';

  /// Số tài khoản nhận tiền
  static String accountNo = '1031760236';

  /// Tên chủ tài khoản (in hoa có dấu/không dấu đều được)
  static String accountName = 'NGUYEN KHAC TRIEU';

  /// Cập nhật runtime (ví dụ sau khi user đổi trong phần cài đặt)
  static void update({
    String? bankBin_,
    String? accountNo_,
    String? accountName_,
  }) {
    if (bankBin_ != null && bankBin_.isNotEmpty) bankBin = bankBin_;
    if (accountNo_ != null && accountNo_.isNotEmpty) accountNo = accountNo_;
    if (accountName_ != null && accountName_.isNotEmpty) accountName = accountName_;
  }
}
