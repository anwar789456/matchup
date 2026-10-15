import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_text_field.dart';

/// Keeps the 8 Tunisian digits, drops a pasted 216 / 00216 country code, groups 2-3-3 and keeps
/// the caret after the same digit.
class MuPhoneFormatter extends TextInputFormatter {
  static const int maxDigits = 8;

  /// The raw digits of a formatted or pasted value.
  static String digitsOf(String text) {
    var d = text.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('00216')) {
      d = d.substring(5);
    } else if (d.startsWith('216') && d.length > maxDigits) {
      d = d.substring(3);
    }
    return d.length > maxDigits ? d.substring(0, maxDigits) : d;
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = digitsOf(newValue.text);
    // Digits before the caret in the new raw text, capped to what was kept.
    final caretRaw = newValue.selection.end.clamp(0, newValue.text.length);
    var before = newValue.text.substring(0, caretRaw).replaceAll(RegExp(r'\D'), '').length;
    final dropped = newValue.text.replaceAll(RegExp(r'\D'), '').length - digits.length;
    if (dropped > 0 && newValue.text.replaceAll(RegExp(r'\D'), '').startsWith(RegExp('(00)?216'))) {
      before = (before - dropped).clamp(0, digits.length);
    }
    before = before.clamp(0, digits.length);
    final text = groupPhoneDigits(digits);
    final offset = groupPhoneDigits(digits.substring(0, before)).length;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// PhoneField (components/PhoneField.md): a fixed « TN +216 » segment and 8 digits grouped
/// « 20 123 456 ». [onChanged] receives the raw digits. Shows « Le numéro doit contenir
/// 8 chiffres. » on blur when 1–7 digits are typed.
class MuPhoneField extends StatefulWidget {
  const MuPhoneField({
    super.key,
    this.label = 'Numéro de téléphone',
    this.controller,
    this.size = MuFieldSize.l,
    this.helper,
    this.error,
    this.success,
    this.optional = false,
    this.enabled = true,
    this.validateOnBlur = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final MuFieldSize size;
  final String? helper;
  final String? error;
  final String? success;
  final bool optional;
  final bool enabled;
  final bool validateOnBlur;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<MuPhoneField> createState() => _MuPhoneFieldState();
}

class _MuPhoneFieldState extends State<MuPhoneField> {
  final _focus = FocusNode();
  TextEditingController? _own;
  String? _blurError;

  TextEditingController get _controller => widget.controller ?? (_own ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus.dispose();
    _own?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focus.hasFocus || !widget.validateOnBlur) return;
    final n = MuPhoneFormatter.digitsOf(_controller.text).length;
    setState(() {
      _blurError = n > 0 && n < MuPhoneFormatter.maxDigits
          ? 'Le numéro doit contenir 8 chiffres.'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final large = widget.size == MuFieldSize.l;
    final valueStyle = (large ? MuType.bodyL : MuType.body)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MuTextField(
        label: widget.label,
        controller: _controller,
        focusNode: _focus,
        size: widget.size,
        placeholder: '20 123 456',
        helper: widget.helper,
        error: widget.error ?? _blurError,
        success: widget.success,
        optional: widget.optional,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        keyboardType: TextInputType.phone,
        autofillHints: const [AutofillHints.telephoneNumberNational],
        inputFormatters: [MuPhoneFormatter()],
        valueStyle: valueStyle,
        prefix: _CountrySegment(large: large, enabled: widget.enabled, valueStyle: valueStyle),
        onChanged: (v) {
          if (_blurError != null) setState(() => _blurError = null);
          widget.onChanged?.call(MuPhoneFormatter.digitsOf(v));
        },
        onSubmitted: widget.onSubmitted == null
            ? null
            : (v) => widget.onSubmitted!(MuPhoneFormatter.digitsOf(v)),
      ),
    );
  }
}

class _CountrySegment extends StatelessWidget {
  const _CountrySegment({required this.large, required this.enabled, required this.valueStyle});

  final bool large;
  final bool enabled;
  final TextStyle valueStyle;

  // PhoneField.md: the « TN » tag is 20 px high.
  static const double _tagHeight = 20;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final inset = large ? MuSpace.s3 : MuSpace.s2;
    return Semantics(
      label: 'Indicatif +216, Tunisie',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: large ? MuSpace.s4 : MuSpace.s3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: _tagHeight,
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: MuRadius.xsAll,
                border: Border.all(color: c.border),
              ),
              child: Text('TN', style: MuType.labelS.copyWith(color: c.textSecondary)),
            ),
            const SizedBox(width: MuSpace.s2),
            Text('+216', style: valueStyle.copyWith(color: enabled ? c.text : c.textDisabled)),
            const SizedBox(width: MuSpace.s3),
            Container(
              width: 1,
              height: (large ? MuSize.controlL : MuSize.controlM) - inset * 2,
              color: c.borderStrong,
            ),
            const SizedBox(width: MuSpace.s3),
          ],
        ),
      ),
    );
  }
}
