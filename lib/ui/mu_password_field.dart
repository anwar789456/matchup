import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_icon_button.dart';
import 'mu_text_field.dart';

/// A requirement shown in the PasswordField checklist.
@immutable
class MuPasswordRule {
  const MuPasswordRule(this.label, this.test);

  final String label;
  final bool Function(String value) test;
}

abstract final class MuPasswordRules {
  /// The sign-up rules (AUTH-01): « 8 caractères minimum », « Une majuscule », « Un chiffre ».
  static final List<MuPasswordRule> standard = [
    MuPasswordRule('8 caractères minimum', (v) => v.length >= 8),
    MuPasswordRule('Une majuscule', (v) => v.contains(RegExp(r'[A-ZÀ-Ý]'))),
    MuPasswordRule('Un chiffre', (v) => v.contains(RegExp(r'\d'))),
  ];

  static bool allMet(String value, [List<MuPasswordRule>? rules]) =>
      (rules ?? standard).every((r) => r.test(value));
}

/// Strength score 0–4 (PasswordField.md): one point each for 8+ characters, upper and lower case,
/// a digit, a symbol or 12+ characters; under 8 characters it is always 1 (« Faible »).
/// 0 only for an empty value.
int passwordScore(String value) {
  if (value.isEmpty) return 0;
  if (value.length < 8) return 1;
  var points = 1;
  if (value.contains(RegExp(r'[a-zà-ÿ]')) && value.contains(RegExp(r'[A-ZÀ-Ý]'))) points++;
  if (value.contains(RegExp(r'\d'))) points++;
  if (value.length >= 12 || value.contains(RegExp(r'[^A-Za-z0-9À-ÿ]'))) points++;
  return points;
}

/// PasswordField (components/PasswordField.md): a MuTextField with a show/hide toggle and, for
/// new passwords, a 4-segment strength meter and a live checklist of [rules].
///
/// Set [showRuleErrors] after a failed submit: unmet rules turn into errors.
class MuPasswordField extends StatefulWidget {
  const MuPasswordField({
    super.key,
    this.label = 'Mot de passe',
    this.controller,
    this.focusNode,
    this.size = MuFieldSize.l,
    this.placeholder,
    this.helper,
    this.error,
    this.success,
    this.labelAside,
    this.strength = false,
    this.rules,
    this.showRuleErrors = false,
    this.enabled = true,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final MuFieldSize size;
  final String? placeholder;
  final String? helper;
  final String? error;
  final String? success;
  final Widget? labelAside;
  final bool strength;
  final List<MuPasswordRule>? rules;
  final bool showRuleErrors;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<MuPasswordField> createState() => _MuPasswordFieldState();
}

class _MuPasswordFieldState extends State<MuPasswordField> {
  TextEditingController? _own;
  bool _visible = false;

  TextEditingController get _controller => widget.controller ?? _own!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _own = TextEditingController();
    _controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(MuPasswordField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _own)?.removeListener(_rebuild);
      if (widget.controller == null) _own ??= TextEditingController();
      _controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _own?.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isNew = widget.strength || widget.rules != null;
    final value = _controller.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MuTextField(
          label: widget.label,
          controller: _controller,
          focusNode: widget.focusNode,
          size: widget.size,
          placeholder: widget.placeholder,
          helper: widget.helper,
          error: widget.error,
          success: widget.success,
          labelAside: widget.labelAside,
          enabled: widget.enabled,
          obscureText: !_visible,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: widget.textInputAction,
          autofillHints: [isNew ? AutofillHints.newPassword : AutofillHints.password],
          autocorrect: false,
          enableSuggestions: false,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          trailing: MuIconButton(
            icon: _visible ? PhosphorIcons.eyeSlash() : PhosphorIcons.eye(),
            label: _visible ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
            size: MuIconButtonSize.s,
            onPressed: widget.enabled ? () => setState(() => _visible = !_visible) : null,
          ),
        ),
        if (widget.strength) ...[
          const SizedBox(height: MuSpace.s3),
          _StrengthMeter(score: passwordScore(value)),
        ],
        if (widget.rules != null) ...[
          const SizedBox(height: MuSpace.s3),
          for (final (i, rule) in widget.rules!.indexed) ...[
            if (i > 0) const SizedBox(height: MuSpace.s1),
            _RuleRow(
              label: rule.label,
              met: rule.test(value),
              failed: widget.showRuleErrors,
            ),
          ],
        ],
      ],
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.score});

  final int score;

  // PasswordField.md: 4 segments of 4 px; the level label sits in a 64 px end slot.
  static const double _bar = 4;
  static const double _labelSlot = 64;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final (String label, MuTone? tone) = switch (score) {
      1 => ('Faible', MuTone.error),
      2 => ('Moyen', MuTone.warning),
      3 => ('Bon', MuTone.info),
      4 => ('Excellent', MuTone.success),
      _ => ('Sécurité', null),
    };
    final duration = MuMotion.durationOf(context, MuMotion.base);
    return Semantics(
      liveRegion: true,
      label: 'Sécurité du mot de passe : $label',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: MuSpace.s1),
            Expanded(
              child: AnimatedContainer(
                duration: duration,
                curve: MuMotion.enter,
                height: _bar,
                decoration: BoxDecoration(
                  color: tone != null && i < score ? tone.color(c) : c.border,
                  borderRadius: MuRadius.fullAll,
                ),
              ),
            ),
          ],
          SizedBox(
            width: _labelSlot,
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: MuType.labelS.copyWith(color: tone?.text(c) ?? c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.met, required this.failed});

  final String label;
  final bool met;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final (IconData icon, Color iconColor, Color textColor) = met
        ? (PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), c.successText, c.text)
        : failed
            ? (PhosphorIcons.xCircle(PhosphorIconsStyle.fill), c.errorText, c.errorText)
            : (PhosphorIcons.circle(), c.textSecondary, c.textSecondary);
    return Semantics(
      label: '$label, ${met ? 'fait' : 'à faire'}',
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(icon, size: MuSize.iconXs, color: iconColor),
          const SizedBox(width: MuSpace.s2),
          Expanded(child: Text(label, style: MuType.caption.copyWith(color: textColor))),
        ],
      ),
    );
  }
}
