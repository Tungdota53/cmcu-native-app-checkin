import 'package:flutter/material.dart';

import '../../theme/formatters.dart';
import '../grades/grades_controller.dart';
import '../grades/grades_screen.dart';
import 'check_in_sheet.dart';
import 'entry_card.dart';
import 'schedule_controller.dart';
import 'week_strip.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    super.key,
    required this.controller,
    required this.checkInRequested,
    required this.onCheckInRequestHandled,
    required this.onSignOut,
    required this.onSessionExpired,
  });

  final ScheduleController controller;
  final bool checkInRequested;
  final VoidCallback onCheckInRequestHandled;
  final VoidCallback onSignOut;
  final VoidCallback onSessionExpired;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with WidgetsBindingObserver {
  bool _sheetOpen = false;
  bool _expiredHandled = false;
  int _tab = 0;
  late GradesController _grades;
  ScheduleController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _grades = GradesController(c.api);
    c.addListener(_onChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.offerCurrentClass();
      _handleRequest();
    });
  }

  @override
  void didUpdateWidget(covariant ScheduleScreen old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _grades.dispose();
      _grades = GradesController(c.api);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleRequest();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    c.removeListener(_onChange);
    _grades.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _tab == 0) c.offerCurrentClass();
  }

  void _handleRequest() {
    if (widget.checkInRequested) {
      if (_tab != 0) setState(() => _tab = 0);
      c.checkInNow();
      widget.onCheckInRequestHandled();
    }
  }

  void _onChange() {
    if (!mounted) return;
    if (c.sessionExpired && !_expiredHandled) {
      _expiredHandled = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onSessionExpired(),
      );
    }
    final notice = c.notice;
    if (notice != null) {
      c.noticeShown();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(notice)));
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSheet());
  }

  void _syncSheet() {
    if (!mounted) return;
    if (c.checkIn != null && !_sheetOpen && _tab == 0) {
      _sheetOpen = true;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => CheckInSheet(controller: c),
      ).whenComplete(() {
        _sheetOpen = false;
        c.dismissCheckIn();
      });
    } else if (c.checkIn == null && _sheetOpen) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 24 + MediaQuery.textScalerOf(context).scale(44),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tab == 0 ? 'Lịch học' : 'Kết quả học tập',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                _tab == 0 ? weekLabel(c.weekStart) : 'CMC STUDENT',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            if (_tab == 0)
              IconButton(
                onPressed: c.goToToday,
                tooltip: 'Hôm nay',
                icon: const Icon(Icons.today_outlined),
              ),
            IconButton(
              onPressed: widget.onSignOut,
              tooltip: 'Đăng xuất',
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (value) {
            setState(() => _tab = value);
            if (value == 0)
              WidgetsBinding.instance.addPostFrameCallback((_) => _syncSheet());
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Lịch học',
            ),
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Kết quả',
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: _tab == 1
                  ? GradesScreen(
                      controller: _grades,
                      onSessionExpired: widget.onSessionExpired,
                    )
                  : Column(
                      children: [
                        WeekStrip(controller: c),
                        if (c.loading)
                          const LinearProgressIndicator(minHeight: 3),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: c.refresh,
                            child: _DayList(controller: c),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({required this.controller});
  final ScheduleController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final entries = c.dayEntries;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF172C65), Color(0xFF365BC4)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SẴN SÀNG CHO BUỔI HỌC',
                style: TextStyle(
                  color: Color(0xFFBDDAFF),
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                c.loading && entries.isEmpty
                    ? 'Đang cập nhật lịch…'
                    : '${entries.length} buổi học trong ngày',
                style: text.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Xem lịch, chọn lớp và nhập từ khóa điểm danh.',
                style: TextStyle(color: Color(0xFFE0E9FF)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          dayTitle(c.selectedDay),
          style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (c.error != null) ...[
          Card(
            color: scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.error!,
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                  TextButton(
                    onPressed: c.refresh,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (entries.isEmpty && !c.loading && c.error == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Không có lịch học trong ngày này.\nKéo xuống để cập nhật lịch mới nhất.',
              style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        for (final e in entries) ...[
          EntryCard(entry: e, onTap: () => c.openCheckIn(e)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
