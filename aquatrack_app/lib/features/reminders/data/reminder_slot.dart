import 'package:flutter/foundation.dart';

/// Voice/style of a Reminder Slot's notification copy. Selects which message
/// template fires; does not affect timing. See CONTEXT.md ("Tone").
enum ReminderTone { energetic, friendly, gentle, calm }

extension ReminderToneLabel on ReminderTone {
  /// Vietnamese display name shown in the UI.
  String get label {
    switch (this) {
      case ReminderTone.energetic:
        return 'Năng động';
      case ReminderTone.friendly:
        return 'Thân thiện';
      case ReminderTone.gentle:
        return 'Nhẹ nhàng';
      case ReminderTone.calm:
        return 'Bình yên';
    }
  }
}

/// Vietnamese time-of-day label derived from the hour, used as the Slot's
/// display label (the user never types one).
String timeOfDayLabel(int hour) {
  if (hour < 11) return 'Buổi sáng';
  if (hour < 13) return 'Buổi trưa';
  if (hour < 18) return 'Buổi chiều';
  return 'Buổi tối';
}

/// A single entry in the Hydration Schedule: a daily clock time + on/off + Tone.
/// Repeats every day. Stored on-device only (Hive). See CONTEXT.md.
@immutable
class ReminderSlot {
  final String id;
  final int hour; // 0..23
  final int minute; // 0..59
  final ReminderTone tone;
  final bool enabled;

  const ReminderSlot({
    required this.id,
    required this.hour,
    required this.minute,
    this.tone = ReminderTone.friendly,
    this.enabled = true,
  });

  /// Build from minutes-since-midnight (as produced by the suggestion engine).
  factory ReminderSlot.fromMinutes(
    int minutesOfDay, {
    required String id,
    ReminderTone tone = ReminderTone.friendly,
    bool enabled = true,
  }) {
    final m = minutesOfDay.clamp(0, 24 * 60 - 1);
    return ReminderSlot(
      id: id,
      hour: m ~/ 60,
      minute: m % 60,
      tone: tone,
      enabled: enabled,
    );
  }

  int get minutesOfDay => hour * 60 + minute;

  /// "08:30"
  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get label => timeOfDayLabel(hour);

  ReminderSlot copyWith({
    int? hour,
    int? minute,
    ReminderTone? tone,
    bool? enabled,
  }) {
    return ReminderSlot(
      id: id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      tone: tone ?? this.tone,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'tone': tone.name,
        'enabled': enabled,
      };

  factory ReminderSlot.fromJson(Map<String, dynamic> json) {
    return ReminderSlot(
      id: json['id'] as String,
      hour: (json['hour'] as num).toInt(),
      minute: (json['minute'] as num).toInt(),
      tone: ReminderTone.values.firstWhere(
        (t) => t.name == json['tone'],
        orElse: () => ReminderTone.friendly,
      ),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderSlot &&
      other.id == id &&
      other.hour == hour &&
      other.minute == minute &&
      other.tone == tone &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(id, hour, minute, tone, enabled);
}
