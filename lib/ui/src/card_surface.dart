import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'interaction.dart';

/// The `mu-card` surface shared by the card components: `surface`, `radius-md`, `elevation-1`
/// (hairline in Night match), `elevation-2` on hover, `scale-press` when pressed, focus ring.
class MuCardSurface extends StatefulWidget {
  const MuCardSurface({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(MuSpace.s4),
    this.color,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Overrides `surface` (e.g. `surface-elevated` on the welcome illustrations).
  final Color? color;
  final String? semanticLabel;

  @override
  State<MuCardSurface> createState() => _MuCardSurfaceState();
}

class _MuCardSurfaceState extends State<MuCardSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final e = MuElevation.of(context);
    final interactive = widget.onTap != null;
    Widget card = AnimatedContainer(
      duration: MuMotion.durationOf(context, MuMotion.fast),
      curve: MuMotion.enter,
      decoration: BoxDecoration(
        color: widget.color ?? c.surface,
        borderRadius: MuRadius.mdAll,
        boxShadow: _hovered && interactive ? e.level2 : e.level1,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onHover: interactive ? (v) => setState(() => _hovered = v) : null,
          borderRadius: MuRadius.mdAll,
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
    if (interactive) {
      card = MuFocusRing(
        borderRadius: MuRadius.mdAll,
        child: MuPressScale(child: card),
      );
    }
    return Semantics(container: true, label: widget.semanticLabel, child: card);
  }
}
