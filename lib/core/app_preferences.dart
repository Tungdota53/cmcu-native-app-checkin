import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  bool compactSchedule = false;
  bool reduceMotion = false;
  bool _disposed = false;
  int _revision = 0;

  Future<void> load() async {
    final revision = _revision;
    try {
      final store = await SharedPreferences.getInstance();
      if (_disposed || revision != _revision) return;
      final theme = store.getString('appearance.theme');
      themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == theme,
        orElse: () => ThemeMode.system,
      );
      compactSchedule = store.getBool('appearance.compact') ?? false;
      reduceMotion = store.getBool('appearance.reduceMotion') ?? false;
      notifyListeners();
    } catch (_) {
      /* Dùng cài đặt mặc định khi bộ nhớ tùy chọn chưa sẵn sàng. */
    }
  }

  Future<bool> update({ThemeMode? theme, bool? compact, bool? motion}) async {
    _revision++;
    themeMode = theme ?? themeMode;
    compactSchedule = compact ?? compactSchedule;
    reduceMotion = motion ?? reduceMotion;
    if (!_disposed) notifyListeners();
    try {
      final store = await SharedPreferences.getInstance();
      final results = await Future.wait([
        store.setString('appearance.theme', themeMode.name),
        store.setBool('appearance.compact', compactSchedule),
        store.setBool('appearance.reduceMotion', reduceMotion),
      ]);
      return results.every((saved) => saved);
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
