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
import '../../../l10n/l10n.dart';

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
      _venueError = _venue.text.trim().isEmpty ? l10n.indiqueLeNomDuTerrain : null;
      _legalError = _legal.text.trim().isEmpty ? l10n.indiqueLaRaisonSociale : null;
      final tax = _tax.text.trim();
      _taxError = tax.isEmpty
          ? 'Indique ton matricule fiscal.'
          : (_taxId.hasMatch(tax) ? null : l10n.leMatriculeFiscalRessembleA);
      _phoneError = MuPhoneFormatter.digitsOf(_phone.text).length == 8
          ? null
          : l10n.leNumeroDoitContenirChiffres;
      _emailError = AuthMessages.validateEmail(_email.text);
    });
    return [_venueError, _legalError, _taxError, _phoneError, _emailError].every((e) => e == null);
  }

  @override
  Widget build(BuildContext context) {
    return OwnerWizard(
      step: 0,
      title: l10n.parleNousDeTonEntreprise,
      lead: l10n.lesJoueursNeVerrontQue,
      validate: _validate,
      body: ProFormCard(
        children: [
          ProFormSection(
            title: l10n.tonEtablissement,
            description: l10n.cesInfosFigurentSurTes,
            children: [
              ProFieldGrid(
                children: [
                  MuTextField(
                    label: l10n.nomDuTerrain,
                    controller: _venue,
                    size: MuFieldSize.m,
                    helper: l10n.leNomQueLesJoueurs,
                    error: _venueError,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (v) {
                      if (_venueError != null) setState(() => _venueError = null);
                      _owner.edit((d) => d.copyWith(venueName: v));
                    },
                  ),
                  MuTextField(
                    label: l10n.raisonSociale,
                    controller: _legal,
                    size: MuFieldSize.m,
                    helper: l10n.commeSurTonRegistreDe,
                    error: _legalError,
                    onChanged: (v) {
                      if (_legalError != null) setState(() => _legalError = null);
                      _owner.edit((d) => d.copyWith(legalName: v));
                    },
                  ),
                  MuTextField(
                    label: l10n.matriculeFiscal,
                    controller: _tax,
                    size: MuFieldSize.m,
                    placeholder: '1234567/A/M/000',
                    helper: l10n.ilFigureSurTaCarte,
                    error: _taxError,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    onChanged: (v) {
                      if (_taxError != null) setState(() => _taxError = null);
                      _owner.edit((d) => d.copyWith(taxId: v.trim()));
                    },
                  ),
                  MuSelect<String>(
                    label: l10n.formeJuridique,
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
            title: l10n.contact,
            description: l10n.responsableDuCompte(_d.manager),
            children: [
              ProFieldGrid(
                children: [
                  MuPhoneField(
                    label: l10n.telephoneDuTerrain,
                    controller: _phone,
                    size: MuFieldSize.m,
                    helper: l10n.lesJoueursTAppellentA,
                    error: _phoneError,
                    onChanged: (digits) {
                      if (_phoneError != null) setState(() => _phoneError = null);
                      _owner.edit((d) => d.copyWith(phone: digits));
                    },
                  ),
                  MuTextField(
                    label: l10n.emailPro,
                    controller: _email,
                    size: MuFieldSize.m,
                    leadingIcon: PhosphorIcons.envelopeSimple(),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    helper: l10n.pourLesReservationsLesVersements,
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
