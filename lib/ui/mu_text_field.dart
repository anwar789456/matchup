import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_icon_button.dart';
import 'src/interaction.dart';

enum MuFieldSize { l, m }

/// TextField (components/TextField.md): visible label, field box, then helper / error / success
/// message with an optional counter. Every MatchUp input reuses it.
///
/// [maxLength] is a soft limit: text is never cut, the counter and message explain the overflow.
class MuTextField extends StatefulWidget {
  const MuTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.size = MuFieldSize.l,
    this.placeholder,
    this.helper,
    this.error,
    this.success,
    this.messageExtra,
    this.optional = false,
    this.labelAside,
    this.leadingIcon,
    this.prefix,
    this.prefixText,
    this.suffixText,
    this.trailing,
    this.clearable = false,
    this.maxLength,
    this.multiline = false,
    this.minLines = 3,
    this.maxLines = 8,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.textDirection,
    this.valueStyle,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final MuFieldSize size;
  final String? placeholder;
  final String? helper;
  final String? error;
  final String? success;

  /// Extra line under the message (e.g. « C'est le tien ? Se connecter »).
  final Widget? messageExtra;
  final bool optional;

  /// Widget at the end of the label row (e.g. « Mot de passe oublié ? »).
  final Widget? labelAside;
  final IconData? leadingIcon;

  /// Custom leading segment (PhoneField's « TN +216 »).
  final Widget? prefix;
  final String? prefixText;
  final String? suffixText;

  /// Trailing control inside the box (PasswordField's eye).
  final Widget? trailing;
  final bool clearable;
  final int? maxLength;
  final bool multiline;
  final int minLines;
  final int maxLines;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextDirection? textDirection;

  /// Overrides the value style (PhoneField uses tabular digits).
  final TextStyle? valueStyle;

  @override
  State<MuTextField> createState() => _MuTextFieldState();
}

class _MuTextFieldState extends State<MuTextField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  bool _hovered = false;

  TextEditingController get _controller => widget.controller ?? _ownController!;
  FocusNode get _focus => widget.focusNode ?? _ownFocus!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _ownController = TextEditingController();
    if (widget.focusNode == null) _ownFocus = FocusNode();
    _controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(MuTextField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _ownController)?.removeListener(_onText);
      if (widget.controller == null) _ownController ??= TextEditingController();
      _controller.addListener(_onText);
    }
    if (widget.focusNode == null) _ownFocus ??= FocusNode();
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _onText() {
    // Rebuild for the clear button and the counter.
    if (widget.clearable || widget.maxLength != null) setState(() {});
  }

  bool get _large => widget.size == MuFieldSize.l;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final length = _controller.text.characters.length;
    final over = widget.maxLength != null && length > widget.maxLength!;
    final error = widget.error ??
        (over
            ? '${length - widget.maxLength!} caractères en trop — raccourcis un peu ton texte.'
            : null);
    final hasError = error != null;

    final valueStyle = widget.valueStyle ?? (_large ? MuType.bodyL : MuType.body);
    final padStart = _large ? MuSpace.s4 : MuSpace.s3;
    final trailingPad = _large ? MuSpace.s2 : MuSpace.s1;
    final height = _large ? MuSize.controlL : MuSize.controlM;
    final lineHeight = valueStyle.fontSize! * valueStyle.height!;
    final vPad = widget.multiline ? MuSpace.s3 : (height - lineHeight) / 2;

    OutlineInputBorder outline(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: MuRadius.smAll,
          borderSide: BorderSide(color: color, width: width),
        );

    // Borders per state (TextField.md « Colours »). Errors are drawn here, not through
    // InputDecoration.errorText, so the message stays under our own control.
    final enabledBorder = !widget.enabled
        ? outline(c.border)
        : widget.readOnly
            ? outline(c.border)
            : hasError
                ? outline(c.error)
                : outline(_hovered ? c.textSecondary : c.borderControl);
    final focusedBorder = outline(hasError ? c.error : c.focus, 2);

    final showClear = widget.clearable &&
        widget.enabled &&
        !widget.readOnly &&
        _controller.text.isNotEmpty;

    Widget? leading;
    if (widget.prefix != null) {
      leading = widget.prefix;
    } else if (widget.leadingIcon != null) {
      leading = Padding(
        padding: EdgeInsetsDirectional.only(start: padStart, end: MuSpace.s2),
        child: Icon(widget.leadingIcon,
            size: MuSize.iconS,
            color: widget.enabled ? c.textSecondary : c.textDisabled),
      );
    }

    final trailingWidgets = <Widget>[
      if (showClear)
        MuIconButton(
          icon: PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
          label: 'Effacer',
          size: MuIconButtonSize.s,
          color: c.textSecondary,
          onPressed: () {
            _controller.clear();
            widget.onChanged?.call('');
          },
        ),
      ?widget.trailing,
    ];

    final field = TextField(
      controller: _controller,
      focusNode: _focus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      keyboardType: widget.multiline ? TextInputType.multiline : widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.enabled ? widget.autofillHints : null,
      inputFormatters: widget.inputFormatters,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textDirection: widget.textDirection,
      minLines: widget.multiline ? widget.minLines : 1,
      maxLines: widget.multiline ? widget.maxLines : 1,
      style: valueStyle.copyWith(color: widget.enabled ? c.text : c.textDisabled),
      cursorColor: c.focus,
      decoration: InputDecoration(
        isDense: true,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        counterText: '',
        hintText: widget.placeholder,
        hintStyle: valueStyle.copyWith(color: c.textSecondary),
        filled: true,
        fillColor: !widget.enabled
            ? c.disabledFill
            : (widget.readOnly ? c.surfaceMuted : c.surface),
        hoverColor: Colors.transparent,
        border: enabledBorder,
        enabledBorder: enabledBorder,
        focusedBorder: focusedBorder,
        disabledBorder: outline(c.border),
        contentPadding: EdgeInsetsDirectional.fromSTEB(
          leading == null ? padStart : 0,
          vPad,
          trailingWidgets.isEmpty ? padStart : trailingPad,
          vPad,
        ),
        prefixIcon: leading,
        prefixIconConstraints: const BoxConstraints(),
        prefixText: widget.prefixText == null ? null : '${widget.prefixText} ',
        prefixStyle: valueStyle.copyWith(color: c.textSecondary),
        suffixText: widget.suffixText == null ? null : ' ${widget.suffixText}',
        suffixStyle: valueStyle.copyWith(color: c.textSecondary),
        suffixIcon: trailingWidgets.isEmpty
            ? null
            : Padding(
                padding: EdgeInsetsDirectional.only(end: trailingPad),
                child: Row(mainAxisSize: MainAxisSize.min, children: trailingWidgets),
              ),
        suffixIconConstraints: BoxConstraints(minHeight: height),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MuFieldLabel(
          label: widget.label,
          optional: widget.optional,
          enabled: widget.enabled,
          aside: widget.labelAside,
        ),
        const SizedBox(height: MuSpace.s2),
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: MuFocusRing(borderRadius: MuRadius.smAll, forceVisible: true, child: field),
        ),
        if (error != null || widget.success != null || widget.helper != null ||
            widget.maxLength != null) ...[
          const SizedBox(height: MuSpace.s1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: error != null
                    ? MuFieldMessage.error(error)
                    : widget.success != null
                        ? MuFieldMessage.success(widget.success!)
                        : widget.helper != null
                            ? MuFieldMessage.helper(widget.helper!)
                            : const SizedBox.shrink(),
              ),
              if (widget.maxLength != null) ...[
                const SizedBox(width: MuSpace.s2),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '$length/${widget.maxLength}',
                    style: MuType.caption.copyWith(
                      color: over ? c.errorText : c.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
        if (widget.messageExtra != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: MuSpace.s5),
            child: widget.messageExtra!,
          ),
      ],
    );
  }
}

/// Field label row: `label` in `text` (`text-secondary` when disabled), « (facultatif) » for
/// optional fields, and an optional widget at the end.
class MuFieldLabel extends StatelessWidget {
  const MuFieldLabel({
    super.key,
    required this.label,
    this.optional = false,
    this.enabled = true,
    this.aside,
  });

  final String label;
  final bool optional;
  final bool enabled;
  final Widget? aside;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final text = Text.rich(
      TextSpan(children: [
        TextSpan(text: label),
        if (optional)
          TextSpan(
            text: ' (facultatif)',
            style: MuType.body.copyWith(color: c.textSecondary),
          ),
      ]),
      style: MuType.label.copyWith(color: enabled ? c.text : c.textSecondary),
    );
    if (aside == null) return text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Expanded(child: text), aside!],
    );
  }
}

enum MuFieldMessageKind { helper, error, success }

/// The message under a field: `caption`, with a 16 px fill icon for errors and success.
class MuFieldMessage extends StatelessWidget {
  const MuFieldMessage(this.text, {super.key, this.kind = MuFieldMessageKind.helper});

  const MuFieldMessage.helper(this.text, {super.key}) : kind = MuFieldMessageKind.helper;

  const MuFieldMessage.error(this.text, {super.key}) : kind = MuFieldMessageKind.error;

  const MuFieldMessage.success(this.text, {super.key}) : kind = MuFieldMessageKind.success;

  final String text;
  final MuFieldMessageKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final (IconData? icon, Color color) = switch (kind) {
      MuFieldMessageKind.helper => (null, c.textSecondary),
      MuFieldMessageKind.error =>
        (PhosphorIcons.warningCircle(PhosphorIconsStyle.fill), c.errorText),
      MuFieldMessageKind.success =>
        (PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), c.successText),
    };
    final message = Text(text, style: MuType.caption.copyWith(color: color));
    final Widget content = icon == null
        ? message
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: MuSize.iconXs, color: color),
              const SizedBox(width: MuSpace.s1),
              Expanded(child: message),
            ],
          );
    return Semantics(liveRegion: kind == MuFieldMessageKind.error, child: content);
  }
}
