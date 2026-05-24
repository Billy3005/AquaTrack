import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_text_styles.dart';

/// Shared CoinBadge component - displays coin amount with tap to shop navigation
class CoinBadge extends StatefulWidget {
  final int amount;
  final double? size;
  final bool showPlusButton;

  const CoinBadge({
    super.key,
    required this.amount,
    this.size,
    this.showPlusButton = false,
  });

  @override
  State<CoinBadge> createState() => _CoinBadgeState();
}

class _CoinBadgeState extends State<CoinBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    _pressController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp() {
    _pressController.reverse();
  }

  void _handleTap() {
    context.push('/shop');
  }

  @override
  Widget build(BuildContext context) {
    final coinSize = widget.size ?? 13.0;
    final fontSize = (widget.size ?? 13.0) * 0.85;
    final padding = EdgeInsets.fromLTRB(
      coinSize * 0.46, // left
      coinSize * 0.31, // top
      widget.showPlusButton ? coinSize * 0.46 : coinSize * 0.69, // right
      coinSize * 0.31, // bottom
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _handleTapDown(),
            onTapUp: (_) => _handleTapUp(),
            onTapCancel: _handleTapUp,
            onTap: _handleTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x2DFBBF24), // rgba(251,191,36,0.18)
                    Color(0x0FF59E0B), // rgba(245,158,11,0.06)
                  ],
                ),
                border: Border.all(
                  color: const Color(0x73FBBF24), // rgba(251,191,36,0.45)
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.06),
                    blurRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCoinIcon(coinSize),
                  SizedBox(width: coinSize * 0.38),
                  Text(
                    _formatAmount(widget.amount),
                    style: AppTextStyles.caption.copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFDE68A),
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 0.01,
                    ),
                  ),
                  if (widget.showPlusButton) ...[
                    SizedBox(width: coinSize * 0.31),
                    Container(
                      width: coinSize * 0.92,
                      height: coinSize * 0.92,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        color: const Color(0xFFFDE68A),
                        size: coinSize * 0.61,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoinIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.3),
          radius: 0.75,
          colors: [
            Color(0xFFFEF3C7), // Light cream
            Color(0xFFFBBF24), // Gold
            Color(0xFFB45309), // Dark gold border
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF78350F), width: size * 0.046),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.35),
            blurRadius: size * 0.31,
            offset: Offset(0, size * 0.15),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.38,
          height: size * 0.38,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.2, -0.2),
              radius: 0.8,
              colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}K';
    } else {
      return amount.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]}.',
          );
    }
  }
}

/// Large CoinBadge variant for prominent display (like wallet cards)
class LargeCoinBadge extends StatelessWidget {
  final int amount;
  final VoidCallback? onTap;
  final String? subtitle;

  const LargeCoinBadge({
    super.key,
    required this.amount,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/shop'),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x29FBBF24), // rgba(251,191,36,0.16)
              Color(0x0FF59E0B), // rgba(245,158,11,0.06)
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x66FBBF24),
          ), // rgba(251,191,36,0.4)
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  gradient: const RadialGradient(
                    center: Alignment(-0.4, -0.4),
                    colors: [Color(0xFFFEF3C7), Color(0xFFB45309)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.monetization_on,
                  color: Color(0xFF451A03),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFFFCD34D),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatLargeAmount(amount),
                          style: AppTextStyles.headingMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'xu',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFFFDE68A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFFFDE68A).withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLargeAmount(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
  }
}
