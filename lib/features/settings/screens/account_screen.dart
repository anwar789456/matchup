import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../data/settings_repository.dart';
import '../../../l10n/l10n.dart';

/// SET-02 · Compte: contact (email, phone) and personal information.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  late final AccountSettings _initial = ref.read(accountSettingsProvider);
  late final _email = TextEditingController(text: _initial.email);
  late final _phone = TextEditingController(text: _initial.phone);
  late final _first = TextEditingController(text: _initial.firstName);
  late final _last = TextEditingController(text: _initial.lastName);
  late final _birth = TextEditingController(text: _initial.birthDate);
  late Gender _gender = _initial.gender;

  @override
  void dispose() {
    for (final c in [_email, _phone, _first, _last, _birth]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final contactChanged = _email.text != _initial.email || _phone.text != _initial.phone;
    ref
        .read(accountSettingsProvider.notifier)
        .update(
          (s) => s.copyWith(
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
            birthDate: _birth.text.trim(),
            gender: _gender,
          ),
        );
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: l10n.compteEnregistre,
      description: contactChanged ? l10n.unCodeDeVerificationT : null,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    Widget card(String title, String note, List<Widget> fields) => Container(
      padding: const EdgeInsets.all(MuSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        boxShadow: MuElevation.of(context).level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: MuType.h3.copyWith(color: c.text)),
          ),
          const SizedBox(height: MuSpace.s1),
          Text(note, style: caption),
          for (final f in fields) ...[const SizedBox(height: MuSpace.s5), f],
        ],
      ),
    );
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.compte,
            backLabel: l10n.retourAuxParametres,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                card(
                  l10n.contact,
                  l10n.siTuChangesLUn,
                  [
                    MuTextField(
                      label: l10n.email,
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    MuPhoneField(label: l10n.telephone, controller: _phone),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                card(
                  l10n.infosPersonnelles,
                  l10n.lesAutresJoueursVoientTon2(_first.text, _last.text.isEmpty ? '' : '${_last.text[0]}.'),
                  [
                    MuTextField(
                      label: l10n.prenom,
                      controller: _first,
                      onChanged: (_) => setState(() {}),
                    ),
                    MuTextField(label: l10n.nom, controller: _last, onChanged: (_) => setState(() {})),
                    MuTextField(
                      label: l10n.dateDeNaissance,
                      controller: _birth,
                      placeholder: l10n.jjMmAaaa,
                      helper: l10n.jamaisAfficheeSurTonProfil,
                      keyboardType: TextInputType.datetime,
                    ),
                    MuSelect<Gender>(
                      label: l10n.genre,
                      value: _gender,
                      helper: l10n.sertSeulementATeProposer,
                      options: [
                        MuSelectOption(value: Gender.male, label: l10n.homme),
                        MuSelectOption(value: Gender.female, label: l10n.femme),
                        MuSelectOption(value: Gender.unspecified, label: l10n.jePrefereNePasDire),
                      ],
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          MuButton.primary(
            label: l10n.enregistrer,
            size: MuButtonSize.xl,
            fullWidth: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
