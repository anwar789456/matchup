import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_icon_button.dart';
import 'src/interaction.dart';

enum MuStepperSize { m, s }

enum MuStepperLayout { stacked, inline }

/// Stepper (components/Stepper.md): a small whole number between bounds with − and + — players,
/// places to fill — and a helper with the price per person, announced politely as it changes.
///
/// It reads as one adjustable control (« 4 places, 10 joueurs · 15 DT chacun »); the digits slide
/// up on increase and down on decrease.
class MuStepper extends StatefulWidget {
  const MuStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.label,
    this.helper,
    this.unit,
    this.size = MuStepperSize.m,
    this.layout = MuStepperLayout.inline,
    this.decrementLabel = 'Retirer',
    this.incrementLabel = 'Ajouter',
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;
  final String label;

  /// Under the label: « 10 joueurs · 15 DT chacun ».
  final String Function(int value)? helper;

  /// Read after the value (« places »).
  final String? unit;
  final MuStepperSize size;
  final MuStepperLayout layout;
  final String decrementLabel;
  final String incrementLabel;

  @override
  State<MuStepper> createState() => _MuStepperState();
}

class _MuStepperState extends State<MuStepper> {
  bool _up = true;

  // Stepper.md: value box min 64 × 40 (S 40 × 32).
  static const Size _box = Size(64, 40);
  static const Size _boxS = Size(40, 32);
  static const int _page = 5;

  bool get _enabled => widget.onChanged != null;

  void _set(int v) {
    final next = v.clamp(widget.min, widget.max);
    if (next == widget.value) return;
    setState(() => _up = next > widget.value);
    widget.onChanged?.call(next);
  }

  KeyEventResult _onKey(KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final v = widget.value;
    int? next;
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.arrowRight) next = v + 1;
    if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.arrowLeft) next = v - 1;
    if (k == LogicalKeyboardKey.pageUp) next = v + _page;
    if (k == LogicalKeyboardKey.pageDown) next = v - _page;
    if (k == LogicalKeyboardKey.home) next = widget.min;
    if (k == LogicalKeyboardKey.end) next = widget.max;
    if (next == null) return KeyEventResult.ignored;
    _set(next);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final small = widget.size == MuStepperSize.s;
    final v = widget.value;
    final ink = _enabled ? c.text : c.textDisabled;
    final helper = widget.helper?.call(v);
    final box = small ? _boxS : _box;
    final duration = MuMotion.durationOf(context, MuMotion.fast);
    final unit = widget.unit == null ? '' : ' ${widget.unit}';

    final number = ConstrainedBox(
      constraints: BoxConstraints(minWidth: box.width, minHeight: box.height),
      child: Center(
        child: AnimatedSwitcher(
          duration: duration,
          transitionBuilder: (child, animation) {
            final incoming = child.key == ValueKey(v);
            final dy = (_up ? 0.45 : -0.45) * (incoming ? 1 : -1);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: Offset(0, dy), end: Offset.zero).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            '$v',
            key: ValueKey(v),
            style: (small ? MuType.numM : MuType.numL).copyWith(color: ink),
          ),
        ),
      ),
    );

    final control = Semantics(
      label: widget.label,
      value: '$v$unit${helper == null ? '' : ', $helper'}',
      increasedValue: v < widget.max ? '${v + 1}$unit' : null,
      decreasedValue: v > widget.min ? '${v - 1}$unit' : null,
      onIncrease: _enabled && v < widget.max ? () => _set(v + 1) : null,
      onDecrease: _enabled && v > widget.min ? () => _set(v - 1) : null,
      child: Focus(
        canRequestFocus: _enabled,
        onKeyEvent: (_, e) => _onKey(e),
        child: Builder(
          builder: (context) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MuIconButton(
                icon: PhosphorIcons.minus(),
                label: widget.decrementLabel,
                variant: MuIconButtonVariant.secondary,
                size: small ? MuIconButtonSize.s : MuIconButtonSize.m,
                onPressed: _enabled && v > widget.min ? () => _set(v - 1) : null,
              ),
              SizedBox(width: small ? MuSpace.s1 : MuSpace.s2),
              MuFocusRing(
                borderRadius: MuRadius.smAll,
                forceVisible: Focus.of(context).hasFocus,
                child: ExcludeSemantics(child: number),
              ),
              SizedBox(width: small ? MuSpace.s1 : MuSpace.s2),
              MuIconButton(
                icon: PhosphorIcons.plus(),
                label: widget.incrementLabel,
                variant: MuIconButtonVariant.secondary,
                size: small ? MuIconButtonSize.s : MuIconButtonSize.m,
                onPressed: _enabled && v < widget.max ? () => _set(v + 1) : null,
              ),
            ],
          ),
        ),
      ),
    );

    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: MuType.label.copyWith(color: ink)),
        if (helper != null)
          Semantics(
            liveRegion: true,
            child: Text(
              helper,
              style: MuType.body.copyWith(color: _enabled ? c.textSecondary : c.textDisabled),
            ),
          ),
      ],
    );

    if (widget.layout == MuStepperLayout.inline) {
      return Row(
        children: [
          Expanded(child: ExcludeSemantics(child: texts)),
          const SizedBox(width: MuSpace.s3),
          control,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: MuType.label.copyWith(color: ink)),
        const SizedBox(height: MuSpace.s2),
        control,
        if (helper != null) ...[
          const SizedBox(height: MuSpace.s2),
          Text(helper, style: MuType.body.copyWith(color: c.textSecondary)),
        ],
      ],
    );
  }
}
