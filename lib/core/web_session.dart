import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebSession {
  WebSession._();
  static String? _ua;

  /// UA mặc định của WebView (cùng UA dùng lúc đăng nhập).
  static Future<String> userAgent() async {
    if (_ua != null) return _ua!;
    try {
      _ua = await InAppWebViewController.getDefaultUserAgent();
    } catch (_) {}
    return _ua ??= 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36';
  }

  /// Header `Cookie` từ store của WebView (gồm cả cookie HttpOnly) cho [url].
  static Future<String?> cookieHeader(Uri url) async {
    final cookies = await CookieManager.instance().getCookies(url: WebUri.uri(url));
    if (cookies.isEmpty) return null;
    return cookies.map((c) => '${c.name}=${c.value}').join('; ');
  }

  /// Đăng xuất hẳn: xóa cookie + toàn bộ website data.
  static Future<void> clearAll() async {
    await CookieManager.instance().deleteAllCookies();
    await InAppWebViewController.clearAllCache();
    try {
      await WebStorageManager.instance().deleteAllData();
    } catch (_) {/* chỉ Android hỗ trợ đầy đủ */}
  }
}
