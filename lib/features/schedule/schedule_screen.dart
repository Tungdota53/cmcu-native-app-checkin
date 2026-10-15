import 'package:flutter/material.dart';
import '../../theme/formatters.dart';
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

class _ScheduleScreenState extends State<ScheduleScreen> with WidgetsBindingObserver {
  bool _sheetOpen = false;
  bool _expiredHandled = false;
  ScheduleController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    }
    _handleRequest();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    c.removeListener(_onChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) c.offerCurrentClass();
  }

  void _handleRequest() {
    if (widget.checkInRequested) {
      c.checkInNow();
      widget.onCheckInRequestHandled();
    }
  }

  void _onChange() {
    if (!mounted) return;
    if (c.sessionExpired && !_expiredHandled) {
      _expiredHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onSessionExpired());
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
    if (c.checkIn != null && !_sheetOpen) {
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Schedule'),
              Text(weekLabel(c.weekStart),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
          actions: [
            IconButton(
                onPressed: c.goToToday,
                tooltip: 'Today',
                icon: const Icon(Icons.today_outlined)),
            IconButton(
                onPressed: widget.onSignOut,
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout)),
          ],
        ),
        body: Column(
          children: [
            WeekStrip(controller: c),
            Expanded(
              child: RefreshIndicator(
                onRefresh: c.refresh,
                child: _DayList(controller: c),
              ),
            ),
          ],
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
        Text(dayTitle(c.selectedDay),
            style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        if (c.error != null) ...[
          Card(
            color: scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.error!, style: TextStyle(color: scheme.onErrorContainer)),
                  TextButton(onPressed: c.refresh, child: const Text('Try again')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (entries.isEmpty && !c.loading && c.error == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('No classes this day.',
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
          ),
        for (final e in entries) ...[
          EntryCard(entry: e, onTap: () => c.openCheckIn(e)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
