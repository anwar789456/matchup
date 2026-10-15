import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_text_field.dart';
import 'src/interaction.dart';

/// Checkbox (components/Checkbox.md): a 20 px box with a label row that is entirely tappable
/// (min 44 high). [value] null is the indeterminate state (with [tristate]).
class MuCheckbox extends StatelessWidget {
  const MuCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.labelSpan,
    this.description,
    this.error,
    this.tristate = false,
    this.semanticLabel,
  });

  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final String? label;

  /// Rich label (with a link, e.g. « conditions d'utilisation »), used instead of [label].
  final InlineSpan? labelSpan;
  final String? description;
  final String? error;
  final bool tristate;

  /// Name for a bare checkbox without a visible label (table rows).
  final String? semanticLabel;

  // Checkbox.md: 20 × 20 box, 1.5 px border, 14 px mark, pressed scale 0.9, description 2 px
  // under the label.
  static const double _box = 20;
  static const double _border = 1.5;
  static const double _mark = 14;
  static const double _pressScale = 0.9;
  static const double _descriptionGap = 2;

  bool get _enabled => onChanged != null;

  void _toggle() {
    if (!_enabled) return;
    if (tristate) {
      onChanged!(value == false ? true : (value == true ? null : false));
    } else {
      onChanged!(!(value ?? false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final checked = value ?? true; // indeterminate draws filled with a dash
    final on = value != false;
    final hasError = error != null;

    final (Color fill, Color border) = !_enabled
        ? (c.disabledFill, c.borderStrong)
        : on
            ? (c.primary, c.primary)
            : hasError
                ? (c.errorSoft, c.error)
                : (c.surface, c.borderControl);
    final markColor = _enabled ? c.onPrimary : c.textDisabled;

    final box = MuPressScale(
      enabled: _enabled,
      scale: _pressScale,
      child: AnimatedContainer(
        duration: MuMotion.durationOf(context, MuMotion.fast),
        curve: MuMotion.enter,
        width: _box,
        height: _box,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: MuRadius.xsAll,
          border: Border.all(color: border, width: _border),
        ),
        child: AnimatedSwitcher(
          duration: MuMotion.durationOf(context, MuMotion.base),
          switchInCurve: MuMotion.enter,
          child: on
              ? Icon(
                  checked && value != null
                      ? PhosphorIcons.check(PhosphorIconsStyle.bold)
                      : PhosphorIcons.minus(PhosphorIconsStyle.bold),
                  key: ValueKey(value),
                  size: _mark,
                  color: markColor,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );

    final hasLabel = label != null || labelSpan != null;
    final labelStyle = (description != null ? MuType.label : MuType.body)
        .copyWith(color: _enabled ? c.text : c.textDisabled);

    final content = hasLabel
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              box,
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(labelSpan ?? TextSpan(text: label), style: labelStyle),
                    if (description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: _descriptionGap),
                        child: Text(
                          description!,
                          style: MuType.body.copyWith(
                              color: _enabled ? c.textSecondary : c.textDisabled),
                        ),
                      ),
                    if (error != null) ...[
                      const SizedBox(height: MuSpace.s1),
                      MuFieldMessage.error(error!),
                    ],
                  ],
                ),
              ),
            ],
          )
        : box;

    return MergeSemantics(
      child: Semantics(
        checked: value == true,
        mixed: tristate && value == null,
        enabled: _enabled,
        label: semanticLabel,
        child: MuFocusRing(
          borderRadius: MuRadius.smAll,
          child: InkWell(
            onTap: _enabled ? _toggle : null,
            borderRadius: MuRadius.smAll,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: MuSize.touchTarget,
                minWidth: MuSize.touchTarget,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: hasLabel ? MuSpace.s3 : 0),
                child: hasLabel ? content : Center(widthFactor: 1, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled group of [MuCheckbox] rows (role group), with an optional group error.
class MuCheckboxGroup extends StatelessWidget {
  const MuCheckboxGroup({
    super.key,
    required this.label,
    required this.children,
    this.description,
    this.error,
  });

  final String label;
  final String? description;
  final String? error;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: MuType.label.copyWith(color: c.text)),
          if (description != null)
            Text(description!, style: MuType.body.copyWith(color: c.textSecondary)),
          ...children,
          if (error != null) MuFieldMessage.error(error!),
        ],
      ),
    );
  }
}
