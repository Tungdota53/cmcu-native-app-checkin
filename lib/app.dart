import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/models.dart';
import 'core/app_preferences.dart';
import 'core/app_brand.dart';
import 'core/portal_api.dart';
import 'core/session_store.dart';
import 'core/web_session.dart';
import 'core/widget_bridge.dart';
import 'features/login/login_screen.dart';
import 'features/schedule/schedule_controller.dart';
import 'features/schedule/schedule_screen.dart';
import 'theme/app_theme.dart';

class CmcCheckinApp extends StatefulWidget {
  const CmcCheckinApp({super.key, this.initialSession});
  final Session? initialSession;

  @override
  State<CmcCheckinApp> createState() => _CmcCheckinAppState();
}

class _CmcCheckinAppState extends State<CmcCheckinApp> {
  final _preferences = AppPreferences();
  @override
  void initState() {
    super.initState();
    _preferences.load();
  }

  @override
  void dispose() {
    _preferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _preferences,
      builder: (context, _) => MaterialApp(
        title: AppBrand.name,
        debugShowCheckedModeBanner: false,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: _preferences.themeMode,
        themeAnimationDuration: _preferences.reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 240),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                _preferences.reduceMotion ||
                MediaQuery.disableAnimationsOf(context),
          ),
          child: child!,
        ),
        home: AuthGate(
          initialSession: widget.initialSession,
          preferences: _preferences,
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.initialSession, this.preferences});
  final Session? initialSession;
  final AppPreferences? preferences;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  ScheduleController? _controller;
  bool _checkInRequested = false;
  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    if (_session != null) _buildController(_session!);
    _listenDeepLinks();
  }

  @override
  void dispose() {
    _links?.cancel();
    _controller?.api.close();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _listenDeepLinks() async {
    final links = AppLinks();
    final initial = await links.getInitialLink();
    if (!mounted) return;
    if (initial != null) _handle(initial);
    _links = links.uriLinkStream.listen(_handle);
  }

  void _handle(Uri uri) {
    if (!mounted) return;
    if (uri.scheme == 'cmccheckin' && uri.host == 'checkin') {
      setState(() => _checkInRequested = true);
    }
  }

  Future<void> _buildController(Session s) async {
    final ua = await WebSession.userAgent();
    if (!mounted || !identical(_session, s)) return;
    final api = PortalApi(
      session: s,
      userAgent: ua,
      cookieHeader: WebSession.cookieHeader,
    );
    final old = _controller;
    setState(() {
      _controller = ScheduleController(
        api: api,
        fallbackIp: s.portalIp,
        onCurrentWeekLoaded: (week, entries) => WidgetBridge.publish(
          signedIn: true,
          weekStart: week,
          entries: entries,
        ),
      );
    });
    old?.dispose();
    old?.api.close();
  }

  Future<void> _onSignedIn(Session s) async {
    await SessionStore.save(s);
    if (!mounted) return;
    setState(() => _session = s);
    await _buildController(s);
    await WidgetBridge.publish(signedIn: true);
  }

  Future<void> _onSessionExpired() async {
    await SessionStore.clear();
    if (!mounted) return;
    _controller?.api.close();
    _controller?.dispose();
    setState(() {
      _session = null;
      _controller = null;
    });
    await WidgetBridge.publish(signedIn: false);
  }

  Future<void> _onSignOut() async {
    await SessionStore.clear();
    await WidgetBridge.clear();
    await WebSession.clearAll();
    if (!mounted) return;
    _controller?.api.close();
    _controller?.dispose();
    setState(() {
      _session = null;
      _controller = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_session == null) {
      return LoginScreen(onSignedIn: _onSignedIn);
    }
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ScheduleScreen(
      key: ValueKey(_session!.token),
      controller: controller,
      preferences: widget.preferences,
      checkInRequested: _checkInRequested,
      onCheckInRequestHandled: () => setState(() => _checkInRequested = false),
      onSignOut: _onSignOut,
      onSessionExpired: _onSessionExpired,
    );
  }
}
