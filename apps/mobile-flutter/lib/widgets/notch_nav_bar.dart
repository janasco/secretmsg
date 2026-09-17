import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Floating bottom bar with a sliding concave notch: the active tab rides in
/// a brand-violet bubble that glides between destinations while the valley
/// in the bar follows it. Icons-only (labels live in tooltips + semantics).
class NotchDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const NotchDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class NotchNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<NotchDestination> destinations;

  const NotchNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.destinations,
  });

  @override
  State<NotchNavBar> createState() => _NotchNavBarState();
}

class _NotchNavBarState extends State<NotchNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _position;
  int _iconIndex = 0;

  @override
  void initState() {
    super.initState();
    _iconIndex = widget.selectedIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _position = Tween<double>(
      begin: widget.selectedIndex.toDouble(),
      end: widget.selectedIndex.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));
    // The bubble icon swaps when the glide lands — swapping at tap time
    // briefly shows the new icon riding at the old tab.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _iconIndex = widget.selectedIndex);
      }
    });
  }

  @override
  void didUpdateWidget(NotchNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _position = Tween<double>(
        begin: _position.value,
        end: widget.selectedIndex.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tap(int i) {
    if (i == widget.selectedIndex) return;
    HapticFeedback.selectionClick();
    widget.onTap(i);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        child: SizedBox(
          height: 92,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barW = constraints.maxWidth;
              const barH = 64.0;
              const barTop = 22.0;
              const bubbleR = 27.0;
              final tabW = barW / widget.destinations.length;
              return AnimatedBuilder(
                animation: _position,
                builder: (context, _) {
                  final cx = tabW * (_position.value + 0.5);
                  final dest = widget.destinations[_iconIndex];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: barTop,
                        height: barH,
                        child: CustomPaint(
                          painter: _NotchPainter(
                            notchCenterX: cx,
                            fill: palette.surface,
                            border: palette.borderStrong,
                            shadow: Colors.black.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      // Inactive icons ride inside the bar.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: barTop,
                        height: barH,
                        child: Row(
                          children: [
                            for (var i = 0; i < widget.destinations.length; i++)
                              Expanded(
                                child: Semantics(
                                  button: true,
                                  selected: i == widget.selectedIndex,
                                  label: widget.destinations[i].label,
                                  child: Tooltip(
                                    message: widget.destinations[i].label,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _tap(i),
                                      child: Center(
                                        child: AnimatedOpacity(
                                          duration: const Duration(milliseconds: 200),
                                          opacity: i == _iconIndex ? 0 : 1,
                                          child: Icon(
                                            widget.destinations[i].icon,
                                            size: 23,
                                            color: palette.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // The bubble glides along the valley.
                      Positioned(
                        left: cx - bubbleR,
                        top: barTop - 20,
                        child: GestureDetector(
                          onTap: () => _tap(_iconIndex),
                          child: Container(
                            width: bubbleR * 2,
                            height: bubbleR * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: palette.accent.withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, anim) => ScaleTransition(
                                  scale: anim,
                                  child: FadeTransition(opacity: anim, child: child),
                                ),
                                child: Icon(
                                  dest.selectedIcon,
                                  key: ValueKey(_iconIndex),
                                  size: 25,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Bar silhouette: rounded pill with a concave valley carved from the top
/// edge at [notchCenterX]. Shadow is painted manually (a box shadow on the
/// parent would ignore the valley).
class _NotchPainter extends CustomPainter {
  final double notchCenterX;
  final Color fill;
  final Color border;
  final Color shadow;

  const _NotchPainter({
    required this.notchCenterX,
    required this.fill,
    required this.border,
    required this.shadow,
  });

  static const _radius = 26.0;
  static const _halfWidth = 30.0;
  static const _depth = 26.0;

  Path _path(Size size) {
    final w = size.width;
    final h = size.height;
    // Clamp only against the valley's own half-width: over-clamping (e.g. by
    // the corner radius) visibly detached the valley from the bubble on the
    // first and last tabs.
    final cx = notchCenterX.clamp(_halfWidth, w - _halfWidth);
    const hw = _halfWidth;
    const d = _depth;
    final p = Path()
      ..moveTo(0, h - _radius)
      ..quadraticBezierTo(0, h, _radius, h)
      ..lineTo(w - _radius, h)
      ..quadraticBezierTo(w, h, w, h - _radius)
      ..lineTo(w, _radius)
      ..quadraticBezierTo(w, 0, w - _radius, 0)
      ..lineTo(cx + hw, 0)
      ..cubicTo(cx + hw * 0.55, 0, cx + hw * 0.62, d, cx, d)
      ..cubicTo(cx - hw * 0.62, d, cx - hw * 0.55, 0, cx - hw, 0)
      ..lineTo(_radius, 0)
      ..quadraticBezierTo(0, 0, 0, _radius)
      ..close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    canvas.drawPath(
      path.shift(const Offset(0, 7)),
      Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(path, Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_NotchPainter old) =>
      old.notchCenterX != notchCenterX || old.fill != fill || old.border != border;
}

/// Hit area math helper (kept visible for tests).
double notchCenterFor(double barWidth, int tabCount, double position) =>
    math.max(0, barWidth) / math.max(1, tabCount) * (position + 0.5);
