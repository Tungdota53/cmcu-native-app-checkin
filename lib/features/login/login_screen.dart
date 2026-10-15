import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models.dart';
import '../../core/portal_api.dart' show portalOrigin;

const _loginUrl = '$portalOrigin/congthongtin/login.aspx';
const _probeInterval = Duration(milliseconds: 700);
const _menuWaitProbes = 15;

const _probeJs = r'''
(function () {
  try {
    var s = (typeof edu !== 'undefined' && edu) ? edu.system : null;
    if (!s || !s.tokenJWT || !s.userId) return null;
    var list = s.dtChucNang || [], match = null, grades = null;
    for (var i = 0; i < list.length; i++) {
      var file = String(list[i].DUONGDANFILE || '').toLowerCase();
      var name = String(list[i].TENCHUCNANG || '').toLowerCase();
      if (file.indexOf('lichgiang') >= 0 || file.indexOf('lichhoc') >= 0 || name.indexOf('lịch cá nhân') >= 0) match = list[i].ID;
      if (file.indexOf('diemhoc') >= 0 || name.indexOf('điểm học') >= 0 || name.indexOf('kết quả học tập') >= 0) grades = list[i].ID;
    }
    return JSON.stringify({
      token: s.tokenJWT, userId: s.userId, clientIP: s.clientIP || '',
      chucNangId: match == null ? null : String(match),
      gradesChucNangId: grades == null ? '' : String(grades),
      currentChucNangId: s.strChucNang_Id || '', menuLoaded: list.length > 0
    });
  } catch (e) { return null; }
})();
''';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onSignedIn});
  final void Function(Session session) onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  InAppWebViewController? _web;
  double _progress = 0;
  bool _canGoBack = false;
  Timer? _timer;
  bool _done = false;
  bool _probing = false;
  int _probesWithToken = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startProbe() {
    _timer?.cancel();
    _timer = Timer.periodic(_probeInterval, (_) => _probe());
  }

  Future<void> _probe() async {
    final web = _web;
    if (_done || _probing || web == null || !mounted) return;
    _probing = true;
    try {
      final uri = await web.getUrl();
      if (uri?.host != 'iu.cmcu.edu.vn' || uri?.scheme != 'https') return;
      final raw = await web.evaluateJavascript(source: _probeJs);
      if (raw is! String || _done) return;
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final token = obj['token'] as String?;
      final userId = obj['userId'] as String?;
      if (token == null || token.isEmpty || userId == null || userId.isEmpty)
        return;
      final chucNangId = obj['chucNangId'] as String?;
      final menuLoaded = obj['menuLoaded'] == true;
      final gradesId = obj['gradesChucNangId'] as String? ?? '';
      if ((menuLoaded && chucNangId != null && gradesId.isNotEmpty) ||
          _probesWithToken >= _menuWaitProbes) {
        _done = true;
        _timer?.cancel();
        widget.onSignedIn(
          Session(
            token: token,
            userId: userId,
            chucNangId:
                chucNangId ?? (obj['currentChucNangId'] as String? ?? ''),
            portalIp: obj['clientIP'] as String? ?? '',
            gradesChucNangId: gradesId,
          ),
        );
      } else {
        _probesWithToken++;
      }
    } catch (_) {
      // Trang đang chuyển hướng / chưa có `edu` → thử lại ở nhịp sau.
    } finally {
      _probing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _canGoBack) _web?.goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đăng nhập tài khoản trường'),
          bottom: _progress < 1
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 3,
                  ),
                )
              : null,
        ),
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_loginUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            thirdPartyCookiesEnabled: true,
            javaScriptCanOpenWindowsAutomatically: true,
            supportMultipleWindows: false,
            allowsBackForwardNavigationGestures: true,
            useShouldOverrideUrlLoading: true,
          ),
          onWebViewCreated: (c) {
            _web = c;
            _startProbe();
          },
          onProgressChanged: (_, p) => setState(() => _progress = p / 100),
          onUpdateVisitedHistory: (c, _, __) async {
            final can = await c.canGoBack();
            if (mounted && can != _canGoBack) setState(() => _canGoBack = can);
          },
          shouldOverrideUrlLoading: (c, action) async {
            final uri = action.request.url;
            final scheme = uri?.scheme.toLowerCase();
            if (uri == null ||
                const {
                  'http',
                  'https',
                  'about',
                  'data',
                  'blob',
                }.contains(scheme)) {
              return NavigationActionPolicy.ALLOW;
            }
            try {
              await launchUrl(
                Uri.parse(uri.toString()),
                mode: LaunchMode.externalApplication,
              );
            } catch (_) {}
            return NavigationActionPolicy.CANCEL;
          },
        ),
      ),
    );
  }
}
