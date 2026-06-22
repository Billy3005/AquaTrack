// AquaTrack — main app shell
// Renders all screens inside iOS frames on a design canvas

const SPEAKER_NOTES_PLACEHOLDER = null;

function PhoneFrame({ children, label, sublabel }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12 }}>
      <IOSDevice width={390} height={844} dark>
        {children}
      </IOSDevice>
    </div>
  );
}

function App() {
  // global tweakable state
  const TWEAKS = /*EDITMODE-BEGIN*/{
    "current": 1450,
    "goal": 2500,
    "homeState": "normal",
    "hot": false,
    "showAllScreens": true,
    "showLevelUp": false
  }/*EDITMODE-END*/;

  const [tweaks, setTweak] = useTweaks(TWEAKS);

  // for the main standalone prototype (when not showing all screens)
  const [screen, setScreen] = React.useState('home');
  const [current, setCurrent] = React.useState(tweaks.current);

  React.useEffect(() => { setCurrent(tweaks.current); }, [tweaks.current]);

  function handleLog(amt) {
    setCurrent((c) => Math.min(tweaks.goal + 500, c + amt));
  }

  // map state name → effective % shown
  function stateToCurrent(state, goal) {
    if (state === 'dehydrated') return Math.round(goal * 0.22);
    if (state === 'goal') return Math.round(goal * 0.94);
    if (state === 'night') return Math.round(goal * 0.78);
    return tweaks.current;
  }

  if (!tweaks.showAllScreens) {
    // single phone, navigable prototype
    const cur = current;
    return (
      <div style={{
        width: '100vw', minHeight: '100vh',
        background: 'radial-gradient(ellipse at top, #0F1A2E, #050B18)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        padding: 32, fontFamily: FONT,
      }}>
        <IOSDevice width={390} height={844} dark>
          {screen === 'home' && <HomeScreen state={tweaks.homeState} hot={tweaks.hot} current={cur} goal={tweaks.goal} onLog={handleLog} onNavigate={setScreen} />}
          {screen === 'coach' && <CoachScreen current={cur} goal={tweaks.goal} onLog={handleLog} onNavigate={setScreen} />}
          {screen === 'stats' && <StatsScreen onNavigate={setScreen} />}
          {screen === 'level' && <LevelScreen onNavigate={setScreen} />}
          {screen === 'log' && <LogScreen current={cur} goal={tweaks.goal} onLog={handleLog} onNavigate={setScreen} />}
          {screen === 'camera' && <CameraScreen onLog={handleLog} onNavigate={setScreen} />}
          {screen === 'profile' && <ProfileScreen onNavigate={setScreen} />}
          {screen === 'friends' && <FriendsScreen onNavigate={setScreen} />}
          {screen === 'missions' && <MissionsScreen onNavigate={setScreen} />}
          {screen === 'missions-weekly' && <MissionsScreen onNavigate={setScreen} initialTab="weekly" />}
          {screen === 'shop' && <ShopScreen onNavigate={setScreen} />}
          {screen === 'login' && <LoginScreen onNavigate={setScreen} />}
          {screen === 'register' && <RegisterScreen onNavigate={setScreen} onSignedIn={() => setScreen('bodyinfo')} />}
          {screen === 'bodyinfo' && <BodyInfoScreen mode="onboarding" onNavigate={setScreen} onDone={() => setScreen('home')} />}
          {screen === 'bodyinfo-edit' && <BodyInfoScreen mode="edit" onNavigate={setScreen} onDone={() => setScreen('profile')} />}
          {tweaks.showLevelUp && (
            <div style={{ position: 'absolute', inset: 0, zIndex: 50 }}>
              <LevelUpCelebration onDone={() => setTweak('showLevelUp', false)} />
            </div>
          )}
        </IOSDevice>

        <TweaksPanel>
          <TweakSection label="Khoảnh khắc">
            <TweakToggle label="Hiện mừng lên cấp" value={tweaks.showLevelUp} onChange={(v) => setTweak('showLevelUp', v)} />
          </TweakSection>
          <TweakSection label="Hydration">
            <TweakSlider label="Hiện tại (ml)" min={0} max={3500} step={50} value={tweaks.current} onChange={(v) => setTweak('current', v)} />
            <TweakSlider label="Mục tiêu (ml)" min={1500} max={4000} step={100} value={tweaks.goal} onChange={(v) => setTweak('goal', v)} />
          </TweakSection>
          <TweakSection label="Trạng thái">
            <TweakRadio label="Trạng thái" value={tweaks.homeState} onChange={(v) => setTweak('homeState', v)} options={[
              { value: 'normal', label: 'Thường' },
              { value: 'dehydrated', label: 'Thiếu' },
              { value: 'goal', label: 'Đạt' },
              { value: 'night', label: 'Đêm' },
            ]} />
            <TweakToggle label="Thời tiết nóng (34°C)" value={tweaks.hot} onChange={(v) => setTweak('hot', v)} />
          </TweakSection>
          <TweakSection label="Bố cục">
            <TweakToggle label="Hiện tất cả màn hình" value={tweaks.showAllScreens} onChange={(v) => setTweak('showAllScreens', v)} />
          </TweakSection>
        </TweaksPanel>
      </div>
    );
  }

  // Canvas mode — show all screens side by side
  const goal = tweaks.goal;

  // For visualizing state variants on Home, derive a current that matches state
  const homeStateCurrent = stateToCurrent(tweaks.homeState, goal);

  return (
    <div style={{ width: '100vw', minHeight: '100vh', background: '#06091A', fontFamily: FONT }}>
      <DesignCanvas>
        <DCSection id="primary" title="AquaTrack" subtitle="Giọt sống · Trợ lý · Cơ thể · Thống kê · Cấp độ · Ghi nước">

          <DCArtboard id="home" label="01 · Trang chủ" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <HomeScreen
                state={tweaks.homeState}
                hot={tweaks.hot}
                current={homeStateCurrent}
                goal={goal}
                onLog={() => {}}
                onNavigate={() => {}}
              />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="coach" label="02 · Trợ lý AI" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <CoachScreen current={1450} goal={goal} onLog={() => {}} onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="stats" label="04 · Thống kê" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <StatsScreen onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="level" label="05 · Cấp độ & Thành tựu" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <LevelScreen onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="levelup" label="05b · Mừng lên cấp" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <LevelUpCelebration />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="log" label="06 · Ghi nước" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <LogScreen current={1450} goal={goal} onLog={() => {}} onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="camera" label="07 · Quét thông minh" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <CameraScreen onNavigate={() => {}} onLog={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="profile" label="08 · Hồ sơ" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <ProfileScreen onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="friends" label="09 · Bạn bè & Xếp hạng" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <FriendsScreen onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="missions-daily" label="10 · Nhiệm vụ — Hằng ngày" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <MissionsScreen onNavigate={() => {}} initialTab="daily" />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="missions-weekly" label="11 · Nhiệm vụ — Hằng tuần" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <MissionsScreen onNavigate={() => {}} initialTab="weekly" />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="shop" label="12 · Cửa hàng (AquaShop)" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <ShopScreen onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="login" label="13 · Đăng nhập" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <LoginScreen onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="register" label="14 · Đăng ký" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <RegisterScreen onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

        </DCSection>

        <DCSection id="bodyinfo" title="Onboarding sau đăng ký" subtitle="Wizard 5 bước để AI tính nhu cầu nước · cũng truy cập được từ Hồ sơ">
          <DCArtboard id="bi-body" label="B1 · Cơ thể" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <BodyInfoScreen mode="onboarding" />
            </IOSDevice>
          </DCArtboard>
          <DCArtboard id="bi-life" label="B2 · Nhịp sống" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <BodyInfoScreenAtStep step={1} />
            </IOSDevice>
          </DCArtboard>
          <DCArtboard id="bi-health" label="B3 · Sức khoẻ" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <BodyInfoScreenAtStep step={2} />
            </IOSDevice>
          </DCArtboard>
          <DCArtboard id="bi-diet" label="B4 · Ăn uống" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <BodyInfoScreenAtStep step={3} />
            </IOSDevice>
          </DCArtboard>
          <DCArtboard id="bi-review" label="B5 · Tóm tắt & Mục tiêu" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <BodyInfoScreenAtStep step={4} />
            </IOSDevice>
          </DCArtboard>
          <DCArtboard id="bi-edit" label="Chế độ chỉnh sửa (từ Hồ sơ)" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <BodyInfoScreen mode="edit" />
            </IOSDevice>
          </DCArtboard>
        </DCSection>

        <DCSection id="states" title="Trang chủ — Các trạng thái" subtitle="Giao diện phản ứng theo ngữ cảnh">
          <DCArtboard id="s-low" label="Mất nước · 22%" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <HomeScreen state="dehydrated" current={Math.round(goal * 0.22)} goal={goal} />
            </IOSDevice>
          </DCArtboard>
          <DCArtboard id="s-normal" label="Bình thường · 58%" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <HomeScreen state="normal" current={Math.round(goal * 0.58)} goal={goal} />
            </IOSDevice>
          </DCArtboard>
          <DCArtboard id="s-hot" label="Trời nóng · 45%" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <HomeScreen state="normal" hot current={Math.round(goal * 0.45)} goal={goal} />
            </IOSDevice>
          </DCArtboard>
          <DCArtboard id="s-goal" label="Đạt mục tiêu · 94%" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <HomeScreen state="goal" current={Math.round(goal * 0.94)} goal={goal} />
            </IOSDevice>
          </DCArtboard>
          <DCArtboard id="s-night" label="Đêm muộn · tự mờ" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <HomeScreen state="night" current={Math.round(goal * 0.78)} goal={goal} />
            </IOSDevice>
          </DCArtboard>
        </DCSection>

        <DCSection id="widgets" title="Widget & Màn khoá" subtitle="Ghi nước 1 chạm không cần mở app">
          <DCArtboard id="w-small" label="Widget nhỏ · 2×2" width={220} height={220}>
            <SmallWidget current={1450} goal={goal} />
          </DCArtboard>
          <DCArtboard id="w-medium" label="Widget vừa · 4×2" width={460} height={220}>
            <MediumWidget current={1450} goal={goal} />
          </DCArtboard>
          <DCArtboard id="w-lock" label="Widget màn khoá" width={300} height={220}>
            <LockWidget current={1450} goal={goal} />
          </DCArtboard>
        </DCSection>
      </DesignCanvas>

      <TweaksPanel>
        <TweakSection label="Xem trước trạng thái">
          <TweakRadio label="Trạng thái" value={tweaks.homeState} onChange={(v) => setTweak('homeState', v)} options={[
            { value: 'normal', label: 'Thường' },
            { value: 'dehydrated', label: 'Thiếu' },
            { value: 'goal', label: 'Đạt' },
            { value: 'night', label: 'Đêm' },
          ]} />
          <TweakToggle label="Thời tiết nóng" value={tweaks.hot} onChange={(v) => setTweak('hot', v)} />
          <TweakSlider label="Mục tiêu/ngày" min={1500} max={4000} step={100} value={tweaks.goal} onChange={(v) => setTweak('goal', v)} />
        </TweakSection>
        <TweakSection label="Chế độ">
          <TweakToggle label="Canvas (tất cả màn)" value={tweaks.showAllScreens} onChange={(v) => setTweak('showAllScreens', v)} />
          <TweakToggle label="Hiện mừng lên cấp (1 màn)" value={tweaks.showLevelUp} onChange={(v) => setTweak('showLevelUp', v)} />
        </TweakSection>
      </TweaksPanel>
    </div>
  );
}

// Small widgets
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

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
