import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Level-up celebration overlay animation
class LevelUpCelebration extends StatefulWidget {
  final int newLevel;
  final String avatarEmoji;
  final VoidCallback? onAnimationComplete;
  final bool isVisible;

  const LevelUpCelebration({
    super.key,
    required this.newLevel,
    required this.avatarEmoji,
    this.onAnimationComplete,
    required this.isVisible,
  });

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _mainController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    if (widget.isVisible) {
      _startCelebration();
    }
  }

  @override
  void didUpdateWidget(LevelUpCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _startCelebration();
    }
  }

  void _startCelebration() {
    _confettiController.forward();
    _mainController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onAnimationComplete?.call();
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.background.withValues(alpha: 0.95),
        child: Stack(
          children: [
            // Background confetti
            ..._buildConfetti(),

            // Main celebration content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Level up text
                  Text(
                    'LEVEL UP!',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.xpPurple,
                      fontWeight: FontWeight.w900,
                      fontSize: 48,
                    ),
                  )
                      .animate(controller: _mainController)
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1.0, 1.0),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .shimmer(
                        duration: 1.5.seconds,
                        color: AppColors.cyan,
                      ),

                  const SizedBox(height: 20),

                  // New level badge
                  _LevelBadge(
                    level: widget.newLevel,
                    controller: _mainController,
                  ),

                  const SizedBox(height: 30),

                  // Avatar celebration
                  _AvatarCelebration(
                    emoji: widget.avatarEmoji,
                    controller: _mainController,
                  ),

                  const SizedBox(height: 40),

                  // Congratulations text
                  Text(
                    'Chúc mừng! Bạn đã đạt level ${widget.newLevel}',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate(controller: _mainController)
                      .fadeIn(
                        delay: 800.ms,
                        duration: 600.ms,
                      )
                      .slideY(
                        begin: 0.5,
                        end: 0.0,
                        delay: 800.ms,
                        duration: 600.ms,
                      ),

                  const SizedBox(height: 60),

                  // Tap to continue
                  Text(
                    'Tap để tiếp tục',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                  )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .fadeIn(delay: 1.5.seconds, duration: 600.ms)
                      .then()
                      .fade(
                        begin: 1.0,
                        end: 0.5,
                        duration: 1.seconds,
                      ),
                ],
              ),
            ),

            // Tap to dismiss
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onAnimationComplete,
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildConfetti() {
    final confettiPieces = <Widget>[];
    const colors = [
      AppColors.cyan,
      AppColors.xpPurple,
      AppColors.success,
      AppColors.warning,
    ];

    for (int i = 0; i < 30; i++) {
      confettiPieces.add(
        Positioned(
          left: (i * 30) % MediaQuery.of(context).size.width,
          top: -50,
          child: _ConfettiPiece(
            color: colors[i % colors.length],
            controller: _confettiController,
            delay: Duration(milliseconds: i * 100),
          ),
        ),
      );
    }

    return confettiPieces;
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final AnimationController controller;

  const _LevelBadge({
    required this.level,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.xpPurple, AppColors.cyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.xpPurple.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars,
            color: AppColors.textPrimary,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            'LEVEL $level',
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    )
        .animate(controller: controller)
        .scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1.0, 1.0),
          delay: 300.ms,
          duration: 800.ms,
          curve: Curves.bounceOut,
        )
        .rotate(
          begin: 0.0,
          end: 0.05,
          delay: 300.ms,
          duration: 200.ms,
        )
        .then()
        .rotate(
          begin: 0.05,
          end: -0.05,
          duration: 400.ms,
        )
        .then()
        .rotate(
          begin: -0.05,
          end: 0.0,
          duration: 200.ms,
        );
  }
}

class _AvatarCelebration extends StatelessWidget {
  final String emoji;
  final AnimationController controller;

  const _AvatarCelebration({
    required this.emoji,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.cyan.withValues(alpha: 0.3),
            AppColors.xpPurple.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 80),
        ),
      ),
    )
        .animate(controller: controller)
        .scale(
          begin: const Offset(0.0, 0.0),
          end: const Offset(1.0, 1.0),
          delay: 600.ms,
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
        .then()
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.1, 1.1),
          duration: 300.ms,
        )
        .then()
        .scale(
          begin: const Offset(1.1, 1.1),
          end: const Offset(1.0, 1.0),
          duration: 300.ms,
        );
  }
}

class _ConfettiPiece extends StatelessWidget {
  final Color color;
  final AnimationController controller;
  final Duration delay;

  const _ConfettiPiece({
    required this.color,
    required this.controller,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    )
        .animate(controller: controller)
        .slideY(
          begin: -1.0,
          end: 2.0,
          delay: delay,
          duration: 2.seconds,
          curve: Curves.easeInQuad,
        )
        .rotate(
          begin: 0.0,
          end: 6.0,
          delay: delay,
          duration: 2.seconds,
        )
        .fadeIn(
          delay: delay,
          duration: 200.ms,
        )
        .then()
        .fadeOut(
          duration: 500.ms,
        );
  }
}

/// Level-up celebration manager
class LevelUpCelebrationManager {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required int newLevel,
    required String avatarEmoji,
    VoidCallback? onComplete,
  }) {
    hide(); // Remove any existing celebration

    _currentOverlay = OverlayEntry(
      builder: (context) => LevelUpCelebration(
        newLevel: newLevel,
        avatarEmoji: avatarEmoji,
        isVisible: true,
        onAnimationComplete: () {
          hide();
          onComplete?.call();
        },
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}
