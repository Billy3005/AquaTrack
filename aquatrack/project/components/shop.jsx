// ShopScreen — Cửa hàng xu
// Truy cập khi tap vào CoinBadge ở các screen.

function ShopScreen({ onNavigate, balance = 1240 }) {
  const [tab, setTab] = React.useState('all');
  const [purchased, setPurchased] = React.useState({});
  const [equipped, setEquipped] = React.useState('theme_ocean');
  const [toast, setToast] = React.useState(null);

  // Catalog
  const items = [
    // Featured / limited
    { id: 'theme_aurora', cat: 'theme', name: 'Aurora Night', sub: 'Theme · giới hạn', price: 450, rarity: 'epic', featured: true, swatch: ['#312E81', '#7C3AED', '#06B6D4'] },
    { id: 'frame_dragon', cat: 'frame', name: 'Rồng nước', sub: 'Khung avatar · hiếm', price: 600, rarity: 'epic', featured: true, ringColors: ['#FBBF24', '#F472B6', '#0EA5E9'] },

    // Themes
    { id: 'theme_ocean', cat: 'theme', name: 'Đêm Đại dương', sub: 'Theme · đã có', price: 0, rarity: 'common', swatch: ['#0C4A80', '#082F5C', '#38BDF8'], owned: true },
    { id: 'theme_forest', cat: 'theme', name: 'Mưa rừng', sub: 'Theme', price: 280, rarity: 'rare', swatch: ['#064E3B', '#059669', '#A3E635'] },
    { id: 'theme_desert', cat: 'theme', name: 'Hoàng hôn sa mạc', sub: 'Theme', price: 320, rarity: 'rare', swatch: ['#7C2D12', '#F59E0B', '#FDE68A'] },
    { id: 'theme_sakura', cat: 'theme', name: 'Hoa anh đào', sub: 'Theme', price: 380, rarity: 'rare', swatch: ['#831843', '#EC4899', '#FBCFE8'] },

    // Avatar frames
    { id: 'frame_ocean', cat: 'frame', name: 'Sóng Ocean', sub: 'Khung avatar · đã có', price: 0, rarity: 'common', ringColors: ['#0EA5E9', '#38BDF8'], owned: true },
    { id: 'frame_gold', cat: 'frame', name: 'Vàng ròng', sub: 'Khung avatar', price: 220, rarity: 'rare', ringColors: ['#FBBF24', '#F59E0B'] },
    { id: 'frame_aurora', cat: 'frame', name: 'Cực quang', sub: 'Khung avatar', price: 480, rarity: 'epic', ringColors: ['#A78BFA', '#22D3EE', '#10B981'] },

    // Boosters / consumables
    { id: 'boost_2x', cat: 'boost', name: 'Nhân đôi 24h', sub: 'Toàn bộ xu nhận được × 2', price: 180, rarity: 'rare', icon: '⚡' },
    { id: 'boost_freeze', cat: 'boost', name: 'Đóng băng chuỗi', sub: 'Bảo vệ streak 1 ngày', price: 120, rarity: 'common', icon: '🧊' },
    { id: 'boost_xpkit', cat: 'boost', name: 'Gói +500 XP', sub: 'Nạp ngay 500 XP', price: 250, rarity: 'rare', icon: '💎' },

    // Drink stickers (cosmetic)
    { id: 'sticker_neon', cat: 'sticker', name: 'Drop Neon', sub: 'Hiệu ứng giọt nước', price: 90, rarity: 'common', icon: '💧' },
    { id: 'sticker_bubble', cat: 'sticker', name: 'Bong bóng vàng', sub: 'Hiệu ứng khi log', price: 140, rarity: 'common', icon: '🫧' },
  ];

  const tabs = [
    { id: 'all', label: 'Tất cả' },
    { id: 'theme', label: 'Theme' },
    { id: 'frame', label: 'Khung' },
    { id: 'boost', label: 'Tăng tốc' },
    { id: 'sticker', label: 'Sticker' },
  ];

  const filtered = tab === 'all' ? items : items.filter((i) => i.cat === tab);
  const featured = items.filter((i) => i.featured);

  const isOwned = (i) => i.owned || purchased[i.id];

  function buy(item) {
    if (isOwned(item)) {
      setEquipped(item.id);
      setToast({ kind: 'equip', msg: `Đã chọn “${item.name}”` });
    } else if (balance < item.price) {
      setToast({ kind: 'err', msg: `Thiếu ${item.price - balance} xu` });
    } else {
      setPurchased({ ...purchased, [item.id]: true });
      setToast({ kind: 'ok', msg: `Đã mua “${item.name}” · −${item.price} xu` });
    }
    setTimeout(() => setToast(null), 2200);
  }

  // Adjusted balance (subtract purchased items)
  const spent = items.filter((i) => purchased[i.id]).reduce((s, i) => s + i.price, 0);
  const liveBalance = balance - spent;

  return (
    <div style={{
      width: '100%', height: '100%',
      background: COLORS.nightBase, color: COLORS.textPrimary,
      fontFamily: FONT, display: 'flex', flexDirection: 'column',
    }}>
      {/* Header */}
      <div style={{
        background: 'linear-gradient(180deg, #1A1040 0%, #0B1120 100%)',
        padding: '54px 18px 14px',
        position: 'relative', overflow: 'hidden',
        flexShrink: 0,
      }}>
        <div style={{
          position: 'absolute', top: -40, right: -30, width: 240, height: 240,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(251,191,36,0.18), transparent 60%)',
          pointerEvents: 'none',
        }} />
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', position: 'relative' }}>
          <button onClick={() => onNavigate && onNavigate('home')} style={{
            width: 36, height: 36, borderRadius: 999,
            background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.08)',
            color: 'white', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M15 6 L9 12 L15 18" />
            </svg>
          </button>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 11, color: '#FCD34D', fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', fontFamily: FONT_TEXT }}>
              Cửa hàng
            </div>
            <div style={{ fontSize: 16, fontWeight: 700, color: 'white', fontFamily: FONT_ROUND, letterSpacing: '-0.01em' }}>
              AquaShop
            </div>
          </div>
          <div style={{ width: 36 }} />
        </div>

        {/* Wallet card */}
        <div style={{
          marginTop: 14,
          background: 'linear-gradient(135deg, rgba(251,191,36,0.16) 0%, rgba(245,158,11,0.06) 100%)',
          border: '1px solid rgba(251,191,36,0.4)',
          borderRadius: 16,
          padding: '12px 14px',
          display: 'flex', alignItems: 'center', gap: 12,
          position: 'relative', overflow: 'hidden',
        }}>
          <div style={{
            position: 'absolute', right: -16, top: -16,
            width: 90, height: 90,
            background: 'radial-gradient(circle, rgba(251,191,36,0.3), transparent 70%)',
            borderRadius: '50%',
          }} />
          <div style={{
            width: 46, height: 46, borderRadius: 999,
            background: 'radial-gradient(circle at 30% 30%, #FEF3C7, #B45309)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
            boxShadow: '0 4px 14px rgba(245,158,11,0.45)',
          }}>
            {I.coin(28, 'wallet')}
          </div>
          <div style={{ flex: 1, position: 'relative' }}>
            <div style={{ fontSize: 10.5, color: '#FCD34D', fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', fontFamily: FONT_TEXT }}>
              Số dư
            </div>
            <div style={{
              fontSize: 24, fontWeight: 700, color: 'white',
              fontFamily: FONT_ROUND, letterSpacing: '-0.02em',
              fontFeatureSettings: '"tnum"',
              display: 'flex', alignItems: 'baseline', gap: 6,
            }}>
              {liveBalance.toLocaleString('vi-VN')}
              <span style={{ fontSize: 12, color: '#FDE68A', fontWeight: 600 }}>xu</span>
            </div>
          </div>
          <button onClick={() => onNavigate && onNavigate('missions')} style={{
            background: 'rgba(255,255,255,0.1)',
            border: '1px solid rgba(255,255,255,0.18)',
            borderRadius: 10,
            color: '#FDE68A',
            padding: '7px 11px',
            fontFamily: FONT_ROUND, fontSize: 11, fontWeight: 700,
            cursor: 'pointer',
            display: 'flex', alignItems: 'center', gap: 4,
            letterSpacing: '0.02em',
          }}>
            + Kiếm xu
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div style={{
        flexShrink: 0,
        padding: '12px 14px 8px',
        borderBottom: `1px solid ${COLORS.border}`,
        background: COLORS.nightBase,
      }}>
        <div style={{ display: 'flex', gap: 6, overflowX: 'auto', scrollbarWidth: 'none' }}>
          {tabs.map((t) => {
            const a = t.id === tab;
            return (
              <button key={t.id} onClick={() => setTab(t.id)} style={{
                background: a ? 'linear-gradient(135deg, rgba(251,191,36,0.2), rgba(245,158,11,0.08))' : 'rgba(255,255,255,0.04)',
                border: a ? '1px solid rgba(251,191,36,0.45)' : '1px solid rgba(255,255,255,0.06)',
                color: a ? '#FDE68A' : COLORS.textSecondary,
                padding: '6px 12px', borderRadius: 999,
                fontFamily: FONT_ROUND, fontSize: 12, fontWeight: 600,
                whiteSpace: 'nowrap', cursor: 'pointer',
                letterSpacing: '0.01em',
              }}>{t.label}</button>
            );
          })}
        </div>
      </div>

      {/* Content */}
      <div style={{ flex: 1, overflow: 'auto', padding: '14px 14px 20px' }}>
        {/* Featured carousel */}
        {tab === 'all' && (
          <>
            <SectionLabel>✨ Nổi bật tuần này</SectionLabel>
            <div style={{
              display: 'flex', gap: 10, overflowX: 'auto',
              paddingBottom: 6, marginBottom: 18,
              scrollbarWidth: 'none',
            }}>
              {featured.map((item) => (
                <FeaturedCard key={item.id} item={item} balance={liveBalance} owned={isOwned(item)} equipped={equipped === item.id} onBuy={() => buy(item)} />
              ))}
            </div>
            <SectionLabel>Tất cả vật phẩm</SectionLabel>
          </>
        )}

        {/* Grid */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          gap: 10,
        }}>
          {filtered.map((item) => (
            <ShopItem key={item.id} item={item} balance={liveBalance} owned={isOwned(item)} equipped={equipped === item.id} onBuy={() => buy(item)} />
          ))}
        </div>
      </div>

      {/* Toast */}
      {toast && (
        <div style={{
          position: 'absolute', bottom: 90, left: '50%',
          transform: 'translateX(-50%)',
          background: toast.kind === 'err' ? 'rgba(239,68,68,0.95)' : toast.kind === 'equip' ? 'rgba(56,189,248,0.95)' : 'rgba(34,197,94,0.95)',
          color: 'white',
          padding: '10px 18px', borderRadius: 999,
          fontFamily: FONT_ROUND, fontSize: 12, fontWeight: 600,
          boxShadow: '0 8px 24px rgba(0,0,0,0.5)',
          animation: 'shop-toast 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)',
          whiteSpace: 'nowrap',
          zIndex: 50,
        }}>{toast.msg}</div>
      )}

      <BottomTabBar active="shop" onNavigate={onNavigate} />

      <style>{`
        @keyframes shop-toast {
          from { transform: translate(-50%, 20px); opacity: 0; }
          to { transform: translate(-50%, 0); opacity: 1; }
        }
        @keyframes shop-shine {
          0% { transform: translateX(-120%) skewX(-20deg); }
          100% { transform: translateX(220%) skewX(-20deg); }
        }
      `}</style>
    </div>
  );
}

function SectionLabel({ children }) {
  return (
    <div style={{
      fontSize: 11, color: COLORS.textBright, fontWeight: 600,
      letterSpacing: '0.08em', textTransform: 'uppercase',
      fontFamily: FONT_TEXT, marginBottom: 10, marginTop: 2,
    }}>{children}</div>
  );
}

function rarityColor(r) {
  return r === 'epic' ? '#A78BFA' : r === 'rare' ? '#38BDF8' : '#94A3B8';
}

function FeaturedCard({ item, balance, owned, equipped, onBuy }) {
  const rc = rarityColor(item.rarity);
  return (
    <div style={{
      flexShrink: 0,
      width: 215,
      background: `linear-gradient(135deg, ${rc}22 0%, rgba(11,17,32,0.6) 100%)`,
      border: `1px solid ${rc}55`,
      borderRadius: 14,
      padding: 12,
      position: 'relative', overflow: 'hidden',
    }}>
      <div style={{
        position: 'absolute', inset: 0,
        background: `radial-gradient(circle at 100% 0%, ${rc}33, transparent 60%)`,
        pointerEvents: 'none',
      }} />
      {/* shine */}
      <div style={{
        position: 'absolute', top: 0, bottom: 0, width: 40,
        background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.15), transparent)',
        animation: 'shop-shine 3.5s ease-in-out infinite',
        pointerEvents: 'none',
      }} />
      <div style={{
        position: 'absolute', top: 8, right: 8,
        fontSize: 8.5, padding: '2px 7px', borderRadius: 4,
        background: rc + '33', color: rc,
        fontFamily: FONT_ROUND, fontWeight: 700, letterSpacing: '0.08em',
        textTransform: 'uppercase',
      }}>{item.rarity}</div>

      {/* Preview */}
      <div style={{
        height: 92, borderRadius: 10,
        marginBottom: 10,
        background: COLORS.nightCard,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        overflow: 'hidden', position: 'relative',
      }}>
        <ItemPreview item={item} large />
      </div>

      <div style={{ fontSize: 13, fontWeight: 600, color: 'white', letterSpacing: '-0.01em', fontFamily: FONT_TEXT }}>
        {item.name}
      </div>
      <div style={{ fontSize: 10.5, color: COLORS.textSecondary, marginTop: 1, fontFamily: FONT_TEXT }}>
        {item.sub}
      </div>

      <BuyButton item={item} balance={balance} owned={owned} equipped={equipped} onBuy={onBuy} compact={false} />
    </div>
  );
}

function ShopItem({ item, balance, owned, equipped, onBuy }) {
  const rc = rarityColor(item.rarity);
  return (
    <div style={{
      background: COLORS.nightSurface,
      border: equipped ? `1.5px solid ${COLORS.glow}` : `1px solid ${COLORS.border}`,
      borderRadius: 14,
      padding: 10,
      position: 'relative',
      boxShadow: equipped ? '0 0 0 4px rgba(56,189,248,0.10)' : 'none',
    }}>
      {/* Preview area */}
      <div style={{
        height: 82, borderRadius: 9,
        marginBottom: 9,
        background: COLORS.nightCard,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative', overflow: 'hidden',
      }}>
        <ItemPreview item={item} />
        <div style={{
          position: 'absolute', top: 6, left: 6,
          fontSize: 8, padding: '1px 5px', borderRadius: 3,
          background: rc + '33', color: rc,
          fontFamily: FONT_ROUND, fontWeight: 700, letterSpacing: '0.08em',
          textTransform: 'uppercase',
        }}>{item.rarity}</div>
        {equipped && (
          <div style={{
            position: 'absolute', top: 6, right: 6,
            fontSize: 8.5, padding: '2px 6px', borderRadius: 4,
            background: 'rgba(56,189,248,0.25)', color: '#BAE6FD',
            fontFamily: FONT_ROUND, fontWeight: 700, letterSpacing: '0.04em',
            border: '1px solid rgba(56,189,248,0.4)',
          }}>ĐANG DÙNG</div>
        )}
      </div>

      <div style={{ fontSize: 12.5, fontWeight: 600, color: COLORS.textPrimary, letterSpacing: '-0.01em', fontFamily: FONT_TEXT, textWrap: 'pretty' }}>
        {item.name}
      </div>
      <div style={{ fontSize: 10, color: COLORS.textMuted, marginTop: 1, fontFamily: FONT_TEXT, marginBottom: 7 }}>
        {item.sub}
      </div>

      <BuyButton item={item} balance={balance} owned={owned} equipped={equipped} onBuy={onBuy} compact />
    </div>
  );
}

function BuyButton({ item, balance, owned, equipped, onBuy, compact }) {
  const cantAfford = !owned && balance < item.price;

  if (owned && equipped) {
    return (
      <button disabled style={{
        width: '100%',
        background: 'rgba(56,189,248,0.12)',
        border: '1px solid rgba(56,189,248,0.3)',
        borderRadius: 9,
        padding: compact ? '6px 0' : '8px 0',
        color: '#7DD3FC',
        fontFamily: FONT_ROUND, fontWeight: 700,
        fontSize: compact ? 11 : 12,
        letterSpacing: '0.04em',
        cursor: 'default',
      }}>✓ ĐANG DÙNG</button>
    );
  }

  if (owned) {
    return (
      <button onClick={onBuy} style={{
        width: '100%',
        background: 'linear-gradient(135deg, #0EA5E9, #0284C7)',
        border: 'none',
        borderRadius: 9,
        padding: compact ? '6px 0' : '8px 0',
        color: 'white',
        fontFamily: FONT_ROUND, fontWeight: 700,
        fontSize: compact ? 11 : 12,
        letterSpacing: '0.04em',
        cursor: 'pointer',
        boxShadow: '0 2px 8px rgba(14,165,233,0.35)',
      }}>CHỌN DÙNG</button>
    );
  }

  return (
    <button onClick={onBuy} disabled={cantAfford} style={{
      width: '100%',
      background: cantAfford
        ? 'rgba(255,255,255,0.04)'
        : 'linear-gradient(135deg, #FBBF24, #F59E0B)',
      border: cantAfford ? '1px solid rgba(255,255,255,0.06)' : 'none',
      borderRadius: 9,
      padding: compact ? '6px 0' : '8px 0',
      color: cantAfford ? COLORS.textMuted : '#451A03',
      fontFamily: FONT_ROUND, fontWeight: 700,
      fontSize: compact ? 11 : 12,
      letterSpacing: '0.02em',
      cursor: cantAfford ? 'not-allowed' : 'pointer',
      boxShadow: cantAfford ? 'none' : '0 2px 8px rgba(245,158,11,0.35)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 5,
      fontFeatureSettings: '"tnum"',
    }}>
      {I.coin(compact ? 12 : 14, 'b' + item.id)}
      <span>{item.price.toLocaleString('vi-VN')}</span>
    </button>
  );
}

function ItemPreview({ item, large = false }) {
  if (item.cat === 'theme') {
    return (
      <div style={{
        width: '100%', height: '100%',
        display: 'flex',
      }}>
        {item.swatch.map((c, i) => (
          <div key={i} style={{ flex: 1, background: c }} />
        ))}
      </div>
    );
  }
  if (item.cat === 'frame') {
    const size = large ? 72 : 56;
    return (
      <div style={{
        width: size, height: size, borderRadius: 999,
        padding: 3,
        background: `conic-gradient(from 220deg, ${item.ringColors.join(', ')}, ${item.ringColors[0]})`,
        boxShadow: '0 0 20px rgba(165,180,252,0.4)',
      }}>
        <div style={{
          width: '100%', height: '100%', borderRadius: 999,
          background: 'radial-gradient(circle at 30% 30%, #7DD3FC, #0284C7)',
          border: '2px solid #0B1120',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          {I.drop('white', large ? 26 : 20)}
        </div>
      </div>
    );
  }
  if (item.cat === 'boost') {
    return (
      <div style={{
        width: large ? 64 : 52, height: large ? 64 : 52, borderRadius: large ? 16 : 12,
        background: 'radial-gradient(circle at 30% 30%, rgba(167,139,250,0.35), rgba(124,58,237,0.1))',
        border: '1px solid rgba(167,139,250,0.4)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: large ? 30 : 24,
        boxShadow: '0 4px 16px rgba(124,58,237,0.25)',
      }}>{item.icon}</div>
    );
  }
  // sticker
  return (
    <div style={{
      width: large ? 64 : 52, height: large ? 64 : 52, borderRadius: 999,
      background: 'radial-gradient(circle at 30% 30%, #7DD3FC, #0EA5E9)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: large ? 28 : 22,
      boxShadow: '0 0 20px rgba(56,189,248,0.4)',
    }}>{item.icon}</div>
  );
}

window.ShopScreen = ShopScreen;
