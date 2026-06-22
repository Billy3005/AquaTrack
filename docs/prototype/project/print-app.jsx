// AquaTrack — print version. One phone per landscape page.

const PRINT_GOAL = 2500;

function PhonePage({ num, title, desc, children }) {
  return (
    <div className="print-page">
      <div className="print-meta">
        <div className="num">Screen {num}</div>
        <h2 className="title">{title}</h2>
        <p className="desc">{desc}</p>
      </div>
      <div style={{ flexShrink: 0 }}>
        <IOSDevice width={390} height={844} dark>
          {children}
        </IOSDevice>
      </div>
    </div>
  );
}

function SectionHead({ num, title, desc }) {
  return (
    <div className="section-head">
      <div className="num">Part {num}</div>
      <h2>{title}</h2>
      <p>{desc}</p>
    </div>
  );
}

function PrintApp() {
  const goal = PRINT_GOAL;

  const screens = [
    { id: 'home', num: '01', title: 'Home — Living Drop', desc: 'A breathing water drop reveals hydration % at a glance. Status pill shifts with weather and time of day.', el: <HomeScreen state="normal" current={1450} goal={goal} onLog={() => {}} onNavigate={() => {}} /> },
    { id: 'coach', num: '02', title: 'AI Coach', desc: 'Conversational nudges with quick-replies. The coach reasons about caffeine, exercise, and weather to suggest precise top-ups.', el: <CoachScreen current={1450} goal={goal} onLog={() => {}} onNavigate={() => {}} /> },
    { id: 'stats', num: '03', title: 'Stats — Wave Chart', desc: 'Weekly hydration as a flowing wave. Patterns surface — weekend dips, post-workout spikes — without spreadsheet feel.', el: <StatsScreen onNavigate={() => {}} /> },
    { id: 'level', num: '04', title: 'Level & Achievements', desc: 'XP, streaks, and unlockable avatars turn hydration into a long-game ritual rather than a daily checkbox.', el: <LevelScreen onNavigate={() => {}} /> },
    { id: 'log', num: '05', title: 'Log Drink', desc: 'Six common drink presets, smart amount slider, and effective-hydration math (coffee, tea offset automatically).', el: <LogScreen current={1450} goal={goal} onLog={() => {}} onNavigate={() => {}} /> },
    { id: 'camera', num: '06', title: 'Smart Scan', desc: 'AI vision identifies the drink, estimates volume, and computes effective hydration — log a coffee in one tap.', el: <CameraScreen onLog={() => {}} onNavigate={() => {}} /> },
    { id: 'profile', num: '07', title: 'Profile', desc: 'Identity, body data, reminder schedule, and avatar collection — gamification kept human and editable.', el: <ProfileScreen onNavigate={() => {}} /> },
  ];

  return (
    <div className="print-root">
      {/* Cover */}
      <div className="print-cover">
        <div className="tag">AquaTrack · Hi-fi Prototype</div>
        <h1>The hydration app that feels alive.</h1>
        <p>Eight screens · five home states · three widget formats. A Living Drop interface, an AI coach, and a body-as-ecosystem metaphor that turns water into care.</p>
        <div className="grid">
          {screens.map((s) => (
            <div key={s.id} className="grid-cell">
              <span className="n">{s.num}</span>
              {s.title}
            </div>
          ))}
        </div>
      </div>

      {/* Section: Primary screens */}
      <SectionHead num="I" title="Primary screens" desc="The core eight surfaces of AquaTrack — every hydration moment, end to end." />

      {screens.map((s) => (
        <PhonePage key={s.id} num={s.num} title={s.title} desc={s.desc}>
          {s.el}
        </PhonePage>
      ))}

      {/* Section: Home state variants */}
      <SectionHead num="II" title="Home, in five moods" desc="The Living Drop reacts to context — weather, time, and how close you are to your goal." />

      <div className="print-grid">
        <h3>Home — state variants</h3>
        <div className="grid">
          {[
            { lbl: 'Dehydrated · 22%', state: 'dehydrated', cur: 0.22 },
            { lbl: 'Normal · 58%', state: 'normal', cur: 0.58 },
            { lbl: 'Hot weather · 45%', state: 'normal', hot: true, cur: 0.45 },
            { lbl: 'Goal reached · 94%', state: 'goal', cur: 0.94 },
            { lbl: 'Late night · auto-dim', state: 'night', cur: 0.78 },
          ].map((v, i) => (
            <div key={i} className="cell">
              <IOSDevice width={390} height={844} dark>
                <HomeScreen state={v.state} hot={v.hot} current={Math.round(goal * v.cur)} goal={goal} />
              </IOSDevice>
              <div className="lbl">{v.lbl}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Widgets */}
      <SectionHead num="III" title="Widgets & lock screen" desc="One-tap logging without ever opening the app. The Living Drop scales down beautifully." />

      <div className="print-widgets">
        <h3>Widgets</h3>
        <p>Small, medium, and lock-screen surfaces — each a single-glance hydration check.</p>
        <div className="row">
          <div className="item">
            <div style={{ width: 220, height: 220 }}><SmallWidget current={1450} goal={goal} /></div>
            <div className="lbl">Small · 2×2</div>
          </div>
          <div className="item">
            <div style={{ width: 460, height: 220 }}><MediumWidget current={1450} goal={goal} /></div>
            <div className="lbl">Medium · 4×2</div>
          </div>
          <div className="item">
            <div style={{ width: 300, height: 220 }}><LockWidget current={1450} goal={goal} /></div>
            <div className="lbl">Lock screen</div>
          </div>
        </div>
      </div>
    </div>
  );
}

// Small widgets — copied from app.jsx so this file is self-contained
function SmallWidget({ current, goal }) {
  const pct = Math.round((current / goal) * 100);
  return (
    <div style={{
      width: '100%', height: '100%',
      background: 'linear-gradient(135deg, #0C2A4A, #0B1933)',
      borderRadius: 22, padding: 14,
      display: 'flex', flexDirection: 'column',
      fontFamily: FONT, color: 'white',
      border: '1px solid rgba(56,189,248,0.15)',
      position: 'relative', overflow: 'hidden',
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div style={{ fontSize: 10, color: '#7DD3FC', fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase' }}>
          AquaTrack
        </div>
        <div style={{
          background: 'rgba(129,140,248,0.2)', color: '#C7D2FE',
          padding: '2px 6px', borderRadius: 6, fontSize: 9, fontFamily: FONT_ROUND, fontWeight: 700,
        }}>LV 7</div>
      </div>
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '4px 0' }}>
        <LivingDrop percent={pct} size={100} label={`${pct}%`} />
      </div>
      <div style={{ fontSize: 10, color: '#94A3B8', textAlign: 'center', marginBottom: 6, fontFamily: FONT_TEXT }}>
        {current.toLocaleString()} / {goal.toLocaleString()}ml
      </div>
      <button style={{
        background: 'linear-gradient(135deg, #0EA5E9, #0284C7)',
        border: 'none', color: 'white', borderRadius: 8,
        padding: '6px', fontFamily: FONT_ROUND, fontSize: 11, fontWeight: 600,
        cursor: 'pointer',
      }}>+ 250ml</button>
    </div>
  );
}

function MediumWidget({ current, goal }) {
  const pct = Math.round((current / goal) * 100);
  return (
    <div style={{
      width: '100%', height: '100%',
      background: 'linear-gradient(135deg, #0C2A4A, #0B1933)',
      borderRadius: 22, padding: 14,
      display: 'flex', gap: 14,
      fontFamily: FONT, color: 'white',
      border: '1px solid rgba(56,189,248,0.15)',
    }}>
      <LivingDrop percent={pct} size={140} label={`${pct}%`} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8, paddingTop: 4 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ fontSize: 10, color: '#7DD3FC', fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase' }}>AquaTrack</div>
          <StreakBadge days={12} compact />
        </div>
        <div>
          <div style={{ fontSize: 22, fontWeight: 700, fontFamily: FONT_ROUND, letterSpacing: '-0.02em', lineHeight: 1 }}>
            {current.toLocaleString()}<span style={{ fontSize: 13, color: '#94A3B8', fontWeight: 500 }}> / {goal.toLocaleString()}ml</span>
          </div>
          <div style={{ height: 5, background: 'rgba(255,255,255,0.08)', borderRadius: 999, marginTop: 8, overflow: 'hidden' }}>
            <div style={{ height: '100%', width: `${pct}%`, background: 'linear-gradient(90deg, #0EA5E9, #38BDF8)', borderRadius: 999 }} />
          </div>
        </div>
        <div style={{ fontSize: 10.5, color: '#BAE6FD', lineHeight: 1.4, fontFamily: FONT_TEXT, fontStyle: 'italic' }}>
          “Cà phê có tính lợi tiểu — uống thêm 250ml để bù lại ☕”
        </div>
        <div style={{ display: 'flex', gap: 6, marginTop: 'auto' }}>
          {[100, 250, 500].map((a) => (
            <div key={a} style={{
              flex: 1, padding: '5px 0', textAlign: 'center', borderRadius: 7,
              background: 'rgba(56,189,248,0.15)', border: '1px solid rgba(56,189,248,0.3)',
              fontSize: 10.5, fontFamily: FONT_ROUND, fontWeight: 600, color: '#BAE6FD',
            }}>+{a}</div>
          ))}
        </div>
      </div>
    </div>
  );
}

function LockWidget({ current, goal }) {
  const pct = Math.round((current / goal) * 100);
  return (
    <div style={{
      width: '100%', height: '100%',
      background: '#0B1120',
      borderRadius: 18, padding: 20,
      fontFamily: FONT, color: 'white',
      display: 'flex', alignItems: 'center', gap: 16,
      border: '1px solid rgba(255,255,255,0.06)',
    }}>
      <LivingDrop percent={pct} size={70} />
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 32, fontWeight: 700, fontFamily: FONT_ROUND, letterSpacing: '-0.03em', lineHeight: 1, color: 'white' }}>
          {pct}%
        </div>
        <div style={{ fontSize: 13, color: '#94A3B8', marginTop: 4 }}>
          {current.toLocaleString()} / {goal.toLocaleString()}ml
        </div>
        <div style={{ fontSize: 10.5, color: '#7DD3FC', marginTop: 4, fontFamily: FONT_ROUND, fontWeight: 600, letterSpacing: '0.04em' }}>
          🔥 Streak 12 ngày
        </div>
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<PrintApp />);

// Auto-print after fonts + render settle
(async () => {
  try { if (document.fonts && document.fonts.ready) await document.fonts.ready; } catch (e) {}
  // Wait two animation frames so React has fully painted
  await new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)));
  // Extra safety delay for component layout
  await new Promise((r) => setTimeout(r, 800));
  window.print();
})();
