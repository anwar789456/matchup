import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../ui/ui.dart';
import '../../auth/widgets/auth_messages.dart';
import '../../common/widgets/pro_wizard_scaffold.dart';
import '../controllers/owner_controller.dart';
import '../data/owner_repository.dart';
import '../widgets/owner_wizard.dart';

/// OWN-01 — the company: venue name, legal name, tax id and legal form, then the venue's phone
/// and business email.
class CompanyScreen extends ConsumerStatefulWidget {
  const CompanyScreen({super.key});

  @override
  ConsumerState<CompanyScreen> createState() => _CompanyScreenState();
}

/// « 1234567/A/M/000 »: 7 digits, the key letter, the VAT code and the category, then the
/// 3-digit establishment number; slashes optional.
final _taxId = RegExp(
  r'^\d{7}\s*/?\s*[A-Z]\s*/?\s*[A-Z]\s*/?\s*[A-Z]?\s*/?\s*\d{3}$',
  caseSensitive: false,
);

class _CompanyScreenState extends ConsumerState<CompanyScreen> {
  late final _d = ref.read(ownerProvider).requireValue;
  late final _venue = TextEditingController(text: _d.venueName);
  late final _legal = TextEditingController(text: _d.legalName);
  late final _tax = TextEditingController(text: _d.taxId);
  late final _phone = TextEditingController(text: groupPhoneDigits(_d.phone));
  late final _email = TextEditingController(text: _d.email);
  late String _form = _d.legalForm;

  String? _venueError;
  String? _legalError;
  String? _taxError;
  String? _phoneError;
  String? _emailError;

  @override
  void dispose() {
    for (final c in [_venue, _legal, _tax, _phone, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  OwnerController get _owner => ref.read(ownerProvider.notifier);

  bool _validate() {
    setState(() {
      _venueError = _venue.text.trim().isEmpty ? 'Indique le nom du terrain.' : null;
      _legalError = _legal.text.trim().isEmpty ? 'Indique la raison sociale.' : null;
      final tax = _tax.text.trim();
      _taxError = tax.isEmpty
          ? 'Indique ton matricule fiscal.'
          : (_taxId.hasMatch(tax) ? null : 'Le matricule fiscal ressemble à 1234567/A/M/000.');
      _phoneError = MuPhoneFormatter.digitsOf(_phone.text).length == 8
          ? null
          : 'Le numéro doit contenir 8 chiffres.';
      _emailError = AuthMessages.validateEmail(_email.text);
    });
    return [_venueError, _legalError, _taxError, _phoneError, _emailError].every((e) => e == null);
  }

  @override
  Widget build(BuildContext context) {
    return OwnerWizard(
      step: 0,
      title: 'Parle-nous de ton entreprise',
      lead: 'Les joueurs ne verront que le nom du terrain et son téléphone.',
      validate: _validate,
      body: ProFormCard(
        children: [
          ProFormSection(
            title: 'Ton établissement',
            description: 'Ces infos figurent sur tes factures. Tu pourras les modifier plus tard.',
            children: [
              ProFieldGrid(
                children: [
                  MuTextField(
                    label: 'Nom du terrain',
                    controller: _venue,
                    size: MuFieldSize.m,
                    helper: 'Le nom que les joueurs verront sur MatchUp.',
                    error: _venueError,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (v) {
                      if (_venueError != null) setState(() => _venueError = null);
                      _owner.edit((d) => d.copyWith(venueName: v));
                    },
                  ),
                  MuTextField(
                    label: 'Raison sociale',
                    controller: _legal,
                    size: MuFieldSize.m,
                    helper: 'Comme sur ton registre de commerce.',
                    error: _legalError,
                    onChanged: (v) {
                      if (_legalError != null) setState(() => _legalError = null);
                      _owner.edit((d) => d.copyWith(legalName: v));
                    },
                  ),
                  MuTextField(
                    label: 'Matricule fiscal',
                    controller: _tax,
                    size: MuFieldSize.m,
                    placeholder: '1234567/A/M/000',
                    helper: 'Il figure sur ta carte d’identification fiscale.',
                    error: _taxError,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    onChanged: (v) {
                      if (_taxError != null) setState(() => _taxError = null);
                      _owner.edit((d) => d.copyWith(taxId: v.trim()));
                    },
                  ),
                  MuSelect<String>(
                    label: 'Forme juridique',
                    size: MuFieldSize.m,
                    value: _form,
                    options: [
                      for (final (id, label) in OwnerCatalog.legalForms)
                        MuSelectOption(value: id, label: label),
                    ],
                    onChanged: (v) {
                      setState(() => _form = v);
                      _owner.edit((d) => d.copyWith(legalForm: v));
                    },
                  ),
                ],
              ),
            ],
          ),
          ProFormSection(
            title: 'Contact',
            description: 'Responsable du compte : ${_d.manager}',
            children: [
              ProFieldGrid(
                children: [
                  MuPhoneField(
                    label: 'Téléphone du terrain',
                    controller: _phone,
                    size: MuFieldSize.m,
                    helper: 'Les joueurs t’appellent à ce numéro le jour du match.',
                    error: _phoneError,
                    onChanged: (digits) {
                      if (_phoneError != null) setState(() => _phoneError = null);
                      _owner.edit((d) => d.copyWith(phone: digits));
                    },
                  ),
                  MuTextField(
                    label: 'Email pro',
                    controller: _email,
                    size: MuFieldSize.m,
                    leadingIcon: PhosphorIcons.envelopeSimple(),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    helper: 'Pour les réservations, les versements et les factures.',
                    error: _emailError,
                    onChanged: (v) {
                      if (_emailError != null) setState(() => _emailError = null);
                      _owner.edit((d) => d.copyWith(email: v.trim()));
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
