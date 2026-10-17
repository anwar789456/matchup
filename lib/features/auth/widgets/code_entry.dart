import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import 'auth_messages.dart';
import '../../../l10n/l10n.dart';

/// The code step shared by AUTH-03 (SMS) and AUTH-07 (email reset code): title with where the code
/// went, the six boxes, and « Vérifier » in the sticky bar. Verifies on the 6th digit too.
///
/// [verify] throws an auth failure for a wrong code; [onVerified] runs after the success state.
class CodeEntry extends StatefulWidget {
  const CodeEntry({
    super.key,
    required this.lead,
    required this.label,
    required this.helper,
    required this.verify,
    required this.onVerified,
    required this.onResend,
    required this.onBack,
    required this.buttonLabel,
    this.successMessage,
    this.header,
  });

  final InlineSpan lead;
  final String label;
  final String helper;
  final Future<void> Function(String code) verify;
  final VoidCallback onVerified;
  final Future<void> Function() onResend;
  final VoidCallback onBack;
  final String buttonLabel;

  /// Shown in the success state before moving on (« Numéro vérifié. »); null skips it.
  final String? successMessage;
  final Widget? header;

  @override
  State<CodeEntry> createState() => _CodeEntryState();
}

class _CodeEntryState extends State<CodeEntry> {
  // OtpInput.md: the resend link comes back after 45 s.
  static const _resendIn = Duration(seconds: 45);

  final _code = TextEditingController();
  String? _error;
  String? _disabled;
  String? _success;
  bool _verifying = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _code.text;
    if (_verifying || _success != null || _disabled != null) return;
    if (code.length < 6) {
      setState(() => _error = AuthMessages.codeIncomplete);
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await widget.verify(code);
      if (!mounted) return;
      if (widget.successMessage == null) {
        setState(() => _verifying = false);
        widget.onVerified();
        return;
      }
      setState(() {
        _verifying = false;
        _success = widget.successMessage;
      });
      await Future<void>.delayed(MuMotion.success);
      if (mounted) widget.onVerified();
    } catch (e) {
      final message = AuthMessages.codeFailure(e);
      if (message == null) rethrow;
      if (!mounted) return;
      setState(() {
        _verifying = false;
        if (message == AuthMessages.tooManyCodes) {
          _disabled = message;
        } else {
          _error = message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlowScaffold(
      onBack: widget.onBack,
      header: widget.header,
      body: [
        FlowTitle(l10n.entreLeCode, leadSpan: widget.lead),
        MuOtpInput(
          controller: _code,
          label: widget.label,
          helper: widget.helper,
          error: _error,
          success: _success,
          verifying: _verifying,
          disabled: _disabled,
          resendIn: _resendIn,
          autofocus: true,
          onResend: () async {
            await widget.onResend();
            if (!context.mounted) return;
            MuToast.show(context, tone: MuToastTone.success, title: l10n.codeRenvoye);
          },
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onCompleted: (_) => _verify(),
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: widget.buttonLabel,
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: _verifying,
          onPressed: _disabled == null ? _verify : null,
        ),
      ],
    );
  }
}
