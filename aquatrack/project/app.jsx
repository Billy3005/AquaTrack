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
    "showAllScreens": true
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
          {screen === 'eco' && <EcosystemScreen current={cur} goal={tweaks.goal} onNavigate={setScreen} />}
          {screen === 'stats' && <StatsScreen onNavigate={setScreen} />}
          {screen === 'level' && <LevelScreen onNavigate={setScreen} />}
          {screen === 'log' && <LogScreen current={cur} goal={tweaks.goal} onLog={handleLog} onNavigate={setScreen} />}
          {screen === 'camera' && <CameraScreen onLog={handleLog} onNavigate={setScreen} />}
          {screen === 'profile' && <ProfileScreen onNavigate={setScreen} />}
          {screen === 'friends' && <FriendsScreen onNavigate={setScreen} />}
        </IOSDevice>

        <TweaksPanel>
          <TweakSection label="Hydration">
            <TweakSlider label="Current ml" min={0} max={3500} step={50} value={tweaks.current} onChange={(v) => setTweak('current', v)} />
            <TweakSlider label="Goal ml" min={1500} max={4000} step={100} value={tweaks.goal} onChange={(v) => setTweak('goal', v)} />
          </TweakSection>
          <TweakSection label="Home state">
            <TweakRadio label="State" value={tweaks.homeState} onChange={(v) => setTweak('homeState', v)} options={[
              { value: 'normal', label: 'Normal' },
              { value: 'dehydrated', label: 'Low' },
              { value: 'goal', label: 'Goal' },
              { value: 'night', label: 'Night' },
            ]} />
            <TweakToggle label="Hot weather (34°C)" value={tweaks.hot} onChange={(v) => setTweak('hot', v)} />
          </TweakSection>
          <TweakSection label="Layout">
            <TweakToggle label="Show all screens (canvas)" value={tweaks.showAllScreens} onChange={(v) => setTweak('showAllScreens', v)} />
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
        <DCSection id="primary" title="AquaTrack" subtitle="Living Drop · Coach · Ecosystem · Stats · Level · Log">

          <DCArtboard id="home" label="01 · Home (Living Drop)" width={420} height={870}>
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

          <DCArtboard id="coach" label="02 · AI Coach" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <CoachScreen current={1450} goal={goal} onLog={() => {}} onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="eco" label="03 · Ecosystem (Body)" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <EcosystemScreen current={1750} goal={goal} onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="stats" label="04 · Stats (Wave)" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <StatsScreen onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="level" label="05 · Level & Achievements" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <LevelScreen onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="log" label="06 · Log Drink" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <LogScreen current={1450} goal={goal} onLog={() => {}} onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="camera" label="07 · Smart Scan (Camera)" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <CameraScreen onNavigate={() => {}} onLog={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="profile" label="08 · Profile" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <ProfileScreen onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

          <DCArtboard id="friends" label="09 · Friends & Leaderboard" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <FriendsScreen onNavigate={() => {}} />
            </IOSDevice>
          </DCArtboard>

        </DCSection>

        <DCSection id="states" title="Home — State Variants" subtitle="Empathic UI reacts to context">
          <DCArtboard id="s-low" label="Dehydrated · 22%" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <HomeScreen state="dehydrated" current={Math.round(goal * 0.22)} goal={goal} />
            </IOSDevice>
          </DCArtboard>
          <DCArtboard id="s-normal" label="Normal · 58%" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <HomeScreen state="normal" current={Math.round(goal * 0.58)} goal={goal} />
            </IOSDevice>
          </DCArtboard>
          <DCArtboard id="s-hot" label="Hot weather · 45%" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <HomeScreen state="normal" hot current={Math.round(goal * 0.45)} goal={goal} />
            </IOSDevice>
          </DCArtboard>
          <DCArtboard id="s-goal" label="Goal reached · 94%" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <HomeScreen state="goal" current={Math.round(goal * 0.94)} goal={goal} />
            </IOSDevice>
          </DCArtboard>
          <DCArtboard id="s-night" label="Late night · auto-dim" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <HomeScreen state="night" current={Math.round(goal * 0.78)} goal={goal} />
            </IOSDevice>
          </DCArtboard>
        </DCSection>

        <DCSection id="eco-states" title="Ecosystem — Hydration response" subtitle="Body as world: dry → blooming">
          <DCArtboard id="e-low" label="Dehydrated · desert" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <EcosystemScreen current={Math.round(goal * 0.25)} goal={goal} />
            </IOSDevice>
          </DCArtboard>
          <DCArtboard id="e-mid" label="Recovering · mid" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <EcosystemScreen current={Math.round(goal * 0.6)} goal={goal} />
            </IOSDevice>
          </DCArtboard>
          <DCArtboard id="e-high" label="Blooming · 95%" width={420} height={870}>
            <IOSDevice width={390} height={844} dark>
              <EcosystemScreen current={Math.round(goal * 0.95)} goal={goal} />
            </IOSDevice>
          </DCArtboard>
        </DCSection>

        <DCSection id="widgets" title="Widgets & Lock screen" subtitle="1-tap log without opening app">
          <DCArtboard id="w-small" label="Small widget · 2×2" width={220} height={220}>
            <SmallWidget current={1450} goal={goal} />
          </DCArtboard>
          <DCArtboard id="w-medium" label="Medium widget · 4×2" width={460} height={220}>
            <MediumWidget current={1450} goal={goal} />
          </DCArtboard>
          <DCArtboard id="w-lock" label="Lock screen widget" width={300} height={220}>
            <LockWidget current={1450} goal={goal} />
          </DCArtboard>
        </DCSection>
      </DesignCanvas>

      <TweaksPanel>
        <TweakSection label="Home state preview">
          <TweakRadio label="State" value={tweaks.homeState} onChange={(v) => setTweak('homeState', v)} options={[
            { value: 'normal', label: 'Normal' },
            { value: 'dehydrated', label: 'Low' },
            { value: 'goal', label: 'Goal' },
            { value: 'night', label: 'Night' },
          ]} />
          <TweakToggle label="Hot weather" value={tweaks.hot} onChange={(v) => setTweak('hot', v)} />
          <TweakSlider label="Daily goal" min={1500} max={4000} step={100} value={tweaks.goal} onChange={(v) => setTweak('goal', v)} />
        </TweakSection>
        <TweakSection label="Mode">
          <TweakToggle label="Canvas (all screens)" value={tweaks.showAllScreens} onChange={(v) => setTweak('showAllScreens', v)} />
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
