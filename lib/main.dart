import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/session_store.dart';
import 'core/widget_bridge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await WidgetBridge.init();
  final session = await SessionStore.load();
  runApp(CmcCheckinApp(initialSession: session));
}
