// avatar-data.jsx — AquaTrack avatar collection
// One water-spirit that evolves across 4 rarity tiers (12 forms).
// Body palette deepens, face matures, accessories stack as tier climbs.

const AQUA_TIERS = {
  common: {
    key: 'common', name: 'Thường', short: 'COMMON',
    color: '#94A3B8', ring: ['#64748B', '#94A3B8', '#CBD5E1', '#64748B'],
    glow: 'rgba(148,163,184,0.35)',
  },
  rare: {
    key: 'rare', name: 'Hiếm', short: 'RARE',
    color: '#38BDF8', ring: ['#0284C7', '#38BDF8', '#7DD3FC', '#0284C7'],
    glow: 'rgba(56,189,248,0.5)',
  },
  epic: {
    key: 'epic', name: 'Sử thi', short: 'EPIC',
    color: '#A78BFA', ring: ['#7C3AED', '#22D3EE', '#A78BFA', '#7C3AED'],
    glow: 'rgba(167,139,250,0.55)',
  },
  legendary: {
    key: 'legendary', name: 'Huyền thoại', short: 'LEGENDARY',
    color: '#FCD34D', ring: ['#FBBF24', '#F472B6', '#38BDF8', '#FBBF24'],
    glow: 'rgba(251,191,36,0.6)',
  },
};

// unlock.type: 'level' | 'coin' | 'streak' | 'mission'
const AQUA_AVATARS = [
  // ── COMMON ── unlock by leveling up ─────────────────────────
  {
    id: 'giot_nuoc', name: 'Giọt Nước', meaning: 'Water Drop', tier: 'common',
    body: ['#7DD3FC', '#0EA5E9'], rim: '#BAE6FD', accent: '#38BDF8',
    eyes: 'cute', mouth: 'smile', blush: true, features: [],
    desc: 'Hình hài khởi nguồn. Một giọt nước tinh khôi, luôn mỉm cười.',
    unlock: { type: 'level', val: 1, label: 'Mặc định', sub: 'Có sẵn từ đầu' },
    owned: true, equipped: true,
  },
  {
    id: 'suong_mai', name: 'Sương Mai', meaning: 'Morning Dew', tier: 'common',
    body: ['#ECFEFF', '#A5E3FF'], rim: '#F0FBFF', accent: '#7DD3FC',
    eyes: 'happy', mouth: 'smile', blush: true, features: ['dew'],
    desc: 'Lấp lánh như giọt sương đầu ngày, nhẹ tênh và trong veo.',
    unlock: { type: 'level', val: 3, label: 'Cấp 3', sub: 'Lên cấp để mở' },
    owned: true,
  },
  {
    id: 'suoi_non', name: 'Suối Non', meaning: 'Young Spring', tier: 'common',
    body: ['#A5F3E8', '#22B8CF'], rim: '#CFFAFE', accent: '#34D399',
    eyes: 'cute', mouth: 'open', blush: true, features: ['leaf'],
    desc: 'Mạch suối trẻ vừa trồi lên, mang theo một mầm lá xanh.',
    unlock: { type: 'level', val: 6, label: 'Cấp 6', sub: 'Lên cấp để mở' },
    owned: true,
  },

  // ── RARE ── level OR coins ──────────────────────────────────
  {
    id: 'dong_chay', name: 'Dòng Chảy', meaning: 'Current', tier: 'rare',
    body: ['#38BDF8', '#0284C7'], rim: '#7DD3FC', accent: '#E0F2FE',
    eyes: 'cool', mouth: 'smirk', blush: false, features: ['quiff', 'speed'],
    desc: 'Đã biết chuyển động. Một mái tóc nước hất ngược đầy tự tin.',
    unlock: { type: 'level', val: 10, label: 'Cấp 10', sub: 'hoặc 280 xu', coin: 280 },
  },
  {
    id: 'thuy_ba', name: 'Thủy Ba', meaning: 'Water Wave', tier: 'rare',
    body: ['#22D3EE', '#0891B2'], rim: '#A5F3FC', accent: '#CFFAFE',
    eyes: 'happy', mouth: 'open', blush: false, features: ['wavecrest', 'fins'],
    desc: 'Sóng lăn tăn đã thành đợt. Vây nước nhỏ mọc hai bên.',
    unlock: { type: 'level', val: 14, label: 'Cấp 14', sub: 'hoặc 320 xu', coin: 320 },
  },
  {
    id: 'lam_ha', name: 'Lam Hà', meaning: 'Blue River', tier: 'rare',
    body: ['#3B82F6', '#1D4ED8'], rim: '#93C5FD', accent: '#BFDBFE',
    eyes: 'cool', mouth: 'calm', blush: false, features: ['ribbon', 'fins'],
    desc: 'Một dải lụa nước quấn quanh mình — phần thưởng của hành trình.',
    unlock: { type: 'mission', val: 0, label: 'Nhiệm vụ', sub: 'Chuỗi “Dòng sông xanh”' },
  },

  // ── EPIC ── coins / high level, aura awakens ────────────────
  {
    id: 'hai_lam', name: 'Hải Lam', meaning: 'Sea Azure', tier: 'epic',
    body: ['#06B6D4', '#0E7490'], rim: '#67E8F9', accent: '#A5F3FC',
    eyes: 'wise', mouth: 'calm', blush: false, features: ['swirl', 'fins'], aura: '#22D3EE',
    desc: 'Sâu như lòng biển. Linh khí bắt đầu xoáy quanh thân.',
    unlock: { type: 'coin', val: 900, label: '900 xu', sub: 'hoặc đạt Cấp 20', alt: 'Cấp 20' },
  },
  {
    id: 'thuy_linh', name: 'Thủy Linh', meaning: 'Water Spirit', tier: 'epic',
    body: ['#67E8F9', '#4F46E5'], rim: '#A5B4FC', accent: '#E0F2FE',
    eyes: 'wise', mouth: 'calm', blush: false, features: ['gem', 'wisps'], aura: '#818CF8',
    desc: 'Đã thành linh hồn nước. Viên ngọc trên trán phát sáng dịu.',
    unlock: { type: 'coin', val: 1100, label: '1.100 xu', sub: 'Chỉ bán ở cửa hàng' },
  },
  {
    id: 'lam_than', name: 'Lam Thần', meaning: 'Azure Deity', tier: 'epic',
    body: ['#2DD4BF', '#0D9488'], rim: '#5EEAD4', accent: '#CCFBF1',
    eyes: 'regal', mouth: 'calm', blush: false, features: ['halo', 'gem', 'wisps'], aura: '#5EEAD4',
    desc: 'Vầng hào quang nước hiện trên đỉnh đầu — bậc thần linh của hồ.',
    unlock: { type: 'coin', val: 1400, label: '1.400 xu', sub: 'hoặc đạt Cấp 28', alt: 'Cấp 28' },
  },

  // ── LEGENDARY ── premium / streak / mastery ─────────────────
  {
    id: 'hai_vuong', name: 'Hải Vương', meaning: 'Sea King', tier: 'legendary',
    body: ['#38BDF8', '#1E40AF'], rim: '#BAE6FD', accent: '#FCD34D',
    eyes: 'regal', mouth: 'calm', blush: false, features: ['crown', 'fins', 'gem'], aura: '#FBBF24',
    desc: 'Vương miện vàng đăng quang. Kẻ trị vì muôn dòng nước.',
    unlock: { type: 'coin', val: 2500, label: '2.500 xu', sub: 'Vật phẩm cao cấp' },
  },
  {
    id: 'long_thuy', name: 'Long Thủy', meaning: 'Water Dragon', tier: 'legendary',
    body: ['#2DD4BF', '#0E7490'], rim: '#5EEAD4', accent: '#FCD34D',
    eyes: 'fierce', mouth: 'open', blush: false, features: ['horns', 'whiskers', 'fangs'], aura: '#5EEAD4',
    desc: 'Sừng rồng, râu nước. Chỉ kẻ giữ chuỗi 100 ngày mới triệu hồi được.',
    unlock: { type: 'streak', val: 100, label: 'Chuỗi 100 ngày', sub: 'Thành tựu hiếm' },
  },
  {
    id: 'thuy_de', name: 'Thủy Đế', meaning: 'Water Emperor', tier: 'legendary',
    body: ['#7DD3FC', '#1E3A8A'], rim: '#E0F2FE', accent: '#FDE68A',
    eyes: 'regal', mouth: 'calm', blush: false,
    features: ['crown_grand', 'wings', 'gem', 'particles'], aura: '#FCD34D',
    desc: 'Hình hài tối thượng. Hội tụ mọi dòng nước thành một đế vương.',
    unlock: { type: 'coin', val: 5000, label: '5.000 xu', sub: 'Đỉnh cao · cần Cấp 40', alt: 'Cấp 40' },
  },
];

window.AQUA_TIERS = AQUA_TIERS;
window.AQUA_AVATARS = AQUA_AVATARS;
