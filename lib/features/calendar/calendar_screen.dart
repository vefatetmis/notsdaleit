import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import '../../core/i18n/i18n.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/nd_colors.dart';
import '../../data/data_providers.dart';
import '../../data/database/database.dart';
import 'calendar_state.dart';

/// Takvim + yapılacaklar ekranı. Aylık ızgara; bir güne dokununca o günün
/// görevleri altta listelenir ve eklenebilir.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _addTask() {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;
    final day = ref.read(selectedDayProvider);
    ref.read(taskRepositoryProvider).insert(title: title, dueDate: day);
    _taskController.clear();
  }

  Future<void> _testNotification() async {
    final granted = await NotificationService.instance.requestPermission();
    if (granted) {
      await NotificationService.instance.showTest();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.t(
              'Bildirim izni kapalı. Ayarlar\'dan izin verin.',
              'Notifications are off. Enable them in Settings.'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final month = ref.watch(visibleMonthProvider);
    final selected = ref.watch(selectedDayProvider);
    final tasks = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];

    final taskDays = <DateTime>{
      for (final t in tasks)
        if (t.dueDate != null) dayOnly(t.dueDate!),
    };
    final dayTasks = [
      for (final t in tasks)
        if (t.dueDate != null && sameDay(t.dueDate!, selected)) t,
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
          children: [
            _CalendarCard(
              month: month,
              selected: selected,
              taskDays: taskDays,
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dayLabel(context, selected),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _testNotification,
                    icon: Icon(Icons.notifications_active_outlined,
                        size: 16, color: nd.text2),
                    label: Text(context.t('Bildirimi sına', 'Test notification'),
                        style: TextStyle(fontSize: 12.5, color: nd.text2)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Görev ekleme
            Container(
              decoration: BoxDecoration(
                color: nd.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: nd.border),
              ),
              padding: const EdgeInsets.only(left: 14, right: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _addTask(),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: context.t('Görev ekle…', 'Add task…'),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    color: nd.text,
                    onPressed: _addTask,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (dayTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                      context.t('Bu güne görev yok', 'No tasks for this day'),
                      style: TextStyle(fontSize: 14, color: nd.text2)),
                ),
              )
            else
              for (final t in dayTasks) _TaskTile(task: t),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(context.t('Gün notu', 'Day note'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            _DayNoteField(key: ValueKey(selected), day: selected),
          ],
        ),
      ),
    );
  }

  String _dayLabel(BuildContext context, DateTime d) {
    final now = DateTime.now();
    if (sameDay(d, now)) return context.t('Bugün', 'Today');
    if (sameDay(d, now.add(const Duration(days: 1)))) {
      return context.t('Yarın', 'Tomorrow');
    }
    final months = context.isEn ? aylarEn : aylar;
    return context.isEn
        ? '${months[d.month - 1]} ${d.day}, ${d.year}'
        : '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _CalendarCard extends ConsumerWidget {
  const _CalendarCard({
    required this.month,
    required this.selected,
    required this.taskDays,
  });

  final DateTime month;
  final DateTime selected;
  final Set<DateTime> taskDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final today = dayOnly(DateTime.now());

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = DateTime(month.year, month.month, 1).weekday - 1; // Pzt=0
    final totalCells = (((leading + daysInMonth) / 7).ceil()) * 7;

    void changeMonth(int delta) {
      ref.read(visibleMonthProvider.notifier).state =
          DateTime(month.year, month.month + delta, 1);
    }

    return Container(
      decoration: BoxDecoration(
        color: nd.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: nd.border),
        boxShadow: nd.shadow,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        children: [
          // Başlık
          Row(
            children: [
              _RoundBtn(
                icon: Icons.chevron_left,
                onTap: () => changeMonth(-1),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${(context.isEn ? aylarEn : aylar)[month.month - 1]} ${month.year}',
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              _RoundBtn(
                icon: Icons.chevron_right,
                onTap: () => changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Gün başlıkları
          Row(
            children: [
              for (final g in (context.isEn ? gunKisaEn : gunKisa))
                Expanded(
                  child: Center(
                    child: Text(g,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: nd.text2)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Günler ızgarası
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
                  final date = DateTime(month.year, month.month, dayNum);
                  final isSelected = sameDay(date, selected);
                  final isToday = sameDay(date, today);
                  final hasTask = taskDays.contains(date);
                  return _DayCell(
                    day: dayNum,
                    isSelected: isSelected,
                    isToday: isToday,
                    hasTask: hasTask,
                    onTap: () =>
                        ref.read(selectedDayProvider.notifier).state = date,
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.hasTask,
    required this.onTap,
  });

  final int day;
  final bool isSelected;
  final bool isToday;
  final bool hasTask;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final fg = isSelected
        ? nd.accentFg
        : (isToday ? nd.accent : nd.text);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? nd.accent
                : (isToday ? nd.hover : Colors.transparent),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight:
                      isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
              if (hasTask)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? nd.accentFg : nd.accent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: nd.text2),
        ),
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});

  final Task task;

  static String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _toggleDone(WidgetRef ref) async {
    final newDone = !task.done;
    await ref.read(taskRepositoryProvider).setDone(id: task.id, done: newDone);
    if (newDone) {
      await NotificationService.instance.cancel(task.id);
    } else if (task.remindAt != null) {
      await NotificationService.instance
          .schedule(id: task.id, title: task.title, when: task.remindAt!);
    }
  }

  Future<void> _pickReminder(BuildContext context, WidgetRef ref) async {
    final base = task.dueDate ?? DateTime.now();
    final initial = task.remindAt != null
        ? TimeOfDay.fromDateTime(task.remindAt!)
        : TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final when =
        DateTime(base.year, base.month, base.day, picked.hour, picked.minute);
    await ref.read(taskRepositoryProvider).update(
          id: task.id,
          title: task.title,
          dueDate: task.dueDate,
          remindAt: when,
        );
    await NotificationService.instance.requestPermission();
    if (!task.done) {
      await NotificationService.instance
          .schedule(id: task.id, title: task.title, when: when);
    }
  }

  Future<void> _clearReminder(WidgetRef ref) async {
    await ref.read(taskRepositoryProvider).update(
          id: task.id,
          title: task.title,
          dueDate: task.dueDate,
          remindAt: null,
        );
    await NotificationService.instance.cancel(task.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nd = context.nd;
    final hasReminder = task.remindAt != null;
    final timeStr = hasReminder
        ? '${_two(task.remindAt!.hour)}:${_two(task.remindAt!.minute)}'
        : null;

    return Dismissible(
      key: ValueKey('task_${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        NotificationService.instance.cancel(task.id);
        ref.read(taskRepositoryProvider).delete(task.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: nd.text.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: nd.text2),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: nd.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: nd.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleDone(ref),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
            child: Row(
              children: [
                Icon(
                  task.done
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 22,
                  color: task.done ? nd.text : nd.text2,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: task.done ? nd.text2 : nd.text,
                      decoration:
                          task.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _pickReminder(context, ref),
                  onLongPress: hasReminder ? () => _clearReminder(ref) : null,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (timeStr != null) ...[
                          Text(timeStr,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: nd.text)),
                          const SizedBox(width: 5),
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
      ),
    );
  }
}

/// Seçili güne ait serbest not alanı (otomatik kaydeder).
class _DayNoteField extends ConsumerStatefulWidget {
  const _DayNoteField({super.key, required this.day});

  final DateTime day;

  @override
  ConsumerState<_DayNoteField> createState() => _DayNoteFieldState();
}

class _DayNoteFieldState extends ConsumerState<_DayNoteField> {
  late final TextEditingController _controller;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    final notes = ref.read(dayNotesProvider).valueOrNull ?? const [];
    String body = '';
    for (final n in notes) {
      if (sameDay(n.day, widget.day)) {
        body = n.body;
        break;
      }
    }
    _controller = TextEditingController(text: body);
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _save);
  }

  void _save() {
    ref.read(dayNoteRepositoryProvider).setForDay(widget.day, _controller.text);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _save();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    return Container(
      decoration: BoxDecoration(
        color: nd.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: nd.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: _controller,
        onChanged: (_) => _scheduleSave(),
        textCapitalization: TextCapitalization.sentences,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        minLines: 3,
        style: const TextStyle(fontSize: 14.5, height: 1.45),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: context.t(
              'Bu güne dair notunu yaz…', 'Write your note for this day…'),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
