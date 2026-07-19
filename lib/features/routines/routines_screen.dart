import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/i18n.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/nd_colors.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import '../calendar/calendar_state.dart';
import '../shared/empty_state.dart';
import 'streaks.dart';

/// Rutinler (alışkanlık takibi) ekranı. Kullanıcı başında onay kutusu olan
/// rutinler tanımlar; işaretler her gün (ya da seçilen günlerde) yenilenir.
/// Bir rutine dokununca geçmişi aylık takvim üzerinde görünür.
class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final routines = ref.watch(routinesProvider).valueOrNull ?? const [];
    final checks = ref.watch(routineChecksProvider).valueOrNull ?? const [];

    final today = dayOnly(DateTime.now());
    final todayIndex = today.weekday - 1; // Pzt=0..Paz=6
    final streaksEnabled = ref.watch(streaksEnabledProvider);

    // Bugün işaretli rutin id'leri.
    final doneToday = <int>{
      for (final c in checks)
        if (sameDay(c.day, today)) c.routineId,
    };

    // Her rutinin tüm işaretli günleri (seri/rozet + tile için).
    final checkedByRoutine = <int, Set<DateTime>>{};
    for (final c in checks) {
      (checkedByRoutine[c.routineId] ??= <DateTime>{}).add(dayOnly(c.day));
    }

    final scheduledToday = <Routine>[
      for (final r in routines)
        if (_isScheduled(r.days, todayIndex)) r,
    ];
    final others = <Routine>[
      for (final r in routines)
        if (!_isScheduled(r.days, todayIndex)) r,
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: routines.isEmpty
            ? Column(
                children: [
                  const SizedBox(height: 16),
                  _CreateButton(onTap: () => _showCreateSheet(context, ref)),
                  Expanded(
                    child: EmptyState(
                      icon: Icons.repeat,
                      title: context.t('Henüz rutin yok', 'No routines yet'),
                      subtitle: context.t(
                          'Su içmek, kitap okumak, spor… Takip etmek '
                              'istediğin alışkanlıkları ekle.',
                          'Drink water, read, exercise… Add the habits '
                              'you want to track.'),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                children: [
                  _CreateButton(onTap: () => _showCreateSheet(context, ref)),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(context.t('Bugün', 'Today'),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 10),
                  if (scheduledToday.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                            context.t('Bugüne rutin yok',
                                'No routines for today'),
                            style:
                                TextStyle(fontSize: 14, color: nd.text2)),
                      ),
                    )
                  else
                    for (final r in scheduledToday)
                      _RoutineTile(
                        routine: r,
                        done: doneToday.contains(r.id),
                        checkable: true,
                        checkedDays:
                            checkedByRoutine[r.id] ?? const <DateTime>{},
                        streaksEnabled: streaksEnabled,
                      ),
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(context.t('Diğer günler', 'Other days'),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 10),
                    for (final r in others)
                      _RoutineTile(
                        routine: r,
                        done: false,
                        checkable: false,
                        checkedDays:
                            checkedByRoutine[r.id] ?? const <DateTime>{},
                        streaksEnabled: streaksEnabled,
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}

bool _isScheduled(String mask, int weekdayIndex) =>
    weekdayIndex >= 0 &&
    weekdayIndex < mask.length &&
    mask[weekdayIndex] == '1';

/// Rutinin tekrar günlerini kısa metne çevirir ('Her gün' / 'Pzt, Çar'…).
String _scheduleLabel(BuildContext context, String mask) {
  if (!mask.contains('0')) return context.t('Her gün', 'Every day');
  final names = context.isEn ? gunKisaEn : gunKisa;
  final parts = <String>[
    for (var i = 0; i < 7 && i < mask.length; i++)
      if (mask[i] == '1') names[i],
  ];
  return parts.isEmpty ? '—' : parts.join(', ');
}

// ─────────────────────────── Rutin satırı ───────────────────────────

class _RoutineTile extends ConsumerWidget {
  const _RoutineTile({
    required this.routine,
    required this.done,
    required this.checkable,
    required this.checkedDays,
    required this.streaksEnabled,
  });

  final Routine routine;
  final bool done;
  final bool checkable;
  final Set<DateTime> checkedDays;
  final bool streaksEnabled;

  String _fmtTime(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:'
      '${(m % 60).toString().padLeft(2, '0')}';

  Future<void> _pickReminder(BuildContext context, WidgetRef ref) async {
    final body = context.t('Rutin hatırlatıcısı', 'Routine reminder');
    final r = routine.remindAt;
    final initial = r != null
        ? TimeOfDay(hour: r ~/ 60, minute: r % 60)
        : const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    await ref
        .read(routineRepositoryProvider)
        .setRemindAt(id: routine.id, minutes: minutes);
    await NotificationService.instance.requestPermission();
    await NotificationService.instance.scheduleRoutine(
      routineId: routine.id,
      title: routine.title,
      body: body,
      days: routine.days,
      minuteOfDay: minutes,
    );
  }

  Future<void> _removeReminder(WidgetRef ref) async {
    await ref
        .read(routineRepositoryProvider)
        .setRemindAt(id: routine.id, minutes: null);
    await NotificationService.instance.cancelRoutine(routine.id);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('Silinsin mi?', 'Delete?')),
        content: Text(context.t(
            '"${routine.title}" rutini ve geçmişi kalıcı olarak silinecek.',
            '“${routine.title}” and its history will be permanently deleted.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.t('Vazgeç', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.t('Sil', 'Delete')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await NotificationService.instance.cancelRoutine(routine.id);
      await ref.read(routineRepositoryProvider).delete(routine.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final today = dayOnly(DateTime.now());
    final created = dayOnly(routine.createdAt);
    final streak = streaksEnabled
        ? currentStreak(routine.days, checkedDays, today, created)
        : 0;
    final hasReminder = routine.remindAt != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: nd.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: nd.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => _RoutineHistoryDialog(routine: routine),
        ),
        onLongPress: () => _confirmDelete(context, ref),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            children: [
              // Onay kutusu (bugün planlı değilse soluk ve pasif).
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 24,
                  color: checkable ? (done ? nd.text : nd.text2) : nd.border,
                ),
                onPressed: checkable
                    ? () async {
                        final wasDone = done;
                        await ref.read(routineRepositoryProvider).toggle(
                            routineId: routine.id, day: DateTime.now());
                        if (!wasDone && streaksEnabled && context.mounted) {
                          final projected = currentStreak(routine.days,
                              {...checkedDays, today}, today, created);
                          if (kBadgeThresholds.contains(projected)) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(context.t(
                                    '🔥 $projected günlük seri! Rozet kazandın 🏅',
                                    '🔥 $projected-day streak! Badge earned 🏅'))));
                          }
                        }
                      }
                    : null,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: checkable && done ? nd.text2 : nd.text,
                        decoration: checkable && done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _scheduleLabel(context, routine.days),
                      style: TextStyle(fontSize: 11.5, color: nd.text2),
                    ),
                  ],
                ),
              ),
              if (streak >= 2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text('🔥$streak',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              // Bildirim çanı: dokun → saat seç/değiştir, uzun bas → kaldır.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _pickReminder(context, ref),
                onLongPress: hasReminder ? () => _removeReminder(ref) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasReminder) ...[
                        Text(_fmtTime(routine.remindAt!),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: nd.text)),
                        const SizedBox(width: 3),
                      ],
                      Icon(
                        hasReminder
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                        size: 18,
                        color: hasReminder ? nd.text : nd.text2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Rutin oluştur ───────────────────────────

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return Material(
      color: nd.card,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: nd.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 18, color: nd.text),
              const SizedBox(width: 7),
              Text(context.t('Rutin oluştur', 'Create routine'),
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: nd.text)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showCreateSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: const _CreateSheet(),
    ),
  );
}

class _CreateSheet extends ConsumerStatefulWidget {
  const _CreateSheet();

  @override
  ConsumerState<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends ConsumerState<_CreateSheet> {
  final _controller = TextEditingController();
  // Pzt..Paz — varsayılan: her gün.
  final List<bool> _days = List.filled(7, true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid =>
      _controller.text.trim().isNotEmpty && _days.contains(true);

  Future<void> _save() async {
    if (!_valid) return;
    final mask = [for (final d in _days) d ? '1' : '0'].join();
    await ref
        .read(routineRepositoryProvider)
        .insert(title: _controller.text.trim(), days: mask);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final names = context.isEn ? gunKisaEn : gunKisa;
    final everyDay = !_days.contains(false);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: nd.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(context.t('Rutin oluştur', 'Create routine'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: nd.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: nd.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: context.t(
                      'Örn. 2 litre su iç', 'e.g. Drink 2 liters of water'),
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(context.t('Tekrar günleri', 'Repeat on'),
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: nd.text2)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _days[i] = !_days[i]),
                        child: Container(
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _days[i] ? nd.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                                color:
                                    _days[i] ? nd.accent : nd.border),
                          ),
                          child: Text(
                            names[i],
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _days[i] ? nd.accentFg : nd.text2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() {
                final target = !everyDay;
                for (var i = 0; i < 7; i++) {
                  _days[i] = target;
                }
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      everyDay
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                      color: nd.text2,
                    ),
                    const SizedBox(width: 6),
                    Text(context.t('Her gün', 'Every day'),
                        style:
                            TextStyle(fontSize: 12.5, color: nd.text2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _valid ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: nd.accent,
                  foregroundColor: nd.accentFg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(context.t('Oluştur', 'Create')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Geçmiş (takvim) ───────────────────────────

class _RoutineHistoryDialog extends ConsumerStatefulWidget {
  const _RoutineHistoryDialog({required this.routine});

  final Routine routine;

  @override
  ConsumerState<_RoutineHistoryDialog> createState() =>
      _RoutineHistoryDialogState();
}

class _RoutineHistoryDialogState
    extends ConsumerState<_RoutineHistoryDialog> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final r = widget.routine;
    final streaksEnabled = ref.watch(streaksEnabledProvider);
    final checks = ref.watch(routineChecksProvider).valueOrNull ?? const [];
    final checkedDays = <DateTime>{
      for (final c in checks)
        if (c.routineId == r.id) dayOnly(c.day),
    };

    final today = dayOnly(DateTime.now());
    final created = dayOnly(r.createdAt);
    final months = context.isEn ? aylarEn : aylar;
    final dayNames = context.isEn ? gunKisaEn : gunKisa;

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = DateTime(_month.year, _month.month, 1).weekday - 1;
    final totalCells = (((leading + daysInMonth) / 7).ceil()) * 7;

    // Ay istatistiği: planlı ve geçmiş/bugün olan günlerden kaçı yapıldı.
    var due = 0;
    var done = 0;
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_month.year, _month.month, d);
      if (date.isAfter(today) || date.isBefore(created)) continue;
      if (!_isScheduled(r.days, date.weekday - 1)) continue;
      due++;
      if (checkedDays.contains(date)) done++;
    }

    return Dialog(
      backgroundColor: nd.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: nd.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close, size: 18, color: nd.text2),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.chevron_left,
                        size: 20, color: nd.text2),
                    onPressed: () => setState(() => _month =
                        DateTime(_month.year, _month.month - 1, 1)),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${months[_month.month - 1]} ${_month.year}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.chevron_right,
                        size: 20, color: nd.text2),
                    onPressed: () => setState(() => _month =
                        DateTime(_month.year, _month.month + 1, 1)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final g in dayNames)
                    Expanded(
                      child: Center(
                        child: Text(g,
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: nd.text2)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < totalCells; i++)
                    Builder(builder: (context) {
                      final dayNum = i - leading + 1;
                      if (dayNum < 1 || dayNum > daysInMonth) {
                        return const SizedBox.shrink();
                      }
                      final date =
                          DateTime(_month.year, _month.month, dayNum);
                      final scheduled =
                          _isScheduled(r.days, date.weekday - 1);
                      final inRange =
                          !date.isAfter(today) && !date.isBefore(created);
                      final checked = checkedDays.contains(date);

                      return _HistoryCell(
                        day: dayNum,
                        scheduled: scheduled,
                        inRange: inRange,
                        checked: checked,
                        isToday: sameDay(date, today),
                        // Geçmiş/bugünkü planlı günler dokunarak düzeltilebilir.
                        onTap: scheduled && inRange
                            ? () => ref
                                .read(routineRepositoryProvider)
                                .toggle(routineId: r.id, day: date)
                            : null,
                      );
                    }),
                ],
              ),
              if (streaksEnabled) ...[
                const SizedBox(height: 12),
                _BadgeShelf(
                    longest:
                        longestStreak(r.days, checkedDays, today, created)),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(color: nd.accent, filled: true),
                  const SizedBox(width: 5),
                  Text(context.t('Yapıldı', 'Done'),
                      style: TextStyle(fontSize: 11.5, color: nd.text2)),
                  const SizedBox(width: 14),
                  _LegendDot(color: nd.text2, filled: false),
                  const SizedBox(width: 5),
                  Text(context.t('Yapılmadı', 'Missed'),
                      style: TextStyle(fontSize: 11.5, color: nd.text2)),
                  const Spacer(),
                  Text(
                    due == 0
                        ? context.t('Bu ay kayıt yok', 'No records this month')
                        : context.t('Bu ay: $done/$due',
                            'This month: $done/$due'),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: nd.text),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCell extends StatelessWidget {
  const _HistoryCell({
    required this.day,
    required this.scheduled,
    required this.inRange,
    required this.checked,
    required this.isToday,
    this.onTap,
  });

  final int day;
  final bool scheduled;
  final bool inRange;
  final bool checked;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;

    Widget child;
    if (scheduled && inRange && checked) {
      // Yapıldı → dolu vurgu.
      child = Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: nd.accent, shape: BoxShape.circle),
        child: Icon(Icons.check, size: 15, color: nd.accentFg),
      );
    } else if (scheduled && inRange) {
      // Planlıydı ama yapılmadı → ince halka.
      child = Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: nd.borderStrong, width: 1.5),
        ),
        child: Text('$day',
            style: TextStyle(fontSize: 11.5, color: nd.text2)),
      );
    } else {
      // Planlı değil ya da aralık dışı → soluk sayı.
      child = Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: isToday
            ? BoxDecoration(color: nd.hover, shape: BoxShape.circle)
            : null,
        child: Text('$day',
            style: TextStyle(
                fontSize: 11.5,
                color: scheduled ? nd.text2 : nd.border)),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(child: child),
    );
  }
}

class _BadgeShelf extends StatelessWidget {
  const _BadgeShelf({required this.longest});

  final int longest;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in kBadgeThresholds)
          _BadgePill(threshold: t, earned: longest >= t),
      ],
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.threshold, required this.earned});

  final int threshold;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: earned ? nd.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: earned ? nd.accent : nd.border),
      ),
      child: Text(
        earned ? '🏅 $threshold' : '🔒 $threshold',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: earned ? nd.accentFg : nd.text2,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: filled ? null : Border.all(color: color, width: 1.5),
      ),
    );
  }
}
