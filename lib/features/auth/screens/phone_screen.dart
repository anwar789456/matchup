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
      setState(() => _error = 'Le numéro doit contenir 8 chiffres.');
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
        const FlowTitle(
          'Ajoute ton numéro',
          lead: 'Pour confirmer les parties et sécuriser les paiements.',
        ),
        MuPhoneField(
          controller: _phone,
          helper: 'On t’envoie un code à 6 chiffres par SMS.',
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
                  TextSpan(text: 'Des parties confirmées.', style: strong),
                  const TextSpan(text: ' Un numéro vérifié par joueur, c’est moins d’absents le jour J.'),
                ]),
              ),
              const SizedBox(height: MuSpace.s4),
              IconLine(
                icon: PhosphorIcons.shieldCheck(),
                text: TextSpan(children: [
                  TextSpan(text: 'Des paiements protégés.', style: strong),
                  const TextSpan(text: ' On s’assure que c’est bien toi avant de débiter ta part.'),
                ]),
              ),
              const SizedBox(height: MuSpace.s4),
              IconLine(
                icon: PhosphorIcons.lockSimple(),
                text: TextSpan(children: [
                  TextSpan(text: 'Ton numéro reste privé.', style: strong),
                  const TextSpan(text: ' Seuls les organisateurs de tes parties le voient.'),
                ]),
              ),
            ],
          ),
        ),
      ],
      bottomBar: [
        MuButton.primary(
          label: 'Recevoir le code',
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
