import 'package:flutter/material.dart';

/// Avatar Catalog — source of truth for the 12 water-spirit forms.
/// Mirrors the backend `avatar_service.py` unlock rules and the design's
/// `avatar-data.jsx` visual specs. Avatars are rendered parametrically from
/// these specs (see `aqua_avatar.dart`), not from static images.

enum AquaTier { common, rare, epic, legendary }

enum UnlockType { level, coin, streak, mission }

class AquaTierStyle {
  final String name;
  final String short;
  final Color color;
  final List<Color> ring;
  final Color glow;

  const AquaTierStyle({
    required this.name,
    required this.short,
    required this.color,
    required this.ring,
    required this.glow,
  });
}

const Map<AquaTier, AquaTierStyle> kAquaTiers = {
  AquaTier.common: AquaTierStyle(
    name: 'Thường',
    short: 'COMMON',
    color: Color(0xFF94A3B8),
    ring: [
      Color(0xFF64748B),
      Color(0xFF94A3B8),
      Color(0xFFCBD5E1),
      Color(0xFF64748B)
    ],
    glow: Color(0x5994A3B8),
  ),
  AquaTier.rare: AquaTierStyle(
    name: 'Hiếm',
    short: 'RARE',
    color: Color(0xFF38BDF8),
    ring: [
      Color(0xFF0284C7),
      Color(0xFF38BDF8),
      Color(0xFF7DD3FC),
      Color(0xFF0284C7)
    ],
    glow: Color(0x8038BDF8),
  ),
  AquaTier.epic: AquaTierStyle(
    name: 'Sử thi',
    short: 'EPIC',
    color: Color(0xFFA78BFA),
    ring: [
      Color(0xFF7C3AED),
      Color(0xFF22D3EE),
      Color(0xFFA78BFA),
      Color(0xFF7C3AED)
    ],
    glow: Color(0x8CA78BFA),
  ),
  AquaTier.legendary: AquaTierStyle(
    name: 'Huyền thoại',
    short: 'LEGENDARY',
    color: Color(0xFFFCD34D),
    ring: [
      Color(0xFFFBBF24),
      Color(0xFFF472B6),
      Color(0xFF38BDF8),
      Color(0xFFFBBF24)
    ],
    glow: Color(0x99FBBF24),
  ),
};

/// How a locked avatar becomes owned. `levelReq`/`streakReq` are derived
/// thresholds (never stored); `coinPrice` requires a purchase. A few avatars
/// offer two paths (e.g. level OR coin) — meeting either grants ownership.
class AquaUnlock {
  final UnlockType type;
  final int? levelReq;
  final int? streakReq;
  final int? coinPrice;
  final String label;
  final String sub;

  const AquaUnlock({
    required this.type,
    this.levelReq,
    this.streakReq,
    this.coinPrice,
    required this.label,
    required this.sub,
  });
}

class AquaAvatarSpec {
  final String id;
  final String name;
  final String meaning;
  final String desc;
  final AquaTier tier;
  final List<Color> body; // [top, bottom] gradient
  final Color rim;
  final Color accent;
  final String eyes; // cute|happy|cool|wise|fierce|regal
  final String mouth; // smile|open|smirk|calm
  final bool blush;
  final List<String> features;
  final Color? aura;
  final bool isDefault;
  final AquaUnlock unlock;

  const AquaAvatarSpec({
    required this.id,
    required this.name,
    required this.meaning,
    required this.desc,
    required this.tier,
    required this.body,
    required this.rim,
    required this.accent,
    required this.eyes,
    required this.mouth,
    this.blush = false,
    this.features = const [],
    this.aura,
    this.isDefault = false,
    required this.unlock,
  });

  AquaTierStyle get tierStyle => kAquaTiers[tier]!;
}

const List<AquaAvatarSpec> kAvatarCatalog = [
  // ── COMMON ──────────────────────────────────────────────
  AquaAvatarSpec(
    id: 'giot_nuoc',
    name: 'Giọt Nước',
    meaning: 'Water Drop',
    desc: 'Hình hài khởi nguồn. Một giọt nước tinh khôi, luôn mỉm cười.',
    tier: AquaTier.common,
    body: [Color(0xFF7DD3FC), Color(0xFF0EA5E9)],
    rim: Color(0xFFBAE6FD),
    accent: Color(0xFF38BDF8),
    eyes: 'cute',
    mouth: 'smile',
    blush: true,
    isDefault: true,
    unlock: AquaUnlock(
      type: UnlockType.level,
      levelReq: 1,
      label: 'Mặc định',
      sub: 'Có sẵn từ đầu',
    ),
  ),
  AquaAvatarSpec(
    id: 'suong_mai',
    name: 'Sương Mai',
    meaning: 'Morning Dew',
    desc: 'Lấp lánh như giọt sương đầu ngày, nhẹ tênh và trong veo.',
    tier: AquaTier.common,
    body: [Color(0xFFECFEFF), Color(0xFFA5E3FF)],
    rim: Color(0xFFF0FBFF),
    accent: Color(0xFF7DD3FC),
    eyes: 'happy',
    mouth: 'smile',
    blush: true,
    features: ['dew'],
    unlock: AquaUnlock(
      type: UnlockType.level,
      levelReq: 3,
      label: 'Cấp 3',
      sub: 'Lên cấp để mở',
    ),
  ),
  AquaAvatarSpec(
    id: 'suoi_non',
    name: 'Suối Non',
    meaning: 'Young Spring',
    desc: 'Mạch suối trẻ vừa trồi lên, mang theo một mầm lá xanh.',
    tier: AquaTier.common,
    body: [Color(0xFFA5F3E8), Color(0xFF22B8CF)],
    rim: Color(0xFFCFFAFE),
    accent: Color(0xFF34D399),
    eyes: 'cute',
    mouth: 'open',
    blush: true,
    features: ['leaf'],
    unlock: AquaUnlock(
      type: UnlockType.level,
      levelReq: 6,
      label: 'Cấp 6',
      sub: 'Lên cấp để mở',
    ),
  ),
  // ── RARE ────────────────────────────────────────────────
  AquaAvatarSpec(
    id: 'dong_chay',
    name: 'Dòng Chảy',
    meaning: 'Current',
    desc: 'Đã biết chuyển động. Một mái tóc nước hất ngược đầy tự tin.',
    tier: AquaTier.rare,
    body: [Color(0xFF38BDF8), Color(0xFF0284C7)],
    rim: Color(0xFF7DD3FC),
    accent: Color(0xFFE0F2FE),
    eyes: 'cool',
    mouth: 'smirk',
    features: ['quiff', 'speed'],
    unlock: AquaUnlock(
      type: UnlockType.level,
      levelReq: 10,
      coinPrice: 280,
      label: 'Cấp 10',
      sub: 'hoặc 280 xu',
    ),
  ),
  AquaAvatarSpec(
    id: 'thuy_ba',
    name: 'Thủy Ba',
    meaning: 'Water Wave',
    desc: 'Sóng lăn tăn đã thành đợt. Vây nước nhỏ mọc hai bên.',
    tier: AquaTier.rare,
    body: [Color(0xFF22D3EE), Color(0xFF0891B2)],
    rim: Color(0xFFA5F3FC),
    accent: Color(0xFFCFFAFE),
    eyes: 'happy',
    mouth: 'open',
    features: ['wavecrest', 'fins'],
    unlock: AquaUnlock(
      type: UnlockType.level,
      levelReq: 14,
      coinPrice: 320,
      label: 'Cấp 14',
      sub: 'hoặc 320 xu',
    ),
  ),
  AquaAvatarSpec(
    id: 'lam_ha',
    name: 'Lam Hà',
    meaning: 'Blue River',
    desc: 'Một dải lụa nước quấn quanh mình — phần thưởng của hành trình.',
    tier: AquaTier.rare,
    body: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    rim: Color(0xFF93C5FD),
    accent: Color(0xFFBFDBFE),
    eyes: 'cool',
    mouth: 'calm',
    features: ['ribbon', 'fins'],
    unlock: AquaUnlock(
      type: UnlockType.mission,
      label: 'Nhiệm vụ',
      sub: 'Chuỗi "Dòng sông xanh"',
    ),
  ),
  // ── EPIC ────────────────────────────────────────────────
  AquaAvatarSpec(
    id: 'hai_lam',
    name: 'Hải Lam',
    meaning: 'Sea Azure',
    desc: 'Sâu như lòng biển. Linh khí bắt đầu xoáy quanh thân.',
    tier: AquaTier.epic,
    body: [Color(0xFF06B6D4), Color(0xFF0E7490)],
    rim: Color(0xFF67E8F9),
    accent: Color(0xFFA5F3FC),
    eyes: 'wise',
    mouth: 'calm',
    features: ['swirl', 'fins'],
    aura: Color(0xFF22D3EE),
    unlock: AquaUnlock(
      type: UnlockType.coin,
      coinPrice: 900,
      levelReq: 20,
      label: '900 xu',
      sub: 'hoặc đạt Cấp 20',
    ),
  ),
  AquaAvatarSpec(
    id: 'thuy_linh',
    name: 'Thủy Linh',
    meaning: 'Water Spirit',
    desc: 'Đã thành linh hồn nước. Viên ngọc trên trán phát sáng dịu.',
    tier: AquaTier.epic,
    body: [Color(0xFF67E8F9), Color(0xFF4F46E5)],
    rim: Color(0xFFA5B4FC),
    accent: Color(0xFFE0F2FE),
    eyes: 'wise',
    mouth: 'calm',
    features: ['gem', 'wisps'],
    aura: Color(0xFF818CF8),
    unlock: AquaUnlock(
      type: UnlockType.coin,
      coinPrice: 1100,
      label: '1.100 xu',
      sub: 'Chỉ bán ở cửa hàng',
    ),
  ),
  AquaAvatarSpec(
    id: 'lam_than',
    name: 'Lam Thần',
    meaning: 'Azure Deity',
    desc: 'Vầng hào quang nước hiện trên đỉnh đầu — bậc thần linh của hồ.',
    tier: AquaTier.epic,
    body: [Color(0xFF2DD4BF), Color(0xFF0D9488)],
    rim: Color(0xFF5EEAD4),
    accent: Color(0xFFCCFBF1),
    eyes: 'regal',
    mouth: 'calm',
    features: ['halo', 'gem', 'wisps'],
    aura: Color(0xFF5EEAD4),
    unlock: AquaUnlock(
      type: UnlockType.coin,
      coinPrice: 1400,
      levelReq: 28,
      label: '1.400 xu',
      sub: 'hoặc đạt Cấp 28',
    ),
  ),
  // ── LEGENDARY ───────────────────────────────────────────
  AquaAvatarSpec(
    id: 'hai_vuong',
    name: 'Hải Vương',
    meaning: 'Sea King',
    desc: 'Vương miện vàng đăng quang. Kẻ trị vì muôn dòng nước.',
    tier: AquaTier.legendary,
    body: [Color(0xFF38BDF8), Color(0xFF1E40AF)],
    rim: Color(0xFFBAE6FD),
    accent: Color(0xFFFCD34D),
    eyes: 'regal',
    mouth: 'calm',
    features: ['crown', 'fins', 'gem'],
    aura: Color(0xFFFBBF24),
    unlock: AquaUnlock(
      type: UnlockType.coin,
      coinPrice: 2500,
      label: '2.500 xu',
      sub: 'Vật phẩm cao cấp',
    ),
  ),
  AquaAvatarSpec(
    id: 'long_thuy',
    name: 'Long Thủy',
    meaning: 'Water Dragon',
    desc: 'Sừng rồng, râu nước. Chỉ kẻ giữ chuỗi 100 ngày mới triệu hồi được.',
    tier: AquaTier.legendary,
    body: [Color(0xFF2DD4BF), Color(0xFF0E7490)],
    rim: Color(0xFF5EEAD4),
    accent: Color(0xFFFCD34D),
    eyes: 'fierce',
    mouth: 'open',
    features: ['horns', 'whiskers', 'fangs'],
    aura: Color(0xFF5EEAD4),
    unlock: AquaUnlock(
      type: UnlockType.streak,
      streakReq: 100,
      label: 'Chuỗi 100 ngày',
      sub: 'Thành tựu hiếm',
    ),
  ),
  AquaAvatarSpec(
    id: 'thuy_de',
    name: 'Thủy Đế',
    meaning: 'Water Emperor',
    desc: 'Hình hài tối thượng. Hội tụ mọi dòng nước thành một đế vương.',
    tier: AquaTier.legendary,
    body: [Color(0xFF7DD3FC), Color(0xFF1E3A8A)],
    rim: Color(0xFFE0F2FE),
    accent: Color(0xFFFDE68A),
    eyes: 'regal',
    mouth: 'calm',
    features: ['crown_grand', 'wings', 'gem', 'particles'],
    aura: Color(0xFFFCD34D),
    unlock: AquaUnlock(
      type: UnlockType.coin,
      coinPrice: 5000,
      levelReq: 40,
      label: '5.000 xu',
      sub: 'Đỉnh cao · cần Cấp 40',
    ),
  ),
];

const String kDefaultAvatarId = 'giot_nuoc';

final Map<String, AquaAvatarSpec> kAvatarById = {
  for (final a in kAvatarCatalog) a.id: a,
};

/// Resolve a (possibly legacy) avatar id to a spec, defaulting to the first
/// water-spirit when unknown (covers old `avatar_1..8` ids).
AquaAvatarSpec avatarSpecOrDefault(String? id) =>
    kAvatarById[id] ?? kAvatarById[kDefaultAvatarId]!;

const List<AquaTier> kTierOrder = [
  AquaTier.common,
  AquaTier.rare,
  AquaTier.epic,
  AquaTier.legendary,
];

/// Per-user ownership state for an avatar — mirrors backend `is_owned`.
enum AvatarOwnership { equipped, owned, locked }

AvatarOwnership avatarOwnership(
  AquaAvatarSpec spec, {
  required int level,
  required int longestStreak,
  required List<String> ownedAvatars,
  required String equippedId,
}) {
  if (spec.id == equippedId) return AvatarOwnership.equipped;
  final u = spec.unlock;
  final owned = spec.isDefault ||
      (u.levelReq != null && level >= u.levelReq!) ||
      (u.streakReq != null && longestStreak >= u.streakReq!) ||
      (u.coinPrice != null && ownedAvatars.contains(spec.id));
  return owned ? AvatarOwnership.owned : AvatarOwnership.locked;
}
