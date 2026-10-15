import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Shrinks its child while a pointer is down (`scale-press`, `duration-fast`, `ease-enter`).
/// Stays still under reduced motion.
class MuPressScale extends StatefulWidget {
  const MuPressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = MuMotion.pressScale,
  });

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<MuPressScale> createState() => _MuPressScaleState();
}

class _MuPressScaleState extends State<MuPressScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.enabled ? (_) => _set(true) : null,
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed && widget.enabled ? widget.scale : 1.0,
        duration: MuMotion.durationOf(context, MuMotion.fast),
        curve: MuMotion.enter,
        child: widget.child,
      ),
    );
  }
}

/// Draws the keyboard `focus-ring` (2px gap + 2px `focus`) around [child] while any focusable
/// descendant has keyboard focus. Never shown for touch.
class MuFocusRing extends StatefulWidget {
  const MuFocusRing({
    super.key,
    required this.child,
    required this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.forceVisible = false,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final BoxShape shape;

  /// Show the ring whatever the input mode (fields show it on any focus).
  final bool forceVisible;

  @override
  State<MuFocusRing> createState() => _MuFocusRingState();
}

class _MuFocusRingState extends State<MuFocusRing> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode _) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final keyboard =
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final visible = _focused && (keyboard || widget.forceVisible);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (value) => setState(() => _focused = value),
      child: AnimatedContainer(
        duration: MuMotion.durationOf(context, MuMotion.fast),
        curve: MuMotion.enter,
        decoration: BoxDecoration(
          shape: widget.shape,
          borderRadius:
              widget.shape == BoxShape.circle ? null : widget.borderRadius,
          boxShadow: visible ? MuElevation.of(context).focusRing : const [],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Flips a directional icon (arrows, carets) in right-to-left layouts.
class MuDirectionalIcon extends StatelessWidget {
  const MuDirectionalIcon(this.icon, {super.key, this.size, this.color});

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: Directionality.of(context) == TextDirection.rtl,
      child: Icon(icon, size: size, color: color),
    );
  }
}
