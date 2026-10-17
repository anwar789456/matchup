import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/auth_providers.dart';
import '../widgets/auth_widgets.dart';
import '../../../l10n/l10n.dart';

/// AUTH-02 · Téléphone: add a +216 number to receive the SMS code.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  late final TextEditingController _phone = TextEditingController(
    text: groupPhoneDigits(ref.read(authFlowProvider).phoneDigits ?? ''),
  );
  String _digits = '';
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _digits = MuPhoneFormatter.digitsOf(_phone.text);
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_digits.length != MuPhoneFormatter.maxDigits) {
      setState(() => _error = l10n.leNumeroDoitContenirChiffres);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).sendPhoneCode(_digits);
      ref.read(authFlowProvider.notifier).setPhone(_digits);
      if (mounted) context.push(Routes.smsCode);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final strong = MuType.label.copyWith(color: c.text);
    return FlowScaffold(
      onBack: () => goBack(context, Routes.signup),
      body: [
        FlowTitle(
          l10n.ajouteTonNumero,
          lead: l10n.pourConfirmerLesPartiesEt,
        ),
        MuPhoneField(
          controller: _phone,
          helper: l10n.onTEnvoieUnCode,
          error: _error,
          onChanged: (d) => setState(() {
            _digits = d;
            _error = null;
          }),
          onSubmitted: (_) => _submit(),
        ),
        Container(
          padding: const EdgeInsets.all(MuSpace.s4),
          decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
          child: Column(
            children: [
              IconLine(
                icon: PhosphorIcons.calendarCheck(),
                text: TextSpan(children: [
                  TextSpan(text: l10n.desPartiesConfirmees, style: strong),
                  TextSpan(text: l10n.unNumeroVerifieParJoueur),
                ]),
              ),
              const SizedBox(height: MuSpace.s4),
              IconLine(
                icon: PhosphorIcons.shieldCheck(),
                text: TextSpan(children: [
                  TextSpan(text: l10n.desPaiementsProteges, style: strong),
                  TextSpan(text: l10n.onSAssureQueC),
                ]),
              ),
              const SizedBox(height: MuSpace.s4),
              IconLine(
                icon: PhosphorIcons.lockSimple(),
                text: TextSpan(children: [
                  TextSpan(text: l10n.tonNumeroRestePrive, style: strong),
                  TextSpan(text: l10n.seulsLesOrganisateursDeTes),
                ]),
              ),
            ],
          ),
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: l10n.recevoirLeCode,
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
