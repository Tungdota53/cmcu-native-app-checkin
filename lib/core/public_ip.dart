import 'dart:convert';
import 'package:http/http.dart' as http;

/// Portal lấy `clientIP` từ jsonip.com; check-in báo cùng nguồn đó.
class PublicIp {
  PublicIp._();

  static Future<String?> lookup() async {
    try {
      final res = await http
          .get(Uri.parse('https://jsonip.com'))
          .timeout(const Duration(seconds: 10));
      final obj = jsonDecode(res.body);
      if (obj is Map && obj['ip'] is String) {
        final ip = (obj['ip'] as String).trim();
        return ip.isEmpty ? null : ip;
      }
    } catch (_) {}
    return null;
  }
}
