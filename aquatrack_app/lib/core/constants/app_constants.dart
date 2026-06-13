/// AquaTrack Business Logic Constants
class AppConstants {
  // Hydration coefficients (Log Drink screen)
  static const hydrationCoeff = {
    'water': 1.00,
    'tea': 0.90,
    'coffee': 0.80,
    'juice': 0.85,
    'smoothie': 0.90,
  };

  // XP Events (Gamification system)
  static const xpEvents = {
    'log_drink': 10, // mỗi lần log
    'daily_goal_met': 50, // đạt 100% mục tiêu
    'streak_7': 100,
    'streak_30': 500,
    'total_100L': 200,
    'smart_scan_used': 5, // dùng AI scan
  };

  // Level thresholds
  static const levels = {
    1: (0, 'Water Newbie'),
    5: (500, 'Water Warrior'),
    7: (1000, 'Aqua Warrior'), // current in prototype
    10: (3000, 'Ocean Master'),
    15: (8000, 'Hydration Legend'),
  };

  // Quick log amounts (HomeScreen quick buttons)
  static const quickLogAmounts = [100, 250, 500];

  // Default daily goal calculation base
  static const dailyGoalBaseMultiplier = 35; // per kg body weight

  // Google Sign-In (ADR 0006): the OAuth *Web* client ID from Google Cloud
  // Console. On Android this is the serverClientId that makes the plugin
  // return an ID token; the backend verifies against the same value
  // (GOOGLE_CLIENT_ID in aquatrack_backend/.env). Empty = not configured yet.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
