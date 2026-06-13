import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_text_styles.dart';

/// Full-screen treasure-chest opening animation shown when the weekly chest
/// (weekly_bonus) is claimed. The chest drops in, rattles, bursts open with a
/// flash and rotating light rays, sprays gold coins, then reveals a "+N xu"
/// card. Tap anywhere (or the button) to dismiss.
Future<void> showChestReward(BuildContext context, {required int coins}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    barrierLabel: 'chest',
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => _ChestRewardDialog(coins: coins),
    transitionBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}

class _Coin {
  final double angle; // launch direction (radians)
  final double distance; // outward travel (px)
  final double size;
  final double spin; // total rotations
  final double delay; // 0..1 fraction of the burst window
  final Color color;

  const _Coin({
    required this.angle,
    required this.distance,
    required this.size,
    required this.spin,
    required this.delay,
    required this.color,
  });
}

class _ChestRewardDialog extends StatefulWidget {
  final int coins;
  const _ChestRewardDialog({required this.coins});

  @override
  State<_ChestRewardDialog> createState() => _ChestRewardDialogState();
}

class _ChestRewardDialogState extends State<_ChestRewardDialog>
    with TickerProviderStateMixin {
  late final AnimationController _c;
  late final AnimationController _rays; // continuous slow spin
  late final List<_Coin> _coins;
  bool _poppedHaptic = false;

  // Phase windows over the main controller's 0..1 timeline.
  static const _chestIn = Interval(0.04, 0.30, curve: Curves.easeOutBack);
  static const _shake = Interval(0.30, 0.46);
  static const _lid = Interval(0.46, 0.66, curve: Curves.easeOutCubic);
  static const _flash = Interval(0.46, 0.64, curve: Curves.easeOut);
  static const _burst = Interval(0.50, 1.0, curve: Curves.easeOut);
  static const _glow = Interval(0.50, 0.78, curve: Curves.easeOutBack);
  static const _card = Interval(0.66, 0.92, curve: Curves.easeOutBack);
  static const _count = Interval(0.66, 0.96, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    const palette = [
      Color(0xFFFCD34D),
      Color(0xFFFBBF24),
      Color(0xFFF59E0B),
      Color(0xFFFDE68A),
    ];
    _coins = List.generate(18, (i) {
      // Bias launch upward (−160°..−20°) so coins fountain out of the lid.
      final a = (-160 + rnd.nextDouble() * 140) * math.pi / 180;
      return _Coin(
        angle: a,
        distance: 90 + rnd.nextDouble() * 130,
        size: 12 + rnd.nextDouble() * 12,
        spin: 1 + rnd.nextDouble() * 3,
        delay: rnd.nextDouble() * 0.25,
        color: palette[rnd.nextInt(palette.length)],
      );
    });

    _rays = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..addListener(_onTick);

    HapticFeedback.lightImpact();
    _c.forward();
  }

  void _onTick() {
    // Fire a punchy haptic exactly when the lid bursts open.
    if (!_poppedHaptic && _c.value >= 0.50) {
      _poppedHaptic = true;
      HapticFeedback.heavyImpact();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _c.dispose();
    _rays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _c.value;
    final chestIn = _chestIn.transform(t);
    final shake = _shake.transform(t);
    final lid = _lid.transform(t);
    final flash = _flash.transform(t);
    final burst = _burst.transform(t);
    final glow = _glow.transform(t);
    final card = _card.transform(t);
    final count = _count.transform(t);

    final wiggle = math.sin(shake * math.pi * 6) * (1 - shake) * 0.05;
    final coinValue = (widget.coins * count).round();
    final finished = t >= 0.96;

    return GestureDetector(
      onTap: finished ? () => Navigator.of(context).maybePop() : null,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating light rays
                  if (glow > 0)
                    Transform.rotate(
                      angle: _rays.value * 2 * math.pi,
                      child: Transform.scale(
                        scale: 0.4 + glow * 1.1,
                        child: Opacity(
                          opacity:
                              (glow * (1.0 - 0.35 * burst)).clamp(0.0, 1.0),
                          child: CustomPaint(
                            size: const Size(240, 240),
                            painter: _RaysPainter(),
                          ),
                        ),
                      ),
                    ),

                  // Soft radial halo
                  if (glow > 0)
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFBBF24)
                                .withValues(alpha: 0.45 * glow),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                  // Coin burst
                  ..._coins.map((coin) => _buildCoin(coin, burst)),

                  // The chest itself
                  Transform.scale(
                    scale: (0.2 + chestIn * 0.8).clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: wiggle,
                      child: _buildChest(lid, flash),
                    ),
                  ),
                ],
              ),
            ),

            // Reward card
            if (card > 0)
              Opacity(
                opacity: card.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - card) * 16),
                  child: Transform.scale(
                    scale: 0.85 + 0.15 * card,
                    child: _buildRewardCard(coinValue, finished),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoin(_Coin coin, double burst) {
    // Stagger each coin, then play projectile motion (out + gravity down).
    final p = ((burst - coin.delay) / (1 - coin.delay)).clamp(0.0, 1.0);
    if (p <= 0) return const SizedBox.shrink();
    final out = Curves.easeOutCubic.transform(p);
    final dx = math.cos(coin.angle) * coin.distance * out;
    final dy = math.sin(coin.angle) * coin.distance * out + 200 * p * p;
    final opacity = (1.0 - math.pow(p, 2.2)).toDouble().clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(dx, dy - 8),
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: coin.spin * 2 * math.pi * p,
          child: Container(
            width: coin.size,
            height: coin.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [coin.color, const Color(0xFFB45309)],
              ),
              boxShadow: [
                BoxShadow(
                  color: coin.color.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Icon(Icons.monetization_on,
                size: coin.size * 0.62, color: const Color(0xFF78350F)),
          ),
        ),
      ),
    );
  }

  Widget _buildChest(double lid, double flash) {
    return SizedBox(
      width: 120,
      height: 104,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Light beam escaping the open lid
          if (flash > 0)
            Positioned(
              bottom: 34,
              child: Opacity(
                opacity: (flash * (1 - 0.4 * lid)).clamp(0.0, 1.0),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.9),
                        const Color(0xFFFDE68A).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Chest base
          Container(
            width: 120,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB45309), Color(0xFF78350F)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: const Color(0xFFFCD34D), width: 2),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Lock plate
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCD34D),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFF92400E)),
                  ),
                  child: const Icon(Icons.circle,
                      size: 7, color: Color(0xFF92400E)),
                ),
              ],
            ),
          ),

          // Chest lid — rotates open around its back (top) edge in 3D.
          Positioned(
            bottom: 56,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateX(lid * 2.1),
              child: Container(
                width: 120,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  border: Border.all(color: const Color(0xFFFCD34D), width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(int coinValue, bool finished) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'KHO BÁU CUỐI TUẦN',
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFFFCD34D),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBBF24),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.monetization_on,
                    size: 18, color: Color(0xFF78350F)),
              ),
              const SizedBox(width: 8),
              Text(
                '+$coinValue',
                style: AppTextStyles.headingMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 34,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'xu',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: const Color(0xFFFDE68A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          IgnorePointer(
            ignoring: !finished,
            child: AnimatedOpacity(
              opacity: finished ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'TUYỆT VỜI',
                    style: TextStyle(
                      color: Color(0xFF451A03),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Golden sunburst rays drawn behind the chest.
class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    const count = 12;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFFCD34D).withValues(alpha: 0.0),
        const Color(0xFFFBBF24).withValues(alpha: 0.55),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    for (var i = 0; i < count; i++) {
      final a = (i / count) * 2 * math.pi;
      const half = 0.16;
      final p1 =
          center + Offset(math.cos(a - half), math.sin(a - half)) * radius;
      final p2 =
          center + Offset(math.cos(a + half), math.sin(a + half)) * radius;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
