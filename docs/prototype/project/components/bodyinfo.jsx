// BodyInfoScreen — thu thập / chỉnh sửa thông tin cơ thể
// Có 2 chế độ:
//   mode="onboarding"  → wizard 4 bước, hiện ngay sau đăng ký
//   mode="edit"        → form 1 trang, mở từ Hồ sơ để chỉnh sửa

const ACTIVITY_OPTIONS = [
  { id: 'sedentary', label: 'Ít vận động', desc: 'Ngồi nhiều, hiếm khi tập', mul: 1.0, icon: '🪑' },
  { id: 'light',     label: 'Nhẹ nhàng',   desc: 'Đi bộ vài lần/tuần',     mul: 1.15, icon: '🚶' },
  { id: 'moderate',  label: 'Vừa phải',    desc: 'Tập 3–4 buổi/tuần',     mul: 1.3, icon: '🏃' },
  { id: 'active',    label: 'Năng động',   desc: 'Tập gần như mỗi ngày',  mul: 1.45, icon: '🏋️' },
  { id: 'athlete',   label: 'Rất năng động', desc: 'VĐV / lao động nặng', mul: 1.6, icon: '🚴' },
];

const WORK_OPTIONS = [
  { id: 'office',  label: 'Văn phòng',      desc: 'Máy lạnh, ngồi nhiều',  mul: 1.0 },
  { id: 'mixed',   label: 'Hỗn hợp',        desc: 'Vừa ngồi vừa di chuyển', mul: 1.05 },
  { id: 'field',   label: 'Ngoài trời',     desc: 'Phơi nắng, đi lại nhiều', mul: 1.2 },
  { id: 'manual',  label: 'Tay chân',       desc: 'Xây dựng, vận chuyển',    mul: 1.25 },
  { id: 'sport',   label: 'Thể thao chuyên nghiệp', desc: 'Tập luyện cường độ cao', mul: 1.35 },
];

const HEALTH_OPTIONS = [
  { id: 'none',         label: 'Không có',          tone: '#10B981' },
  { id: 'diabetes',     label: 'Tiểu đường',        tone: '#F59E0B' },
  { id: 'hypertension', label: 'Cao huyết áp',      tone: '#F97316' },
  { id: 'kidney',       label: 'Bệnh thận',         tone: '#EF4444' },
  { id: 'heart',        label: 'Tim mạch',          tone: '#EC4899' },
  { id: 'pregnant',     label: 'Đang mang thai',    tone: '#A78BFA' },
  { id: 'lactating',    label: 'Đang cho con bú',   tone: '#A78BFA' },
  { id: 'gout',         label: 'Gout',              tone: '#FBBF24' },
];

const VEG_OPTIONS = [
  { id: 'low',  label: 'Ít',     desc: '< 1 phần / ngày', mul: 1.05 },
  { id: 'mid',  label: 'Vừa',    desc: '1–2 phần / ngày', mul: 1.0 },
  { id: 'high', label: 'Nhiều',  desc: '3+ phần / ngày',  mul: 0.95 },
];

function calcGoal(d) {
  // Base ~ 35ml × kg, điều chỉnh theo activity, work, veg, coffee, alcohol
  let g = (Number(d.weight) || 60) * 35;
  const act = ACTIVITY_OPTIONS.find((a) => a.id === d.activity);
  const work = WORK_OPTIONS.find((w) => w.id === d.work);
  const veg = VEG_OPTIONS.find((v) => v.id === d.veg);
  if (act) g *= act.mul;
  if (work) g *= work.mul;
  if (veg) g *= veg.mul;
  g += (Number(d.coffee) || 0) * 120;       // bù 120ml/cốc cà phê
  g += (Number(d.alcohol) || 0) * 200;      // bù 200ml/đơn vị rượu bia
  if ((d.health || []).includes('pregnant'))  g += 300;
  if ((d.health || []).includes('lactating')) g += 700;
  if ((d.health || []).includes('kidney'))    g = Math.min(g, 1800); // giới hạn
  // Làm tròn 50
  return Math.round(g / 50) * 50;
}

function BodyInfoScreen({ mode = 'onboarding', onNavigate, onDone, initialData, initialStep = 0 }) {
  const defaults = {
    gender: 'male',
    age: 28,
    height: 168,
    weight: 60,
    activity: 'moderate',
    work: 'office',
    health: ['none'],
    veg: 'mid',
    coffee: 1,
    alcohol: 0,
  };
  const [data, setData] = React.useState({ ...defaults, ...(initialData || {}) });
  const [step, setStep] = React.useState(initialStep);

  const update = (k, v) => setData((d) => ({ ...d, [k]: v }));
  const toggleHealth = (id) => setData((d) => {
    let h = d.health || [];
    if (id === 'none') return { ...d, health: ['none'] };
    h = h.filter((x) => x !== 'none');
    h = h.includes(id) ? h.filter((x) => x !== id) : [...h, id];
    if (h.length === 0) h = ['none'];
    return { ...d, health: h };
  });

  const goal = calcGoal(data);

  if (mode === 'edit') {
    return (
      <BodyEditView
        data={data}
        update={update}
        toggleHealth={toggleHealth}
        goal={goal}
        onNavigate={onNavigate}
        onDone={onDone}
      />
    );
  }

  // Onboarding wizard
  const steps = [
    { id: 'body',      title: 'Đôi nét về bạn',     subtitle: 'Để AquaTrack tính nhu cầu nước chính xác' },
    { id: 'lifestyle', title: 'Nhịp sống',          subtitle: 'Bạn vận động và làm việc thế nào?' },
    { id: 'health',    title: 'Sức khoẻ',           subtitle: 'Có điều gì cần đặc biệt lưu ý không?' },
    { id: 'diet',      title: 'Thói quen ăn uống',  subtitle: 'Rau, cà phê, rượu bia hằng ngày' },
    { id: 'review',    title: 'Mục tiêu của bạn',   subtitle: 'AI đã tính toán dựa trên dữ liệu' },
  ];
  const s = steps[step];
  const isLast = step === steps.length - 1;

  function next() {
    if (isLast) {
      if (onDone) onDone(data);
      else if (onNavigate) onNavigate('home');
    } else {
      setStep((x) => x + 1);
    }
  }
  function prev() {
    if (step === 0) {
      if (onNavigate) onNavigate('register');
    } else setStep((x) => x - 1);
  }

  return (
    <div style={{
      width: '100%', height: '100%',
      background: COLORS.nightBase, color: COLORS.textPrimary,
      fontFamily: FONT, display: 'flex', flexDirection: 'column',
      position: 'relative', overflow: 'hidden',
    }}>
      {/* Hero / progress */}
      <div style={{
        background: 'linear-gradient(180deg, #0A3460 0%, #0B1933 100%)',
        padding: '52px 22px 18px',
        position: 'relative', overflow: 'hidden',
        flexShrink: 0,
      }}>
        <div style={{
          position: 'absolute', top: -60, left: '50%', transform: 'translateX(-50%)',
          width: 320, height: 320, borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(56,189,248,0.22), transparent 60%)',
          pointerEvents: 'none',
        }} />

        <div style={{ display: 'flex', alignItems: 'center', gap: 12, position: 'relative', marginBottom: 14 }}>
          <button onClick={prev} style={{
            width: 36, height: 36, borderRadius: 999,
            background: 'rgba(255,255,255,0.06)',
            border: '1px solid rgba(255,255,255,0.08)',
            color: 'white', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
          }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M15 6 L9 12 L15 18" />
            </svg>
          </button>
          {/* Progress */}
          <div style={{ flex: 1, display: 'flex', gap: 5 }}>
            {steps.map((_, i) => (
              <div key={i} style={{
                flex: 1, height: 4, borderRadius: 999,
                background: i <= step ? 'linear-gradient(90deg, #38BDF8, #0EA5E9)' : 'rgba(255,255,255,0.1)',
                boxShadow: i === step ? '0 0 10px rgba(56,189,248,0.6)' : 'none',
                transition: 'background 0.3s',
              }} />
            ))}
          </div>
          <div style={{
            fontSize: 11, color: '#BAE6FD', fontFamily: FONT_ROUND, fontWeight: 600,
            fontFeatureSettings: '"tnum"', flexShrink: 0,
          }}>{step + 1}/{steps.length}</div>
        </div>

        <div style={{ position: 'relative' }}>
          <div style={{
            fontSize: 11, color: '#7DD3FC', fontWeight: 600,
            letterSpacing: '0.18em', textTransform: 'uppercase',
            fontFamily: FONT_TEXT, marginBottom: 4,
          }}>Bước {step + 1} · {s.id.toUpperCase()}</div>
          <div style={{
            fontSize: 22, fontWeight: 700, color: 'white',
            letterSpacing: '-0.02em', fontFamily: FONT_ROUND,
            textWrap: 'pretty',
          }}>{s.title}</div>
          <div style={{
            fontSize: 12.5, color: '#BAE6FD', marginTop: 4,
            fontFamily: FONT_TEXT, lineHeight: 1.4,
          }}>{s.subtitle}</div>
        </div>
      </div>

      {/* Step body */}
      <div style={{
        flex: 1, overflow: 'auto',
        padding: '18px 20px 16px',
        display: 'flex', flexDirection: 'column',
      }}>
        {step === 0 && <StepBody data={data} update={update} />}
        {step === 1 && <StepLifestyle data={data} update={update} />}
        {step === 2 && <StepHealth data={data} toggleHealth={toggleHealth} />}
        {step === 3 && <StepDiet data={data} update={update} />}
        {step === 4 && <StepReview data={data} goal={goal} />}
      </div>

      {/* Footer */}
      <div style={{
        flexShrink: 0,
        padding: '12px 20px 28px',
        background: 'linear-gradient(180deg, transparent, #0B1120 30%)',
        borderTop: '1px solid rgba(255,255,255,0.03)',
      }}>
        <button onClick={next} style={{
          width: '100%',
          background: 'linear-gradient(135deg, #0EA5E9, #0284C7)',
          border: '1px solid rgba(255,255,255,0.15)',
          color: 'white',
          padding: '14px 16px',
          borderRadius: 12,
          fontFamily: FONT_ROUND, fontWeight: 700, fontSize: 14,
          letterSpacing: '0.02em',
          cursor: 'pointer',
          boxShadow: '0 8px 24px rgba(14,165,233,0.35)',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          {isLast ? 'Bắt đầu uống nước' : 'Tiếp theo'}
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M5 12 H19 M13 6 L19 12 L13 18"/>
          </svg>
        </button>
        {step < steps.length - 1 && (
          <button onClick={() => setStep(steps.length - 1)} style={{
            width: '100%', marginTop: 10,
            background: 'transparent', border: 'none',
            color: COLORS.textSecondary, fontSize: 12, fontFamily: FONT_TEXT, fontWeight: 500,
            cursor: 'pointer',
          }}>Bỏ qua phần này</button>
        )}
      </div>
    </div>
  );
}

/* ─── Step 1: cơ thể ──────────────────────────────── */
function StepBody({ data, update }) {
  return (
    <>
      <FieldLabel>Giới tính</FieldLabel>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, marginBottom: 18 }}>
        {[
          { id: 'male',   label: 'Nam',  icon: '♂', c: '#38BDF8' },
          { id: 'female', label: 'Nữ',   icon: '♀', c: '#F472B6' },
          { id: 'other',  label: 'Khác', icon: '○', c: '#A78BFA' },
        ].map((g) => {
          const on = data.gender === g.id;
          return (
            <button key={g.id} onClick={() => update('gender', g.id)} style={{
              padding: '14px 8px',
              background: on ? `linear-gradient(180deg, ${g.c}30, ${g.c}12)` : COLORS.nightSurface,
              border: `1.5px solid ${on ? g.c : 'rgba(255,255,255,0.08)'}`,
              borderRadius: 14, cursor: 'pointer',
              color: 'white', fontFamily: FONT_ROUND,
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
              boxShadow: on ? `0 4px 16px ${g.c}30` : 'none',
              transition: 'all 0.15s',
            }}>
              <span style={{ fontSize: 24, color: on ? g.c : COLORS.textSecondary, lineHeight: 1 }}>{g.icon}</span>
              <span style={{ fontSize: 12.5, fontWeight: 600 }}>{g.label}</span>
            </button>
          );
        })}
      </div>

      <FieldLabel>Tuổi</FieldLabel>
      <NumberStepper value={data.age} onChange={(v) => update('age', v)} min={10} max={100} step={1} unit="tuổi" />

      <FieldLabel>Chiều cao</FieldLabel>
      <SliderField value={data.height} onChange={(v) => update('height', v)} min={130} max={210} step={1} unit="cm" />

      <FieldLabel>Cân nặng</FieldLabel>
      <SliderField value={data.weight} onChange={(v) => update('weight', v)} min={30} max={150} step={0.5} unit="kg" precision={1} />
    </>
  );
}

/* ─── Step 2: vận động + công việc ────────────────── */
function StepLifestyle({ data, update }) {
  return (
    <>
      <FieldLabel>Mức vận động thường ngày</FieldLabel>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 18 }}>
        {ACTIVITY_OPTIONS.map((a) => {
          const on = data.activity === a.id;
          return (
            <button key={a.id} onClick={() => update('activity', a.id)} style={{
              padding: '12px 14px',
              background: on ? 'linear-gradient(90deg, rgba(56,189,248,0.18), rgba(56,189,248,0.06))' : COLORS.nightSurface,
              border: `1.5px solid ${on ? '#38BDF8' : 'rgba(255,255,255,0.06)'}`,
              borderRadius: 12, cursor: 'pointer',
              color: 'white', fontFamily: FONT_TEXT,
              display: 'flex', alignItems: 'center', gap: 12,
              textAlign: 'left',
              boxShadow: on ? '0 4px 16px rgba(56,189,248,0.18)' : 'none',
            }}>
              <span style={{ fontSize: 22, lineHeight: 1, flexShrink: 0 }}>{a.icon}</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>{a.label}</div>
                <div style={{ fontSize: 11.5, color: COLORS.textSecondary, marginTop: 1 }}>{a.desc}</div>
              </div>
              <Radio on={on} />
            </button>
          );
        })}
      </div>

      <FieldLabel>Tính chất công việc</FieldLabel>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
        {WORK_OPTIONS.map((w) => {
          const on = data.work === w.id;
          return (
            <button key={w.id} onClick={() => update('work', w.id)} style={{
              padding: '10px 14px',
              background: on ? 'rgba(56,189,248,0.18)' : COLORS.nightSurface,
              border: `1.5px solid ${on ? '#38BDF8' : 'rgba(255,255,255,0.06)'}`,
              borderRadius: 999, cursor: 'pointer',
              color: on ? '#BAE6FD' : 'white', fontFamily: FONT_TEXT,
              fontSize: 12.5, fontWeight: 600,
              display: 'inline-flex', flexDirection: 'column', alignItems: 'flex-start', gap: 2,
            }}>
              <span>{w.label}</span>
              <span style={{ fontSize: 10.5, color: COLORS.textMuted, fontWeight: 400 }}>{w.desc}</span>
            </button>
          );
        })}
      </div>
    </>
  );
}

/* ─── Step 3: health ───────────────────────────────── */
function StepHealth({ data, toggleHealth }) {
  return (
    <>
      <FieldLabel>Tình trạng sức khoẻ đặc biệt</FieldLabel>
      <div style={{ fontSize: 11.5, color: COLORS.textMuted, marginBottom: 10, fontFamily: FONT_TEXT, lineHeight: 1.5 }}>
        Có thể chọn nhiều. AquaTrack sẽ điều chỉnh lượng nước & lời nhắc cho phù hợp.
      </div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 18 }}>
        {HEALTH_OPTIONS.map((h) => {
          const on = (data.health || []).includes(h.id);
          return (
            <button key={h.id} onClick={() => toggleHealth(h.id)} style={{
              padding: '10px 14px',
              background: on ? `${h.tone}1F` : COLORS.nightSurface,
              border: `1.5px solid ${on ? h.tone : 'rgba(255,255,255,0.08)'}`,
              borderRadius: 999, cursor: 'pointer',
              color: on ? h.tone : 'white', fontFamily: FONT_TEXT,
              fontSize: 12.5, fontWeight: 600,
              display: 'inline-flex', alignItems: 'center', gap: 6,
            }}>
              {on && (
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke={h.tone} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M5 12 L10 17 L19 7"/>
                </svg>
              )}
              {h.label}
            </button>
          );
        })}
      </div>

      <div style={{
        background: 'rgba(251,191,36,0.06)',
        border: '1px solid rgba(251,191,36,0.18)',
        borderRadius: 12, padding: '12px 14px',
        display: 'flex', gap: 10,
      }}>
        <span style={{ fontSize: 18, lineHeight: 1 }}>💡</span>
        <div style={{ fontSize: 11.5, color: '#FDE68A', lineHeight: 1.5, fontFamily: FONT_TEXT }}>
          Thông tin này không thay thế lời khuyên y tế. Với bệnh thận hoặc tim mạch, hãy hỏi bác sĩ về lượng nước phù hợp.
        </div>
      </div>
    </>
  );
}

/* ─── Step 4: diet ─────────────────────────────────── */
function StepDiet({ data, update }) {
  return (
    <>
      <FieldLabel>Lượng rau củ quả mỗi ngày</FieldLabel>
      <div style={{ fontSize: 11.5, color: COLORS.textMuted, marginBottom: 10, fontFamily: FONT_TEXT, lineHeight: 1.5 }}>
        Rau củ quả chứa nhiều nước — ăn nhiều sẽ giảm bớt nhu cầu uống.
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, marginBottom: 20 }}>
        {VEG_OPTIONS.map((v) => {
          const on = data.veg === v.id;
          return (
            <button key={v.id} onClick={() => update('veg', v.id)} style={{
              padding: '14px 8px',
              background: on ? 'linear-gradient(180deg, rgba(16,185,129,0.25), rgba(16,185,129,0.08))' : COLORS.nightSurface,
              border: `1.5px solid ${on ? '#10B981' : 'rgba(255,255,255,0.06)'}`,
              borderRadius: 14, cursor: 'pointer',
              color: 'white', fontFamily: FONT_ROUND,
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
              boxShadow: on ? '0 4px 16px rgba(16,185,129,0.2)' : 'none',
            }}>
              <span style={{ fontSize: 22, lineHeight: 1 }}>{v.id === 'low' ? '🥬' : v.id === 'mid' ? '🥗' : '🍎'}</span>
              <span style={{ fontSize: 13, fontWeight: 700 }}>{v.label}</span>
              <span style={{ fontSize: 10.5, color: COLORS.textMuted, fontWeight: 500 }}>{v.desc}</span>
            </button>
          );
        })}
      </div>

      <FieldLabel>Cà phê / ngày</FieldLabel>
      <CounterRow
        value={data.coffee}
        onChange={(v) => update('coffee', v)}
        icon="☕"
        unit="cốc"
        max={6}
        hint="Lợi tiểu — AquaTrack sẽ bù thêm 120ml/cốc"
        tint="#B45309"
      />

      <div style={{ height: 12 }} />

      <FieldLabel>Rượu bia / ngày</FieldLabel>
      <CounterRow
        value={data.alcohol}
        onChange={(v) => update('alcohol', v)}
        icon="🍺"
        unit="đơn vị"
        max={6}
        hint="1 đơn vị = 1 lon bia / 1 ly rượu vang"
        tint="#92400E"
      />
    </>
  );
}

/* ─── Step 5: review ───────────────────────────────── */
function StepReview({ data, goal }) {
  const liter = (goal / 1000).toFixed(2);
  const cups = Math.round(goal / 250);
  const acti = ACTIVITY_OPTIONS.find((a) => a.id === data.activity);
  const work = WORK_OPTIONS.find((w) => w.id === data.work);
  const veg = VEG_OPTIONS.find((v) => v.id === data.veg);
  const healths = (data.health || [])
    .filter((id) => id !== 'none')
    .map((id) => HEALTH_OPTIONS.find((h) => h.id === id))
    .filter(Boolean);

  return (
    <>
      {/* Hero drop */}
      <div style={{
        background: 'radial-gradient(ellipse at top, rgba(14,165,233,0.18), transparent 70%)',
        borderRadius: 18, padding: '8px 0 14px',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        marginBottom: 14,
      }}>
        <LivingDrop percent={80} size={120} />
        <div style={{
          fontSize: 11, color: '#7DD3FC', fontWeight: 600, letterSpacing: '0.16em',
          textTransform: 'uppercase', fontFamily: FONT_TEXT, marginTop: 10,
        }}>Mục tiêu hằng ngày</div>
        <div style={{
          fontSize: 42, fontWeight: 800, color: 'white',
          letterSpacing: '-0.03em', fontFamily: FONT_ROUND,
          lineHeight: 1, marginTop: 4,
          fontFeatureSettings: '"tnum"',
        }}>{goal.toLocaleString()}<span style={{ fontSize: 18, color: COLORS.textSecondary, fontWeight: 500 }}>ml</span></div>
        <div style={{ fontSize: 12.5, color: COLORS.textSecondary, marginTop: 4, fontFamily: FONT_TEXT }}>
          ≈ {liter} lít · khoảng {cups} cốc 250ml
        </div>
      </div>

      <div style={{ fontSize: 11, color: COLORS.textMuted, fontFamily: FONT_TEXT, letterSpacing: '0.08em', textTransform: 'uppercase', marginBottom: 8 }}>
        Tóm tắt
      </div>

      <div style={{
        background: COLORS.nightSurface, borderRadius: 14,
        border: '1px solid rgba(255,255,255,0.05)',
        overflow: 'hidden',
      }}>
        <ReviewRow label="Giới tính · Tuổi" value={`${{ male: 'Nam', female: 'Nữ', other: 'Khác' }[data.gender]} · ${data.age} tuổi`} />
        <ReviewRow label="Chiều cao · Cân nặng" value={`${data.height} cm · ${data.weight} kg`} />
        <ReviewRow label="Vận động" value={acti?.label} />
        <ReviewRow label="Công việc" value={work?.label} />
        <ReviewRow label="Rau củ quả" value={veg?.label} />
        <ReviewRow label="Cà phê · Rượu bia" value={`${data.coffee} cốc · ${data.alcohol} đơn vị`} />
        <ReviewRow label="Sức khoẻ" value={healths.length ? healths.map((h) => h.label).join(', ') : 'Không có lưu ý'} last />
      </div>

      <div style={{
        marginTop: 12,
        background: 'rgba(56,189,248,0.08)',
        border: '1px solid rgba(56,189,248,0.2)',
        borderRadius: 12, padding: '12px 14px',
        display: 'flex', gap: 10,
      }}>
        {I.spark('#38BDF8', 16)}
        <div style={{ fontSize: 11.5, color: '#BAE6FD', lineHeight: 1.5, fontFamily: FONT_TEXT }}>
          AquaTrack sẽ tự điều chỉnh mục tiêu này theo thời tiết, vận động và lịch ngủ. Bạn luôn có thể chỉnh lại trong Hồ sơ.
        </div>
      </div>
    </>
  );
}

/* ─── Edit (single-page) view ─────────────────────── */
function BodyEditView({ data, update, toggleHealth, goal, onNavigate, onDone }) {
  return (
    <div style={{
      width: '100%', height: '100%',
      background: COLORS.nightBase, color: COLORS.textPrimary,
      fontFamily: FONT, display: 'flex', flexDirection: 'column',
    }}>
      {/* Header */}
      <div style={{
        background: 'linear-gradient(180deg, #0C2A4A 0%, #0B1120 100%)',
        padding: '52px 18px 16px',
        display: 'flex', alignItems: 'center', gap: 12,
        flexShrink: 0,
        position: 'relative', overflow: 'hidden',
      }}>
        <div style={{
          position: 'absolute', top: -40, right: -40, width: 220, height: 220,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(56,189,248,0.18), transparent 60%)',
        }} />
        <button onClick={() => onNavigate && onNavigate('profile')} style={{
          width: 36, height: 36, borderRadius: 999,
          background: 'rgba(255,255,255,0.06)',
          border: '1px solid rgba(255,255,255,0.08)',
          color: 'white', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0, position: 'relative',
        }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M15 6 L9 12 L15 18" />
          </svg>
        </button>
        <div style={{ flex: 1, minWidth: 0, position: 'relative' }}>
          <div style={{ fontSize: 11, color: '#7DD3FC', fontWeight: 600, letterSpacing: '0.16em', textTransform: 'uppercase', fontFamily: FONT_TEXT }}>
            Hồ sơ cơ thể
          </div>
          <div style={{ fontSize: 19, fontWeight: 700, color: 'white', fontFamily: FONT_ROUND, letterSpacing: '-0.01em', marginTop: 1 }}>
            Sửa thông tin
          </div>
        </div>
        <div style={{ textAlign: 'right', position: 'relative' }}>
          <div style={{ fontSize: 10, color: COLORS.textMuted, fontFamily: FONT_TEXT, letterSpacing: '0.06em', textTransform: 'uppercase' }}>Goal</div>
          <div style={{ fontSize: 16, fontWeight: 700, color: '#BAE6FD', fontFamily: FONT_ROUND, fontFeatureSettings: '"tnum"', lineHeight: 1.1 }}>
            {goal.toLocaleString()}<span style={{ fontSize: 11, color: COLORS.textSecondary, fontWeight: 500 }}>ml</span>
          </div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '18px 18px 12px' }}>
        <EditSection title="Cơ thể">
          <StepBody data={data} update={update} />
        </EditSection>

        <EditSection title="Nhịp sống">
          <StepLifestyle data={data} update={update} />
        </EditSection>

        <EditSection title="Sức khoẻ">
          <StepHealth data={data} toggleHealth={toggleHealth} />
        </EditSection>

        <EditSection title="Ăn uống">
          <StepDiet data={data} update={update} />
        </EditSection>

        <div style={{ height: 4 }} />
      </div>

      {/* Save bar */}
      <div style={{
        flexShrink: 0,
        padding: '12px 18px 28px',
        background: 'linear-gradient(180deg, transparent, #0B1120 30%)',
        borderTop: '1px solid rgba(255,255,255,0.03)',
        display: 'flex', gap: 8,
      }}>
        <button onClick={() => onNavigate && onNavigate('profile')} style={{
          flexShrink: 0,
          background: 'rgba(255,255,255,0.04)',
          border: '1px solid rgba(255,255,255,0.08)',
          color: COLORS.textPrimary,
          padding: '14px 18px',
          borderRadius: 12,
          fontFamily: FONT_ROUND, fontWeight: 600, fontSize: 13,
          cursor: 'pointer',
        }}>Huỷ</button>
        <button onClick={() => onDone ? onDone(data) : onNavigate && onNavigate('profile')} style={{
          flex: 1,
          background: 'linear-gradient(135deg, #0EA5E9, #0284C7)',
          border: '1px solid rgba(255,255,255,0.15)',
          color: 'white',
          padding: '14px 16px',
          borderRadius: 12,
          fontFamily: FONT_ROUND, fontWeight: 700, fontSize: 14,
          cursor: 'pointer',
          boxShadow: '0 8px 24px rgba(14,165,233,0.35)',
        }}>Lưu thay đổi</button>
      </div>
    </div>
  );
}

function EditSection({ title, children }) {
  return (
    <div style={{ marginBottom: 8 }}>
      <div style={{
        fontSize: 11, color: '#7DD3FC', fontWeight: 700,
        letterSpacing: '0.18em', textTransform: 'uppercase',
        fontFamily: FONT_TEXT,
        marginTop: 8, marginBottom: 12,
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        <span>{title}</span>
        <div style={{ flex: 1, height: 1, background: 'linear-gradient(90deg, rgba(56,189,248,0.3), transparent)' }} />
      </div>
      {children}
    </div>
  );
}

/* ─── Small reusable bits ─────────────────────────── */

function FieldLabel({ children }) {
  return (
    <div style={{
      fontSize: 11, color: '#7DD3FC',
      fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase',
      fontFamily: FONT_TEXT, marginBottom: 8,
    }}>{children}</div>
  );
}

function ReviewRow({ label, value, last }) {
  return (
    <div style={{
      padding: '11px 14px',
      borderBottom: last ? 'none' : '1px solid rgba(255,255,255,0.04)',
      display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12,
    }}>
      <div style={{ fontSize: 12, color: COLORS.textSecondary, fontFamily: FONT_TEXT }}>{label}</div>
      <div style={{ fontSize: 12.5, color: 'white', fontFamily: FONT_TEXT, fontWeight: 600, textAlign: 'right', minWidth: 0 }}>{value}</div>
    </div>
  );
}

function Radio({ on }) {
  return (
    <span style={{
      width: 20, height: 20, borderRadius: 999,
      background: on ? '#38BDF8' : 'transparent',
      border: `2px solid ${on ? '#38BDF8' : 'rgba(255,255,255,0.2)'}`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      flexShrink: 0,
      boxShadow: on ? '0 0 10px rgba(56,189,248,0.5)' : 'none',
    }}>
      {on && <span style={{ width: 8, height: 8, borderRadius: 999, background: 'white' }} />}
    </span>
  );
}

function NumberStepper({ value, onChange, min, max, step = 1, unit }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      background: COLORS.nightSurface,
      border: '1px solid rgba(255,255,255,0.06)',
      borderRadius: 12, padding: '8px 10px',
      marginBottom: 18,
    }}>
      <button onClick={() => onChange(Math.max(min, value - step))} style={stepBtn}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round">
          <path d="M5 12 H19"/>
        </svg>
      </button>
      <div style={{ flex: 1, textAlign: 'center', display: 'flex', alignItems: 'baseline', justifyContent: 'center', gap: 6 }}>
        <span style={{ fontSize: 30, fontWeight: 700, color: 'white', fontFamily: FONT_ROUND, letterSpacing: '-0.02em', fontFeatureSettings: '"tnum"' }}>
          {value}
        </span>
        <span style={{ fontSize: 13, color: COLORS.textSecondary, fontFamily: FONT_TEXT }}>{unit}</span>
      </div>
      <button onClick={() => onChange(Math.min(max, value + step))} style={stepBtn}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round">
          <path d="M5 12 H19 M12 5 V19"/>
        </svg>
      </button>
    </div>
  );
}

const stepBtn = {
  width: 40, height: 40, borderRadius: 10,
  background: 'rgba(56,189,248,0.15)',
  border: '1px solid rgba(56,189,248,0.3)',
  cursor: 'pointer',
  display: 'flex', alignItems: 'center', justifyContent: 'center',
  flexShrink: 0,
};

function SliderField({ value, onChange, min, max, step = 1, unit, precision = 0 }) {
  const pct = ((value - min) / (max - min)) * 100;
  const display = precision ? Number(value).toFixed(precision) : value;
  return (
    <div style={{
      background: COLORS.nightSurface,
      border: '1px solid rgba(255,255,255,0.06)',
      borderRadius: 12, padding: '14px 16px 12px',
      marginBottom: 18,
    }}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
          <span style={{ fontSize: 30, fontWeight: 700, color: 'white', fontFamily: FONT_ROUND, letterSpacing: '-0.02em', fontFeatureSettings: '"tnum"', lineHeight: 1 }}>
            {display}
          </span>
          <span style={{ fontSize: 13, color: COLORS.textSecondary, fontFamily: FONT_TEXT }}>{unit}</span>
        </div>
        <span style={{ fontSize: 10.5, color: COLORS.textMuted, fontFamily: FONT_TEXT }}>
          {min}–{max}{unit}
        </span>
      </div>
      <div style={{ position: 'relative', height: 32, display: 'flex', alignItems: 'center' }}>
        <div style={{ width: '100%', height: 6, borderRadius: 999, background: 'rgba(255,255,255,0.06)' }} />
        <div style={{
          position: 'absolute', left: 0, top: '50%', transform: 'translateY(-50%)',
          width: `${pct}%`, height: 6, borderRadius: 999,
          background: 'linear-gradient(90deg, #0EA5E9, #38BDF8)',
          boxShadow: '0 0 12px rgba(56,189,248,0.5)',
          pointerEvents: 'none',
        }} />
        <div style={{
          position: 'absolute', left: `calc(${pct}% - 10px)`, top: '50%', transform: 'translateY(-50%)',
          width: 20, height: 20, borderRadius: 999,
          background: 'white',
          boxShadow: '0 2px 8px rgba(0,0,0,0.4), 0 0 0 4px rgba(56,189,248,0.25)',
          pointerEvents: 'none',
        }} />
        <input
          type="range"
          value={value}
          min={min}
          max={max}
          step={step}
          onChange={(e) => onChange(Number(e.target.value))}
          style={{
            position: 'absolute', inset: 0,
            width: '100%', height: '100%',
            opacity: 0, cursor: 'pointer',
          }}
        />
      </div>
    </div>
  );
}

function CounterRow({ value, onChange, icon, unit, max = 10, hint, tint = '#38BDF8' }) {
  return (
    <div style={{
      background: COLORS.nightSurface,
      border: '1px solid rgba(255,255,255,0.06)',
      borderRadius: 12, padding: '12px 14px',
      marginBottom: 8,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{
          width: 44, height: 44, borderRadius: 12,
          background: `${tint}22`, border: `1px solid ${tint}44`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 22, flexShrink: 0,
        }}>{icon}</div>
        <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 10, justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 5 }}>
            <span style={{ fontSize: 26, fontWeight: 700, color: 'white', fontFamily: FONT_ROUND, lineHeight: 1, fontFeatureSettings: '"tnum"' }}>
              {value}
            </span>
            <span style={{ fontSize: 12, color: COLORS.textSecondary, fontFamily: FONT_TEXT }}>{unit}</span>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <button onClick={() => onChange(Math.max(0, value - 1))} style={stepBtnSm}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round"><path d="M5 12 H19"/></svg>
            </button>
            <button onClick={() => onChange(Math.min(max, value + 1))} style={stepBtnSm}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round"><path d="M5 12 H19 M12 5 V19"/></svg>
            </button>
          </div>
        </div>
      </div>
      {hint && (
        <div style={{ fontSize: 11, color: COLORS.textMuted, marginTop: 8, fontFamily: FONT_TEXT, lineHeight: 1.4 }}>{hint}</div>
      )}
    </div>
  );
}

const stepBtnSm = {
  width: 34, height: 34, borderRadius: 8,
  background: 'rgba(56,189,248,0.15)',
  border: '1px solid rgba(56,189,248,0.3)',
  cursor: 'pointer',
  display: 'flex', alignItems: 'center', justifyContent: 'center',
  flexShrink: 0,
};

// Canvas helper: render the wizard pre-advanced to a given step
function BodyInfoScreenAtStep({ step = 0 }) {
  return <BodyInfoScreen mode="onboarding" initialStep={step} />;
}

window.BodyInfoScreen = BodyInfoScreen;
window.BodyInfoScreenAtStep = BodyInfoScreenAtStep;
