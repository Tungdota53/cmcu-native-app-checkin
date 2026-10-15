import 'package:cmc_checkin/core/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'Persists theme, compact layout and reduced motion across launches',
    () async {
      final preferences = AppPreferences();
      addTearDown(preferences.dispose);
      expect(
        await preferences.update(
          theme: ThemeMode.dark,
          compact: true,
          motion: true,
        ),
        isTrue,
      );
      final restored = AppPreferences();
      addTearDown(restored.dispose);
      await restored.load();
      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.compactSchedule, isTrue);
      expect(restored.reduceMotion, isTrue);
      final store = await SharedPreferences.getInstance();
      expect(store.getKeys(), {
        'appearance.theme',
        'appearance.compact',
        'appearance.reduceMotion',
      });
    },
  );
  test(
    'Ignores unknown theme values and does not overwrite edits made during load',
    () async {
      SharedPreferences.setMockInitialValues({'appearance.theme': 'invalid'});
      final p = AppPreferences();
      addTearDown(p.dispose);
      await p.load();
      expect(p.themeMode, ThemeMode.system);
      final load = p.load();
      final update = p.update(theme: ThemeMode.light);
      await load;
      await update;
      expect(p.themeMode, ThemeMode.light);
    },
  );
}
