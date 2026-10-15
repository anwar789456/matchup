import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_text_field.dart';
import 'src/interaction.dart';

/// One option of a [MuSelect].
@immutable
class MuSelectOption<T> {
  const MuSelectOption({
    required this.value,
    required this.label,
    this.description,
    this.icon,
    this.enabled = true,
  });

  final T value;
  final String label;
  final String? description;

  /// Sport icon or Phosphor icon, 20 px.
  final Widget? icon;
  final bool enabled;
}

/// Select (components/Select.md): one value from a list. The trigger is the TextField box with
/// a caret that turns while open; the options open in a popover under it (same width, max 360
/// high), or in a bottom sheet below 600 px.
class MuSelect<T> extends StatefulWidget {
  const MuSelect({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.helper,
    this.error,
    this.size = MuFieldSize.l,
    this.hideLabel = false,
  });

  final String label;
  final List<MuSelectOption<T>> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String? placeholder;
  final String? helper;
  final String? error;
  final MuFieldSize size;

  /// Keeps the label for screen readers only (table cells such as opening hours).
  final bool hideLabel;

  @override
  State<MuSelect<T>> createState() => _MuSelectState<T>();
}

class _MuSelectState<T> extends State<MuSelect<T>> {
  final _menu = MenuController();
  bool _open = false;
  bool _hovered = false;

  // Select.md: popover max 360 high; options ≥ 44 (56 in the bottom sheet).
  static const double _popoverMax = 360;
  static const double _sheetRow = 56;

  bool get _enabled => widget.onChanged != null;

  MuSelectOption<T>? get _selected =>
      widget.options.where((o) => o.value == widget.value).firstOrNull;

  void _pick(T value) {
    _menu.close();
    widget.onChanged?.call(value);
  }

  Future<void> _openSheet() async {
    final c = context.mu;
    setState(() => _open = true);
    final picked = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * MuSize.sheetHalf,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s2),
                child: Text(widget.label, style: MuType.h3.copyWith(color: c.text)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
                  children: [
                    for (final o in widget.options)
                      _OptionRow<T>(
                        option: o,
                        selected: o.value == widget.value,
                        minHeight: _sheetRow,
                        onTap: () => Navigator.of(context).pop(o.value),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _open = false);
    if (picked != null) widget.onChanged?.call(picked);
  }

  void _toggle() {
    if (!_enabled) return;
    if (MediaQuery.sizeOf(context).width < MuLayout.bpMedium) {
      _openSheet();
    } else if (_menu.isOpen) {
      _menu.close();
    } else {
      _menu.open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final large = widget.size == MuFieldSize.l;
    final height = large ? MuSize.controlL : MuSize.controlM;
    final valueStyle = large ? MuType.bodyL : MuType.body;
    final selected = _selected;
    final hasError = widget.error != null;
    final duration = MuMotion.durationOf(context, MuMotion.base);

    final Color borderColor;
    final double borderWidth;
    if (!_enabled) {
      (borderColor, borderWidth) = (c.border, 1);
    } else if (_open) {
      (borderColor, borderWidth) = (hasError ? c.error : c.focus, 2);
    } else if (hasError) {
      (borderColor, borderWidth) = (c.error, 1);
    } else if (_hovered) {
      (borderColor, borderWidth) = (c.textSecondary, 1);
    } else {
      (borderColor, borderWidth) = (c.borderControl, 1);
    }

    final trigger = MenuAnchor(
      controller: _menu,
      onOpen: () => setState(() => _open = true),
      onClose: () => setState(() => _open = false),
      alignmentOffset: const Offset(0, MuSpace.s1),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.surfaceElevated),
        elevation: const WidgetStatePropertyAll(MuElevation.materialLevel2),
        shadowColor: WidgetStatePropertyAll(MuElevation.of(context).shadowColor),
        shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: MuRadius.lgAll)),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(MuSpace.s2)),
        maximumSize: const WidgetStatePropertyAll(Size(double.infinity, _popoverMax)),
      ),
      menuChildren: [
        Builder(
          // Same width as the trigger, measured when the menu opens.
          builder: (_) => SizedBox(
            width: (context.findRenderObject() as RenderBox?)?.size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final o in widget.options)
                  _OptionRow<T>(
                    option: o,
                    selected: o.value == widget.value,
                    minHeight: MuSize.touchTarget,
                    onTap: () => _pick(o.value),
                  ),
              ],
            ),
          ),
        ),
      ],
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: MuFocusRing(
          borderRadius: MuRadius.smAll,
          forceVisible: true,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: _enabled ? _toggle : null,
              borderRadius: MuRadius.smAll,
              child: AnimatedContainer(
                duration: MuMotion.durationOf(context, MuMotion.fast),
                height: height,
                padding: const EdgeInsetsDirectional.only(start: MuSpace.s4, end: MuSpace.s3),
                decoration: BoxDecoration(
                  color: _enabled ? c.surface : c.disabledFill,
                  borderRadius: MuRadius.smAll,
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
                child: Row(
                  children: [
                    if (selected?.icon != null) ...[
                      selected!.icon!,
                      const SizedBox(width: MuSpace.s2),
                    ],
                    Expanded(
                      child: Text(
                        selected?.label ?? widget.placeholder ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: valueStyle.copyWith(
                          color: !_enabled
                              ? c.textDisabled
                              : (selected == null ? c.textSecondary : c.text),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: duration,
                      curve: MuMotion.move,
                      child: Icon(PhosphorIcons.caretDown(),
                          size: MuSize.iconS, color: _enabled ? c.textSecondary : c.textDisabled),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: widget.label,
      value: selected?.label,
      expanded: _open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.hideLabel) ...[
            ExcludeSemantics(
              child: MuFieldLabel(label: widget.label, enabled: _enabled),
            ),
            const SizedBox(height: MuSpace.s2),
          ],
          trigger,
          if (widget.error != null || widget.helper != null) ...[
            const SizedBox(height: MuSpace.s1),
            widget.error != null
                ? MuFieldMessage.error(widget.error!)
                : MuFieldMessage.helper(widget.helper!),
          ],
        ],
      ),
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.minHeight,
    required this.onTap,
  });

  final MuSelectOption<T> option;
  final bool selected;
  final double minHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final enabled = option.enabled;
    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: MuRadius.smAll,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
            child: Row(
              children: [
                if (option.icon != null) ...[option.icon!, const SizedBox(width: MuSpace.s3)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.label,
                        style: (selected ? MuType.label : MuType.body)
                            .copyWith(color: enabled ? c.text : c.textDisabled),
                      ),
                      if (option.description != null)
                        Text(option.description!,
                            style: MuType.caption.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                if (selected) Icon(PhosphorIcons.check(), size: MuSize.iconS, color: c.text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
