/// THÔNG TIN SEPAY (GIỐNG WEB)
class PaymentConfig {
  // Bank hiển thị trên web (ví dụ: MBBank)
  static String bank = 'MBBank';

  // "acc" sepay (trên web bạn đang là VQROADYBO0539)
  static String acc = 'VQROADYBO0539';

  // template ảnh QR (compact/compact2 tuỳ bạn)
  static String template = 'compact';

  static void update({
    String? bank_,
    String? acc_,
    String? template_,
  }) {
    if (bank_ != null && bank_.isNotEmpty) bank = bank_;
    if (acc_ != null && acc_.isNotEmpty) acc = acc_;
    if (template_ != null && template_.isNotEmpty) template = template_;
  }
}
