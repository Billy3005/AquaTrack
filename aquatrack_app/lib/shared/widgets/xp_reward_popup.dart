import 'package:flutter/material.dart';

/// A floating "+N XP" reward that rises and fades — the same celebratory
/// feedback used for quick-logging water. Self-contained via an [OverlayEntry]
/// so any screen can trigger it with one call, no animation state to wire in.
///
/// ```dart
/// XpRewardPopup.show(context, amount: 50, label: 'Cuộc Trò Chuyện Đầu Tiên');
/// ```
class XpRewardPopup {
  static void show(BuildContext context, {required int amount, String? label}) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _XpRewardOverlay(
        amount: amount,
        label: label,
        onDone: entry.remove,
      ),
    );
    overlay.insert(entry);
  }
}

class _XpRewardOverlay extends StatefulWidget {
  final int amount;
  final String? label;
  final VoidCallback onDone;

  const _XpRewardOverlay({
    required this.amount,
    required this.label,
    required this.onDone,
  });

  @override
  State<_XpRewardOverlay> createState() => _XpRewardOverlayState();
}

class _XpRewardOverlayState extends State<_XpRewardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final v = _t.value;
        // Fade in for the first 80%, then fade out quickly — float upward.
        final opacity =
            (v < 0.8 ? v * 1.25 : (1.0 - v) * 5).clamp(0.0, 1.0).toDouble();
        return Positioned(
          top: size.height * 0.42 - (v * 70),
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+${widget.amount} XP',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFDE68A),
                        shadows: [
                          Shadow(
                            color:
                                const Color(0xFFFBBF24).withValues(alpha: 0.6),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                    if (widget.label != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.label!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'SF Pro Text',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
