import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'src/interaction.dart';

enum MuSwitchSize { m, s }

/// Switch (components/Switch.md): an on/off setting that applies at once. 48 × 28 (S 36 × 20),
/// outlined when off, `primary` with a checked knob when on. With [label] the whole row (≥ 44) is
/// the target; [labelAtStart] makes a settings row with [icon] · label + description · switch.
class MuSwitch extends StatefulWidget {
  const MuSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.description,
    this.icon,
    this.size = MuSwitchSize.m,
    this.labelAtStart = false,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final String? description;
  final IconData? icon;
  final MuSwitchSize size;
  final bool labelAtStart;

  /// Name when there is no visible label.
  final String? semanticLabel;

  @override
  State<MuSwitch> createState() => _MuSwitchState();
}

class _MuSwitchState extends State<MuSwitch> {
  bool _hovered = false;
  bool _pressed = false;

  // Switch.md: M 48 × 28, knob 16 → 20, check 12; S 36 × 20, knob 12 → 14, check 10;
  // 1,5 px outline when off; the knob stretches 6 px while pressed.
  static const _m = (w: 48.0, h: 28.0, off: 16.0, on: 20.0, check: 12.0);
  static const _s = (w: 36.0, h: 20.0, off: 12.0, on: 14.0, check: 10.0);
  static const double _outline = 1.5;
  static const double _stretch = 6;

  bool get _enabled => widget.onChanged != null;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final d = widget.size == MuSwitchSize.m ? _m : _s;
    final on = widget.value;
    final duration = MuMotion.durationOf(context, MuMotion.fast);

    final Color track;
    final Color knob;
    final Color edge;
    if (!_enabled) {
      track = c.disabledFill;
      knob = on ? c.surface : c.textDisabled;
      edge = c.disabledFill;
    } else if (on) {
      track = _hovered ? c.primaryHover : c.primary;
      knob = c.onPrimary;
      edge = track;
    } else {
      track = c.surface;
      knob = _hovered ? c.textSecondary : c.borderControl;
      edge = _hovered ? c.text : c.borderControl;
    }
    final knobSize = on ? d.on : d.off;
    final knobWidth = knobSize + (_pressed && _enabled ? _stretch : 0);
    final inset = (d.h - knobSize) / 2;

    final switchBox = MuFocusRing(
      borderRadius: MuRadius.fullAll,
      child: AnimatedContainer(
        duration: duration,
        curve: MuMotion.move,
        width: d.w,
        height: d.h,
        decoration: BoxDecoration(
          color: track,
          borderRadius: MuRadius.fullAll,
          border: Border.all(color: edge, width: _outline),
        ),
        child: Stack(
          children: [
            AnimatedPositionedDirectional(
              duration: duration,
              curve: MuMotion.move,
              start: on ? d.w - knobWidth - inset - _outline : inset - _outline,
              top: inset - _outline,
              width: knobWidth,
              height: knobSize,
              child: Container(
                decoration: BoxDecoration(color: knob, borderRadius: MuRadius.fullAll),
                alignment: Alignment.center,
                child: on
                    ? Icon(PhosphorIcons.check(PhosphorIconsStyle.bold),
                        size: d.check, color: _enabled ? c.primary : c.textDisabled)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );

    final hasLabel = widget.label != null;
    final labelColumn = hasLabel
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label!,
                style: (widget.description != null ? MuType.label : MuType.body)
                    .copyWith(color: _enabled ? c.text : c.textDisabled),
              ),
              if (widget.description != null)
                Text(
                  widget.description!,
                  style: MuType.body.copyWith(color: _enabled ? c.textSecondary : c.textDisabled),
                ),
            ],
          )
        : null;
    final gap = widget.size == MuSwitchSize.m ? MuSpace.s3 : MuSpace.s2;

    final Widget row;
    if (!hasLabel) {
      row = switchBox;
    } else if (widget.labelAtStart) {
      row = Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: MuSize.iconM, color: c.textSecondary),
            const SizedBox(width: MuSpace.s3),
          ],
          Expanded(child: labelColumn!),
          SizedBox(width: gap),
          switchBox,
        ],
      );
    } else {
      row = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            widget.description != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [switchBox, SizedBox(width: gap), Flexible(child: labelColumn!)],
      );
    }

    return MergeSemantics(
      child: Semantics(
        toggled: on,
        enabled: _enabled,
        label: widget.semanticLabel,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
            onTap: _enabled ? () => widget.onChanged!(!on) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: MuSize.touchTarget,
                minWidth: MuSize.touchTarget,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: widget.labelAtStart ? null : 1,
                child: row,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
