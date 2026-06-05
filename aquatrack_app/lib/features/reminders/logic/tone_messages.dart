import '../data/reminder_slot.dart';

/// Notification copy for Reminder Slots, grouped by [ReminderTone].
///
/// Pure data + selection helpers so the wording lives in one place and the
/// notification service stays mechanical.
const String reminderNotificationTitle = '💧 Đến giờ uống nước';

const Map<ReminderTone, List<String>> _toneBodies = {
  ReminderTone.energetic: [
    'Nạp nước nào! Cơ thể bạn đang chờ 💪',
    'Một ngụm nước để bùng năng lượng nhé! ⚡',
    'Tiếp nước, tiếp lửa — uống ngay thôi! 🔥',
  ],
  ReminderTone.friendly: [
    'Uống một ngụm nước nhé bạn ơi 💧',
    'Tới giờ chăm sóc bản thân rồi, làm ly nước nha 🥤',
    'Đừng quên uống nước nhé, mình nhắc bạn đây! 😊',
  ],
  ReminderTone.gentle: [
    'Nhẹ nhàng thôi — làm một ngụm nước nha 🌿',
    'Thư thả uống chút nước cho khoẻ nhé 🍃',
    'Một hớp nước nhỏ cũng đủ rồi, bạn nhé 💧',
  ],
  ReminderTone.calm: [
    'Hít thở sâu và uống chút nước nhé 🫧',
    'Tĩnh tại một chút, nhấp ngụm nước mát 🌙',
    'Cho cơ thể nghỉ ngơi với một ngụm nước nào 🌊',
  ],
};

/// Pick a body for [tone], varied deterministically by [seed] (e.g. the slot's
/// minutes-of-day) so different slots don't all read identically.
String reminderBodyFor(ReminderTone tone, int seed) {
  final bodies = _toneBodies[tone] ?? _toneBodies[ReminderTone.friendly]!;
  return bodies[seed.abs() % bodies.length];
}
