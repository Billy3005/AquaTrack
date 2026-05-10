import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Enhanced card widget with prototype-matching shadows and borders
class EnhancedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final bool showShadow;
  final bool showBorder;
  final bool showGlow;
  final VoidCallback? onTap;

  const EnhancedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    this.width,
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 20,
    this.showShadow = true,
    this.showBorder = true,
    this.showGlow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (backgroundColor ?? AppColors.surfaceColor).withValues(alpha: 0.6),
            (backgroundColor ?? AppColors.surfaceColorSoft)
                .withValues(alpha: 0.4),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(
                color: (borderColor ?? AppColors.borderColor)
                    .withValues(alpha: 0.2),
                width: 1,
              )
            : null,
        boxShadow: showShadow
            ? [
                // Primary shadow
                BoxShadow(
                  color: AppColors.cyanDeep.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
                // Secondary shadow
                BoxShadow(
                  color: AppColors.overlay.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
                // Glow effect (conditional)
                if (showGlow)
                  BoxShadow(
                    color: AppColors.cyanAccent.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 6,
                    offset: const Offset(0, 4),
                  ),
              ]
            : null,
      ),
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              ),
            )
          : Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
    );
  }
}

/// Specialized card variants for common use cases

class StatsCard extends EnhancedCard {
  const StatsCard({
    super.key,
    required super.child,
    super.padding = const EdgeInsets.all(24),
    super.showGlow = false,
  });
}

class ActionCard extends EnhancedCard {
  const ActionCard({
    super.key,
    required super.child,
    required super.onTap,
    super.padding = const EdgeInsets.all(20),
    super.showGlow = true,
  });
}

class InfoCard extends EnhancedCard {
  const InfoCard({
    super.key,
    required super.child,
    super.padding = const EdgeInsets.all(18),
    super.backgroundColor = AppColors.cyanDeep,
    super.borderColor = AppColors.cyanAccent,
    super.showGlow = true,
  });
}
