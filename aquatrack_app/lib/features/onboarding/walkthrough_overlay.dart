import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/app_providers.dart';
import '../../core/utils/logger.dart';
import 'walkthrough_targets.dart';

/// One spotlight stop: a widget to cut out of the scrim, plus what to say
/// about it.
@immutable
class WalkthroughStep {
  final GlobalKey targetKey;
  final String title;
  final String body;

  /// Corner radius of the cut-out. Circular targets (the FAB) pass a big
  /// number and get clamped to a true circle.
  final double radius;

  const WalkthroughStep({
    required this.targetKey,
    required this.title,
    required this.body,
    this.radius = 14,
  });
}

/// First-run walkthrough over the real UI (ADR-style note: coach marks, not a
/// separate carousel, so what the user is told is anchored to what they will
/// actually tap).
///
/// Shown once per install, right after the nav shell first mounts on the home
/// route. The "seen" flag is versioned — bump [seenKey] to re-show it to
/// existing users after the tour materially changes.
class WalkthroughHost {
  const WalkthroughHost._();

  static const String _tag = 'Walkthrough';
  static const String seenKey = 'walkthrough_seen_v1';

  /// Guards against a second insert while one is already on screen (a rebuild
  /// of the shell must not stack two overlays).
  static bool _showing = false;

  /// Not `const`: [WalkthroughTargets] holds GlobalKeys, which never are.
  static final List<WalkthroughStep> defaultSteps = [
    WalkthroughStep(
      targetKey: WalkthroughTargets.water,
      title: 'Màn hình chính',
      body:
          'Giọt nước đầy dần theo lượng bạn uống trong ngày. Nhấn vào giọt để '
          'ghi nhanh một ly.',
    ),
    WalkthroughStep(
      targetKey: WalkthroughTargets.smartScan,
      title: 'Chụp ảnh, AI đếm ml',
      body:
          'Không cần nhập tay. Chụp ly nước của bạn, AI ước lượng dung tích và '
          'ghi vào nhật ký.',
      radius: 999,
    ),
    WalkthroughStep(
      targetKey: WalkthroughTargets.coach,
      title: 'AI Coach',
      body:
          'Hỏi bất cứ điều gì về thói quen uống nước. Coach đọc dữ liệu thật '
          'của bạn để trả lời, không nói chung chung.',
    ),
    WalkthroughStep(
      targetKey: WalkthroughTargets.missions,
      title: 'Nhiệm vụ hằng ngày',
      body: 'Hoàn thành nhiệm vụ để nhận XP và xu, lên cấp và mở avatar mới.',
    ),
    WalkthroughStep(
      targetKey: WalkthroughTargets.friends,
      title: 'Bạn bè',
      body:
          'Kết bạn, so kè trên bảng xếp hạng tuần, gửi quà và thách đấu nhau '
          'uống đủ nước.',
    ),
    WalkthroughStep(
      targetKey: WalkthroughTargets.more,
      title: 'Còn nữa ở đây',
      body: 'Thống kê chi tiết và Cấp độ nằm trong nút "Thêm".',
    ),
  ];

  /// Show the tour unless this install has already seen it.
  ///
  /// Never throws: a storage failure must not block the user from reaching the
  /// home screen, so it is logged and treated as "already seen".
  static Future<void> maybeShow(
    BuildContext context,
    WidgetRef ref, {
    List<WalkthroughStep>? steps,
  }) async {
    if (_showing) return;

    final storage = ref.read(storageServiceProvider);
    bool alreadySeen = true;
    try {
      alreadySeen = (await storage.getBool(seenKey)) ?? false;
    } catch (e) {
      AppLogger.error(_tag, 'Could not read $seenKey, skipping walkthrough', e);
      return;
    }
    if (alreadySeen || !context.mounted) return;

    show(
      context,
      steps: steps,
      onFinished: () async {
        try {
          await storage.setBool(seenKey, true);
        } catch (e) {
          // Worst case the tour shows again next launch — better than crashing.
          AppLogger.error(_tag, 'Could not persist $seenKey', e);
        }
      },
    );
  }

  /// Force the tour on, ignoring the seen flag. Public so a "Xem lại hướng
  /// dẫn" entry in Profile can replay it later; for now only tests call it.
  static void show(
    BuildContext context, {
    List<WalkthroughStep>? steps,
    VoidCallback? onFinished,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      AppLogger.error(_tag, 'No root Overlay available, skipping walkthrough');
      return;
    }

    _showing = true;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _WalkthroughView(
        steps: steps ?? defaultSteps,
        onClose: () {
          if (!_showing) return;
          _showing = false;
          entry.remove();
          onFinished?.call();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _WalkthroughView extends StatefulWidget {
  final List<WalkthroughStep> steps;
  final VoidCallback onClose;

  const _WalkthroughView({required this.steps, required this.onClose});

  @override
  State<_WalkthroughView> createState() => _WalkthroughViewState();
}

class _WalkthroughViewState extends State<_WalkthroughView> {
  /// Steps whose target actually rendered. A tab hidden behind a sheet, or a
  /// FAB on a screen we are not on, would otherwise spotlight empty space.
  List<WalkthroughStep> _steps = const [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Targets only have a RenderBox after the frame that mounted them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final laidOut =
          widget.steps.where((s) => _rectFor(s.targetKey) != null).toList();
      if (laidOut.isEmpty) {
        widget.onClose();
        return;
      }
      setState(() => _steps = laidOut);
    });
  }

  Rect? _rectFor(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_index >= _steps.length - 1) {
      widget.onClose();
      return;
    }
    setState(() => _index++);
  }

  void _skip() {
    HapticFeedback.lightImpact();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    // Nothing measured yet — paint nothing rather than a bare scrim flash.
    if (_steps.isEmpty) return const SizedBox.shrink();

    final step = _steps[_index];
    final screen = MediaQuery.sizeOf(context);
    final target = _rectFor(step.targetKey);
    // A target can disappear mid-tour (orientation change); fall back to a
    // centred card with no cut-out instead of crashing.
    final hole = target?.inflate(8);
    final isLast = _index == _steps.length - 1;

    return Material(
      type: MaterialType.transparency,
      child: Semantics(
        container: true,
        label: 'Hướng dẫn sử dụng, bước ${_index + 1} trên ${_steps.length}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _next,
          child: Stack(
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<Rect?>(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  tween: RectTween(begin: hole, end: hole),
                  builder: (context, animated, _) => CustomPaint(
                    painter: _SpotlightPainter(
                      hole: animated ?? hole,
                      radius: step.radius,
                    ),
                  ),
                ),
              ),
              _buildCard(screen, hole, isLast),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Size screen, Rect? hole, bool isLast) {
    const margin = 16.0;
    final width = math.min(screen.width - margin * 2, 360.0);

    // Put the card on the roomier side of the cut-out. The nav bar and the FAB
    // both sit low, so in practice this resolves to "above".
    final below = hole == null || hole.center.dy < screen.height / 2;
    final card = _StepCard(
      width: width,
      title: _steps[_index].title,
      body: _steps[_index].body,
      index: _index,
      total: _steps.length,
      isLast: isLast,
      onNext: _next,
      onSkip: _skip,
    );

    if (hole == null) {
      return Center(child: card);
    }
    return Positioned(
      left: (screen.width - width) / 2,
      top: below ? hole.bottom + 16 : null,
      bottom: below ? null : screen.height - hole.top + 16,
      child: card,
    );
  }
}

class _StepCard extends StatelessWidget {
  final double width;
  final String title;
  final String body;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _StepCard({
    required this.width,
    required this.title,
    required this.body,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (int i = 0; i < total; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Container(
                    width: i == index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == index
                          ? AppColors.cyan
                          : AppColors.textSecondary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  'Bỏ qua',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isLast ? 'Xong' : 'Tiếp',
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dims the whole screen except a rounded cut-out over the current target.
class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final double radius;

  const _SpotlightPainter({required this.hole, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = const Color(0xE60D1B2A); // AppColors.background @ 90%
    final full = Path()..addRect(Offset.zero & size);

    if (hole == null) {
      canvas.drawPath(full, scrim);
      return;
    }

    // Clamp so a "999" radius becomes a true circle rather than an assert.
    final r = Radius.circular(
      math.min(radius, math.min(hole!.width, hole!.height) / 2),
    );
    final cutout = RRect.fromRectAndRadius(hole!, r);

    canvas.drawPath(
      Path.combine(PathOperation.difference, full, Path()..addRRect(cutout)),
      scrim,
    );
    canvas.drawRRect(
      cutout,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.cyan.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.radius != radius;
}
