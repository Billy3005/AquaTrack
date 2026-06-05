import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../data/reminder_slot.dart';
import '../logic/schedule_suggestion.dart';
import '../providers/reminder_provider.dart';

const _cyan = Color(0xFF38BDF8);

String _fmt(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

/// Pick a time using a dark-themed Material time picker.
Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) {
  return showTimePicker(
    context: context,
    initialTime: initial,
    builder: (context, child) => Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: _cyan,
          surface: AppColors.surface,
        ),
      ),
      child: child!,
    ),
  );
}

/// Add (existing == null) or edit a single Reminder Slot.
Future<void> showSlotEditSheet(
  BuildContext context,
  WidgetRef ref, {
  ReminderSlot? existing,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _SlotEditSheet(ref: ref, existing: existing),
  );
}

/// Generate a fresh schedule from a waking window.
Future<void> showSuggestionSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _SuggestionSheet(ref: ref),
  );
}

class _SheetShell extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SheetShell({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ToneSelector extends StatelessWidget {
  final ReminderTone value;
  final ValueChanged<ReminderTone> onChanged;
  const _ToneSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ReminderTone.values.map((tone) {
        final selected = tone == value;
        return GestureDetector(
          onTap: () => onChanged(tone),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? const Color(0x1F38BDF8) : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? _cyan : AppColors.textHint,
              ),
            ),
            child: Text(
              tone.label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFFBAE6FD)
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0EA5E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotEditSheet extends StatefulWidget {
  final WidgetRef ref;
  final ReminderSlot? existing;
  const _SlotEditSheet({required this.ref, this.existing});

  @override
  State<_SlotEditSheet> createState() => _SlotEditSheetState();
}

class _SlotEditSheetState extends State<_SlotEditSheet> {
  late int _hour;
  late int _minute;
  late ReminderTone _tone;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _hour = e?.hour ?? 9;
    _minute = e?.minute ?? 0;
    _tone = e?.tone ?? ReminderTone.friendly;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final notifier = widget.ref.read(reminderProvider.notifier);

    return _SheetShell(
      title: isEdit ? 'Sửa mốc nhắc' : 'Thêm mốc nhắc',
      children: [
        GestureDetector(
          onTap: () async {
            final picked = await _pickTime(
              context,
              TimeOfDay(hour: _hour, minute: _minute),
            );
            if (picked != null) {
              setState(() {
                _hour = picked.hour;
                _minute = picked.minute;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x4D38BDF8)),
            ),
            child: Center(
              child: Text(
                _fmt(_hour, _minute),
                style: const TextStyle(
                  color: Color(0xFFBAE6FD),
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Chạm để chọn giờ · ${timeOfDayLabel(_hour)}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 18),
        const Text(
          'Giọng nhắc',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _ToneSelector(
          value: _tone,
          onChanged: (t) => setState(() => _tone = t),
        ),
        const SizedBox(height: 22),
        _PrimaryButton(
          label: isEdit ? 'Lưu thay đổi' : 'Thêm mốc',
          onTap: () async {
            if (isEdit) {
              await notifier.updateSlot(
                widget.existing!.id,
                hour: _hour,
                minute: _minute,
                tone: _tone,
              );
            } else {
              await notifier.addSlot(hour: _hour, minute: _minute, tone: _tone);
            }
            if (context.mounted) Navigator.pop(context);
          },
        ),
        if (isEdit) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              await notifier.removeSlot(widget.existing!.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              child: const Text(
                'Xoá mốc này',
                style: TextStyle(
                  color: Color(0xFFF87171),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SuggestionSheet extends StatefulWidget {
  final WidgetRef ref;
  const _SuggestionSheet({required this.ref});

  @override
  State<_SuggestionSheet> createState() => _SuggestionSheetState();
}

class _SuggestionSheetState extends State<_SuggestionSheet> {
  late int _wake;
  late int _sleep;

  @override
  void initState() {
    super.initState();
    final state = widget.ref.read(reminderProvider);
    _wake = state.wakeMinutes;
    _sleep = state.sleepMinutes;
  }

  List<int> get _preview => suggestReminderTimes(
        wakeMinutes: _wake,
        sleepMinutes: _sleep,
      );

  Future<void> _pickWindow({required bool isWake}) async {
    final current = isWake ? _wake : _sleep;
    final picked = await _pickTime(
      context,
      TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked != null) {
      setState(() {
        final m = picked.hour * 60 + picked.minute;
        if (isWake) {
          _wake = m;
        } else {
          _sleep = m;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = widget.ref.read(reminderProvider.notifier);
    final hasExisting = widget.ref.read(reminderProvider).slots.isNotEmpty;
    final preview = _preview;
    final valid = preview.isNotEmpty;

    return _SheetShell(
      title: '✨ Gợi ý lịch',
      children: [
        const Text(
          'Cho mình biết bạn thường thức dậy và đi ngủ lúc nào, '
          'mình sẽ rải các mốc nhắc cách đều ~2 tiếng.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _WindowField(
                caption: 'Thức dậy',
                time: _fmt(_wake ~/ 60, _wake % 60),
                onTap: () => _pickWindow(isWake: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WindowField(
                caption: 'Đi ngủ',
                time: _fmt(_sleep ~/ 60, _sleep % 60),
                onTap: () => _pickWindow(isWake: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          valid
              ? 'Sẽ tạo ${preview.length} mốc nhắc:'
              : 'Giờ đi ngủ phải sau giờ thức dậy.',
          style: TextStyle(
            color: valid ? Colors.white : const Color(0xFFF87171),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (valid) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: preview
                .map((m) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x1F38BDF8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x4D38BDF8)),
                      ),
                      child: Text(
                        _fmt(m ~/ 60, m % 60),
                        style: const TextStyle(
                          color: Color(0xFFBAE6FD),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 22),
        _PrimaryButton(
          label: 'Áp dụng gợi ý',
          onTap: !valid
              ? () {}
              : () async {
                  if (hasExisting) {
                    final ok = await _confirmReplace(context);
                    if (ok != true) return;
                  }
                  await notifier.applySuggestion(
                    wakeMinutes: _wake,
                    sleepMinutes: _sleep,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
        ),
      ],
    );
  }

  Future<bool?> _confirmReplace(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Thay lịch hiện tại?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Gợi ý mới sẽ thay toàn bộ các mốc nhắc bạn đang có.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thay lịch', style: TextStyle(color: _cyan)),
          ),
        ],
      ),
    );
  }
}

class _WindowField extends StatelessWidget {
  final String caption;
  final String time;
  final VoidCallback onTap;
  const _WindowField({
    required this.caption,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textHint),
        ),
        child: Column(
          children: [
            Text(
              caption,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
