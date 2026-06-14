import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Level-up celebration — a Dart port of `aquatrack/project/components/levelup.jsx`.
///
/// Water-themed: navy radial backdrop, rotating sunburst rays, expanding ripple
/// rings, teardrop confetti, a hexagon level badge with glow + conic shine, the
/// "ĐÃ LÊN CẤP" headline, an XP bar that surges to fill, and reward chips
/// (coins). Auto-plays on mount; the "Tuyệt vời!" button (or backdrop) closes.
///
/// Shown via [LevelUpOverlayHost.show] from the shell whenever
/// levelNotifierProvider reports a level increase.
class LevelUpOverlay extends StatefulWidget {
  final int fromLevel;
  final int toLevel;
  final int currentXp;
  final int xpForNextLevel;
  final int coinsAwarded;
  final String rankName;
  final VoidCallback onDone;

  const LevelUpOverlay({
    super.key,
    required this.fromLevel,
    required this.toLevel,
    required this.currentXp,
    required this.xpForNextLevel,
    required this.coinsAwarded,
    required this.rankName,
    required this.onDone,
  });

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  // Design palette (from levelup.jsx — water-themed celebration).
  static const _cyanLight = Color(0xFF7DD3FC);
  static const _cyan = Color(0xFF38BDF8);
  static const _cyanDeep = Color(0xFF0EA5E9);
  static const _indigo = Color(0xFFA5B4FC);
  static const _gold = Color(0xFFFBBF24);
  static const _goldSoft = Color(0xFFFDE68A);

  late final AnimationController _spin; // sunburst + conic shine
  late final AnimationController _glow; // badge halo pulse
  late final AnimationController _ripple; // expanding rings
  late final AnimationController _confetti; // teardrop fall (one-shot)

  late final List<_Drop> _drops;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..forward();

    final rnd = math.Random();
    const palette = [
      _cyanLight,
      _cyan,
      _cyanDeep,
      _indigo,
      _gold,
      Color(0xFFBAE6FD),
    ];
    _drops = List.generate(22, (i) {
      return _Drop(
        left: 0.04 + rnd.nextDouble() * 0.92,
        size: 7 + rnd.nextDouble() * 12,
        color: palette[i % palette.length],
        delay: 0.05 + rnd.nextDouble() * 0.45,
        drift: (rnd.nextDouble() - 0.5) * 90,
        rot: (rnd.nextDouble() - 0.5) * 2 * math.pi,
      );
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    _glow.dispose();
    _ripple.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.xpForNextLevel > 0
        ? (widget.currentXp / widget.xpForNextLevel).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onDone,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.32),
              radius: 1.1,
              colors: [Color(0xFF15376B), Color(0xFF0A1B3A), Color(0xFF050B1C)],
              stops: [0.0, 0.48, 1.0],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _sunburst(),
              _rippleRings(),
              ..._confettiDrops(),
              // Tap-anywhere is the backdrop; the column ignores taps except
              // the explicit button, so content can sit above the gesture.
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _eyebrow(),
                    const SizedBox(height: 14),
                    _badge(),
                    const SizedBox(height: 14),
                    _headline(),
                    const SizedBox(height: 22),
                    _xpBar(pct),
                    if (widget.coinsAwarded > 0) ...[
                      const SizedBox(height: 18),
                      _rewardChip(),
                    ],
                    const SizedBox(height: 24),
                    _doneButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sunburst rays: rotating repeating sweep, faded to a soft disc ──────
  Widget _sunburst() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.18,
      child: Opacity(
        opacity: 0.55,
        child: RotationTransition(
          turns: _spin,
          child: Container(
            width: 620,
            height: 620,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0x297DD3FC),
                  Colors.transparent,
                  Color(0x297DD3FC),
                  Colors.transparent,
                ],
                stops: [0.0, 0.04, 0.07, 0.14],
                tileMode: TileMode.repeated,
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 900.ms, curve: Curves.easeOut),
    );
  }

  // ── Three expanding rings on a loop ───────────────────────────────────
  Widget _rippleRings() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.18 + 310 - 60,
      child: AnimatedBuilder(
        animation: _ripple,
        builder: (context, _) {
          return SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [0.0, 0.33, 0.66].map((phase) {
                final t = (_ripple.value + phase) % 1.0;
                final scale = 0.4 + t * 2.8;
                final opacity = (1.0 - t) * 0.6;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _cyanLight.withValues(alpha: opacity),
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  // ── Teardrop confetti rising and drifting ─────────────────────────────
  List<Widget> _confettiDrops() {
    final size = MediaQuery.of(context).size;
    return _drops.map((d) {
      return AnimatedBuilder(
        animation: _confetti,
        builder: (context, _) {
          final raw = (_confetti.value - d.delay) / (1 - d.delay);
          final t = raw.clamp(0.0, 1.0);
          if (t <= 0) return const SizedBox.shrink();
          final dy = size.height * 0.64 - t * 440;
          final dx = d.drift * t;
          final opacity = t < 0.12 ? t / 0.12 : (1.0 - t).clamp(0.0, 1.0);
          return Positioned(
            left: size.width * d.left + dx,
            top: dy,
            child: Opacity(
              opacity: opacity,
              child: Transform.rotate(
                angle: math.pi + d.rot * t,
                child: Container(
                  width: d.size,
                  height: d.size * 1.25,
                  decoration: BoxDecoration(
                    color: d.color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.elliptical(20, 26),
                      bottom: Radius.elliptical(20, 14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: d.color.withValues(alpha: 0.53),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _eyebrow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.auto_awesome, color: _cyanLight, size: 14),
        const SizedBox(width: 7),
        Text(
          'LÊN CẤP',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 4.0,
            color: _cyanLight.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(width: 7),
        const Icon(Icons.auto_awesome, color: _cyanLight, size: 14),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 600.ms).slideY(
          begin: 0.5,
          end: 0,
          delay: 150.ms,
          duration: 600.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _badge() {
    return SizedBox(
      width: 196,
      height: 196,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // glow halo
          AnimatedBuilder(
            animation: _glow,
            builder: (context, child) => Container(
              width: 196,
              height: 196,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _cyan.withValues(alpha: 0.30 + _glow.value * 0.25),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.68],
                ),
              ),
            ),
          ),
          // rotating conic shine ring
          RotationTransition(
            turns: _spin,
            child: Container(
              width: 164,
              height: 164,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.transparent,
                    Color(0xB3A5B4FC),
                    Colors.transparent,
                    Color(0xB37DD3FC),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.18, 0.4, 0.7, 0.95],
                ),
              ),
            ),
          ),
          // hexagon badge body
          ClipPath(
            clipper: _HexClipper(),
            child: Container(
              width: 148,
              height: 162,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF1E40AF),
                    Color(0xFF0C2A6B),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'LV',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.0,
                      color: const Color(0xFFBAE6FD).withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    '${widget.toLevel}',
                    style: const TextStyle(
                      fontSize: 72,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -2,
                      shadows: [
                        Shadow(color: Color(0x66000000), blurRadius: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1, 1),
          delay: 350.ms,
          duration: 700.ms,
          curve: Curves.elasticOut,
        );
  }

  Widget _headline() {
    return Column(
      children: [
        Text(
          'ĐÃ LÊN CẤP ${widget.toLevel}!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
            shadows: [Shadow(color: Color(0x9938BDF8), blurRadius: 26)],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lv ${widget.fromLevel}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: _cyanLight, size: 16),
            const SizedBox(width: 8),
            Text(
              widget.rankName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _goldSoft,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 550.ms, duration: 600.ms).slideY(
          begin: 0.4,
          end: 0,
          delay: 550.ms,
          duration: 600.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _xpBar(double pct) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ Lv ${widget.toLevel}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _cyanLight,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '${widget.currentXp} / ${widget.xpForNextLevel} XP',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF64748B),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 9,
              width: double.infinity,
              color: const Color(0xFF172A4A),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Animate(
                  effects: [
                    CustomEffect(
                      delay: 900.ms,
                      duration: 1100.ms,
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: pct * value,
                        child: child,
                      ),
                    ),
                  ],
                  child: Container(
                    height: 9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(
                        colors: [_cyanDeep, _cyan, _indigo],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _cyan.withValues(alpha: 0.8),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms, duration: 600.ms);
  }

  Widget _rewardChip() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: LinearGradient(
          colors: [
            _cyan.withValues(alpha: 0.12),
            _indigo.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: _cyanLight.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: _gold.withValues(alpha: 0.16),
              border: Border.all(color: _gold.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.monetization_on, color: _gold, size: 20),
          ),
          const SizedBox(width: 11),
          Text(
            '+${widget.coinsAwarded} xu',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE0F2FE),
            ),
          ),
          const Spacer(),
          const Icon(Icons.check, color: Color(0xFF86EFAC), size: 18),
        ],
      ),
    ).animate().fadeIn(delay: 1200.ms, duration: 500.ms).slideX(
          begin: -0.1,
          end: 0,
          delay: 1200.ms,
          duration: 500.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _doneButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.onDone,
          style: ElevatedButton.styleFrom(
            backgroundColor: _cyan,
            foregroundColor: const Color(0xFF04243F),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 8,
            shadowColor: _cyanDeep.withValues(alpha: 0.5),
          ),
          child: const Text(
            'Tuyệt vời!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 1500.ms, duration: 600.ms);
  }
}

class _Drop {
  final double left;
  final double size;
  final Color color;
  final double delay;
  final double drift;
  final double rot;

  const _Drop({
    required this.left,
    required this.size,
    required this.color,
    required this.delay,
    required this.drift,
    required this.rot,
  });
}

/// Rounded-hexagon badge clip (matches the levelup.jsx clip-path polygon).
class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Inserts [LevelUpOverlay] into the root overlay (above modal routes) and
/// removes it when dismissed. One at a time.
class LevelUpOverlayHost {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context, {
    required int fromLevel,
    required int toLevel,
    required int currentXp,
    required int xpForNextLevel,
    required int coinsAwarded,
    required String rankName,
    VoidCallback? onClosed,
  }) {
    hide();
    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (_) => LevelUpOverlay(
        fromLevel: fromLevel,
        toLevel: toLevel,
        currentXp: currentXp,
        xpForNextLevel: xpForNextLevel,
        coinsAwarded: coinsAwarded,
        rankName: rankName,
        onDone: () {
          hide();
          onClosed?.call();
        },
      ),
    );
    overlay.insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}
