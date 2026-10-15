import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import 'mu_button.dart';
import 'mu_spinner.dart';
import 'mu_text_field.dart';

/// OtpInput (components/OtpInput.md): six boxes for the SMS code, built on one hidden TextField so
/// auto-advance, backspace, paste and SMS autofill work natively.
///
/// [resendIn] starts a countdown « Renvoyer le code dans 0:45 », then shows the « Renvoyer le
/// code » link that calls [onResend]. It hides after [success].
class MuOtpInput extends StatefulWidget {
  const MuOtpInput({
    super.key,
    this.length = 6,
    this.controller,
    this.label = 'Code reçu par SMS',
    this.helper,
    this.error,
    this.success,
    this.verifying = false,
    this.disabled,
    this.resendIn,
    this.onResend,
    this.autofocus = false,
    this.onChanged,
    this.onCompleted,
  });

  final int length;
  final TextEditingController? controller;
  final String label;
  final String? helper;
  final String? error;

  /// Success message (« Numéro vérifié. »); non-null turns the boxes green.
  final String? success;
  final bool verifying;

  /// Non-null disables the input and says why (« Trop d'essais. Réessaie dans 10 minutes. »).
  final String? disabled;
  final Duration? resendIn;
  final VoidCallback? onResend;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<MuOtpInput> createState() => _MuOtpInputState();
}

class _MuOtpInputState extends State<MuOtpInput> with TickerProviderStateMixin {
  final _focus = FocusNode();
  TextEditingController? _own;
  Timer? _timer;
  int _secondsLeft = 0;

  late final AnimationController _shake =
      AnimationController(vsync: this, duration: MuMotion.slow);
  late final AnimationController _caret =
      AnimationController(vsync: this, duration: MuMotion.pulse ~/ 2);

  TextEditingController get _controller => widget.controller ?? (_own ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
    _focus.addListener(_rebuild);
    _startCountdown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _caret.value = 1;
      _caret.stop();
    } else if (!_caret.isAnimating) {
      _caret.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MuOtpInput old) {
    super.didUpdateWidget(old);
    if (widget.error != null && widget.error != old.error &&
        !MediaQuery.of(context).disableAnimations) {
      _shake.forward(from: 0);
    }
    if (widget.resendIn != old.resendIn) _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsLeft = widget.resendIn?.inSeconds ?? 0;
    if (_secondsLeft <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_rebuild);
    _own?.dispose();
    _focus.dispose();
    _shake.dispose();
    _caret.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  bool get _locked => widget.verifying || widget.disabled != null || widget.success != null;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final code = _controller.text;
    final active = _focus.hasFocus && !_locked ? math.min(code.length, widget.length - 1) : -1;

    final boxes = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.length; i++) ...[
          if (i > 0) const SizedBox(width: MuSpace.s2),
          Semantics(
            label: 'Chiffre ${i + 1} sur ${widget.length}',
            value: i < code.length ? code[i] : null,
            child: _Box(
              digit: i < code.length ? code[i] : null,
              active: i == active,
              caretFilled: i == active && i == code.length,
              caret: _caret,
              error: widget.error != null,
              success: widget.success != null,
              disabled: widget.disabled != null,
            ),
          ),
        ],
      ],
    );

    // The hidden field sits under the boxes and receives the taps.
    final input = Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              enabled: !_locked,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: widget.length,
              showCursor: false,
              enableInteractiveSelection: false,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              onChanged: (v) {
                widget.onChanged?.call(v);
                if (v.length == widget.length) widget.onCompleted?.call(v);
              },
            ),
          ),
        ),
        IgnorePointer(child: boxes),
      ],
    );

    final shaking = AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        // Three decaying swings over duration-slow.
        final t = _shake.value;
        final dx = math.sin(t * math.pi * 6) * (1 - t) * MuSpace.s2;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _locked ? null : () => _focus.requestFocus(),
        child: input,
      ),
    );

    Widget? message;
    if (widget.verifying) {
      message = Semantics(
        liveRegion: true,
        child: Row(children: [
          MuSpinner(size: MuSize.iconXs, color: c.textSecondary),
          const SizedBox(width: MuSpace.s2),
          Text('Vérification du code…', style: MuType.caption.copyWith(color: c.textSecondary)),
        ]),
      );
    } else if (widget.disabled != null) {
      message = MuFieldMessage.error(widget.disabled!);
    } else if (widget.error != null) {
      message = MuFieldMessage.error(widget.error!);
    } else if (widget.success != null) {
      message = MuFieldMessage.success(widget.success!);
    } else if (widget.helper != null) {
      message = MuFieldMessage.helper(widget.helper!);
    }

    final showResend = widget.success == null && (widget.resendIn != null || widget.onResend != null);

    return Semantics(
      container: true,
      label: widget.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MuFieldLabel(label: widget.label, enabled: widget.disabled == null),
          const SizedBox(height: MuSpace.s2),
          Directionality(textDirection: TextDirection.ltr, child: shaking),
          if (message != null) ...[
            const SizedBox(height: MuSpace.s2),
            message,
          ],
          if (showResend) ...[
            const SizedBox(height: MuSpace.s4),
            if (_secondsLeft > 0)
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Renvoyer le code dans '),
                  TextSpan(
                    text: '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                    style: MuType.numS.copyWith(color: c.text),
                  ),
                ]),
                style: MuType.body.copyWith(color: c.textSecondary),
              )
            else
              MuButton.link(
                label: 'Renvoyer le code',
                onPressed: widget.disabled != null || widget.verifying ? null : widget.onResend,
              ),
          ],
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.digit,
    required this.active,
    required this.caretFilled,
    required this.caret,
    required this.error,
    required this.success,
    required this.disabled,
  });

  final String? digit;
  final bool active;
  final bool caretFilled;
  final Animation<double> caret;
  final bool error;
  final bool success;
  final bool disabled;

  // OtpInput.md: a 2 × 28 caret.
  static const double _caretWidth = 2;
  static const double _caretHeight = 28;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final (Color fill, Color border, double width, Color text) = disabled
        ? (c.disabledFill, c.border, 1.0, c.textDisabled)
        : success
            ? (c.successSoft, c.success, 1.0, c.successText)
            : error
                ? (c.surface, c.error, active ? 2.0 : 1.0, c.text)
                : active
                    ? (c.surface, c.focus, 2.0, c.text)
                    : (c.surface, c.borderControl, 1.0, c.text);
    return AnimatedContainer(
      duration: MuMotion.durationOf(context, MuMotion.fast),
      curve: MuMotion.enter,
      width: MuSize.controlL,
      height: MuSize.controlXl,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: MuRadius.smAll,
        border: Border.all(color: border, width: width),
      ),
      child: digit != null
          ? Text(digit!, style: MuType.numL.copyWith(color: text))
          : caretFilled
              ? FadeTransition(
                  opacity: caret,
                  child: Container(width: _caretWidth, height: _caretHeight, color: c.focus),
                )
              : null,
    );
  }
}
