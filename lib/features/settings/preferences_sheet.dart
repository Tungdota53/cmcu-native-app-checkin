import 'package:flutter/material.dart';
import '../../core/app_preferences.dart';

class PreferencesSheet extends StatelessWidget {
  const PreferencesSheet({
    super.key,
    required this.preferences,
    required this.onSignOut,
  });
  final AppPreferences preferences;
  final VoidCallback onSignOut;

  Future<void> _save(BuildContext context, Future<bool> result) async {
    if (!await result && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã áp dụng cho phiên này, chưa lưu được cài đặt trên thiết bị.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: preferences,
    builder: (context, _) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Theo cách của bạn',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text('Tùy chỉnh giao diện và trải nghiệm học tập.'),
            const SizedBox(height: 24),
            Text('GIAO DIỆN', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mode in ThemeMode.values)
                  ChoiceChip(
                    avatar: Icon(switch (mode) {
                      ThemeMode.system => Icons.brightness_auto_outlined,
                      ThemeMode.light => Icons.light_mode_outlined,
                      ThemeMode.dark => Icons.dark_mode_outlined,
                    }, size: 18),
                    label: Text(switch (mode) {
                      ThemeMode.system => 'Hệ thống',
                      ThemeMode.light => 'Sáng',
                      ThemeMode.dark => 'Tối',
                    }),
                    selected: preferences.themeMode == mode,
                    onSelected: (_) =>
                        _save(context, preferences.update(theme: mode)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lịch học gọn hơn'),
              subtitle: const Text('Ẩn thông tin phụ trên thẻ buổi học.'),
              value: preferences.compactSchedule,
              onChanged: (value) =>
                  _save(context, preferences.update(compact: value)),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Giảm chuyển động'),
              subtitle: const Text(
                'Hiển thị ngay, hạn chế hiệu ứng chuyển cảnh.',
              ),
              value: preferences.reduceMotion,
              onChanged: (value) =>
                  _save(context, preferences.update(motion: value)),
            ),
            const Divider(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Đăng xuất'),
              subtitle: const Text('Xóa phiên đăng nhập trên thiết bị này.'),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Đăng xuất tài khoản?'),
                    content: const Text(
                      'Bạn cần đăng nhập lại để xem lịch học và điểm.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Ở lại'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  Navigator.pop(context);
                  onSignOut();
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}
