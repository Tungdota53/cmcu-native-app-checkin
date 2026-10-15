import 'dart:convert';

/// Port của `AE`/`AD` trong crypto-js.js của portal: XOR lặp khóa trên từng
/// UTF-16 code unit (đúng với `String.codeUnits` của Dart), truyền dưới dạng
/// Base64 của UTF-8.
class PortalCrypto {
  PortalCrypto._();

  /// `edu.system.iM` — hard-code trong portal, cũng là khóa giải mã response.
  static const String im = 'AzzSystem';

  static String encrypt(String plain, String key) =>
      base64.encode(utf8.encode(_xor(plain, key)));

  /// Ném [FormatException] nếu Base64/UTF-8 hỏng.
  static String decrypt(String encoded, String key) {
    final clean = encoded.replaceAll(RegExp(r'\s'), '');
    return _xor(utf8.decode(base64.decode(base64.normalize(clean))), key);
  }

  static String _xor(String text, String key) {
    final k = key.codeUnits;
    if (k.isEmpty) return text;
    final u = text.codeUnits;
    return String.fromCharCodes(
        [for (var i = 0; i < u.length; i++) u[i] ^ k[i % k.length]]);
  }
}
