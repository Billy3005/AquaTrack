# 0001 — Client-only Hydration Reminders

- Status: Accepted
- Date: 2026-06-05

## Context

Users want a personal **Hydration Schedule** (Lịch nhắc nhở): daily notifications
nudging *themselves* to drink water, with a one-tap **Schedule Suggestion** to make
setup easy. This is distinct from the existing social **Reminder (Friend Nudge)**.

At decision time the app had no notification engine at all: the reminder list in the
profile screen was hardcoded, in-memory, and fired nothing. `flutter_local_notifications`
was absent and `firebase_messaging` was commented out. The backend had no
reminder-schedule model or scheduler.

Three delivery options were considered:

1. **Local notifications** — scheduled on-device via `flutter_local_notifications`,
   repeating daily. No backend, no Firebase, works offline.
2. **Server push (FCM)** — backend scheduler pushes via Firebase. Requires Firebase
   setup, push-token lifecycle, a server cron, and online delivery.
3. **Hybrid** — local firing + backend-synced schedule for multi-device.

## Decision

Implement the Hydration Schedule as **client-only local notifications**. The schedule
is stored on-device (Hive `app_settings`) and fires via `flutter_local_notifications`
with `matchDateTimeComponents: time` for daily repeat. The backend is **not** involved.

Timing is **inexact** (OS may drift a few minutes) to avoid the Android 12+
`SCHEDULE_EXACT_ALARM` permission and Doze edge cases — second-level precision is
unnecessary for hydration nudges.

## Consequences

**Positive**
- No Firebase/backend work; ships entirely in Flutter.
- Works offline; no push-token or server-cron lifecycle.
- Simpler permission story (notification permission only, no exact-alarm).

**Negative / Trade-offs**
- Schedule lives on one device — no cross-device sync. A future multi-device need
  requires adding a backend model + sync (the reason this is recorded: a future
  reader will otherwise wonder why reminders are not on the server).
- Inexact timing can drift a few minutes; acceptable for this use case.
- Notifications depend on the OS honoring scheduled local notifications (vendor
  battery savers may delay them).

## Notification sound (signature app sound)

The reminders use a custom signature sound `aquatrack_alert.wav` (~1s) instead of
the OS default. A single **WAV** file serves both platforms (the only format
Android *and* iOS notifications both accept — iOS rejects mp3 and requires < 30s).

- **Android**: `android/app/src/main/res/raw/aquatrack_alert.wav`, referenced as
  `RawResourceAndroidNotificationSound('aquatrack_alert')` (no extension).
- **iOS**: `ios/Runner/aquatrack_alert.wav`, referenced as
  `'aquatrack_alert.wav'` (with extension). Must be added to the Runner target's
  **Copy Bundle Resources** in Xcode (requires a Mac) or it silently falls back
  to the default sound.

**Lock-in gotcha (the reason this is recorded):** on Android 8+ the sound is a
property of the **NotificationChannel**, frozen at channel-creation time. Once a
device has the `hydration_reminders` channel, changing the sound in code has **no
effect** for that install. Pre-release this is harmless (uninstall + reinstall to
refresh). After the first public release, changing the sound requires a **new
channel id** (e.g. `hydration_reminders_v2`) plus deleting the old channel — so
the signature sound must be finalised **before** the first release.

Sound respects the device's silent/DND mode (normal-importance channel, not an
alarm-category one) — consistent with the "gentle nudge" intent above.

Friend-side notifications (the social bell inbox) are **in-app only** today (a
polled list, never raised to the OS), so they have no sound to attach. Giving them
the signature sound would first require an OS-delivery mechanism (FCM or
background-poll-and-fire) — tracked as a separate future change under the same
revisit trigger below.

## Revisit when

- Multi-device sync becomes a requirement, or
- Server-controlled / personalized-by-data reminder timing is needed (would move
  scheduling server-side and likely adopt FCM), or
- Friend/social notifications need to reach the OS (would add FCM or a
  background-poll-and-fire path, then reuse the same signature sound).
