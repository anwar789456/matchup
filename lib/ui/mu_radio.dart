import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'mu_text_field.dart';
import 'src/interaction.dart';

/// One option of a [MuRadioGroup].
@immutable
class MuRadioOption<T> {
  const MuRadioOption({required this.value, required this.label, this.description, this.enabled = true});

  final T value;
  final String label;
  final String? description;
  final bool enabled;
}

/// Radio (components/Radio.md): one choice among a few. 20 px circle, 2 px `primary` ring and
/// 10 px dot when selected; the whole 44 px row is the target. [horizontal] lays 2–3 short
/// options side by side, `space-6` apart.
class MuRadioGroup<T> extends StatelessWidget {
  const MuRadioGroup({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.description,
    this.error,
    this.horizontal = false,
    this.hideLabel = false,
  });

  final String label;
  final String? description;
  final List<MuRadioOption<T>> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String? error;
  final bool horizontal;

  /// The label stays for screen readers only (a section heading already says it).
  final bool hideLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final rows = [
      for (final o in options)
        _MuRadioRow<T>(
          option: o,
          selected: o.value == value,
          error: error != null,
          onTap: onChanged == null || !o.enabled ? null : () => onChanged!(o.value),
        ),
    ];
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hideLabel) Text(label, style: MuType.label.copyWith(color: c.text)),
          if (description != null)
            Text(description!, style: MuType.body.copyWith(color: c.textSecondary)),
          if (!hideLabel || description != null) const SizedBox(height: MuSpace.s2),
          if (horizontal)
            Wrap(spacing: MuSpace.s6, children: rows)
          else
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
          if (error != null) MuFieldMessage.error(error!),
        ],
      ),
    );
  }
}

class _MuRadioRow<T> extends StatelessWidget {
  const _MuRadioRow({
    required this.option,
    required this.selected,
    required this.error,
    required this.onTap,
  });

  final MuRadioOption<T> option;
  final bool selected;
  final bool error;
  final VoidCallback? onTap;

  // Radio.md: 20 px circle, 1,5 px edge (2 px when selected), 10 px dot, pressed scale 0.9.
  static const double _circle = 20;
  static const double _edge = 1.5;
  static const double _edgeOn = 2;
  static const double _dot = 10;
  static const double _pressScale = 0.9;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final enabled = onTap != null;
    final duration = MuMotion.durationOf(context, MuMotion.fast);
    final circle = MuPressScale(
      enabled: enabled,
      scale: _pressScale,
      child: AnimatedContainer(
        duration: duration,
        width: _circle,
        height: _circle,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: !enabled ? c.disabledFill : (error ? c.errorSoft : c.surface),
          border: Border.all(
            color: selected
                ? (enabled ? c.primary : c.textDisabled)
                : (error ? c.error : c.borderControl),
            width: selected ? _edgeOn : _edge,
          ),
        ),
        child: AnimatedScale(
          scale: selected ? 1 : 0,
          duration: duration,
          curve: MuMotion.pop,
          child: Container(
            width: _dot,
            height: _dot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? c.primary : c.textDisabled,
            ),
          ),
        ),
      ),
    );

    return MergeSemantics(
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        enabled: enabled,
        child: MuFocusRing(
          borderRadius: MuRadius.smAll,
          child: InkWell(
            onTap: onTap,
            borderRadius: MuRadius.smAll,
            focusColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: MuSize.touchTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    circle,
                    const SizedBox(width: MuSpace.s3),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            option.label,
                            style: (option.description != null ? MuType.label : MuType.body)
                                .copyWith(color: enabled ? c.text : c.textDisabled),
                          ),
                          if (option.description != null)
                            Text(option.description!,
                                style: MuType.body.copyWith(color: c.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
