import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../auth/widgets/auth_messages.dart';
import '../../coach_onboarding/data/coach_draft.dart' show CoachCatalog;
import '../../common/data/draft_file.dart';
import '../../common/data/pro_providers.dart';
import '../../common/widgets/pro_wizard_scaffold.dart';
import '../controllers/organizer_controller.dart';
import '../data/organizer_draft.dart';

/// ORG-01 — the organisation: logo, name, contact, and up to three past events (optional).
class OrganisationScreen extends ConsumerStatefulWidget {
  const OrganisationScreen({super.key});

  @override
  ConsumerState<OrganisationScreen> createState() => _OrganisationScreenState();
}

class _OrganisationScreenState extends ConsumerState<OrganisationScreen> {
  static const _steps = ['Organisation', 'Premier tournoi'];

  late final _d = ref.read(organizerProvider).requireValue;
  late final _name = TextEditingController(text: _d.name);
  late final _email = TextEditingController(text: _d.email);
  late final _phone = TextEditingController(text: groupPhoneDigits(_d.phone));

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  bool _busy = false;

  /// The event open for editing (new or existing) and its working copy.
  PastEvent? _editing;
  bool _isNew = false;
  final _eventName = TextEditingController();
  final _eventDate = TextEditingController();
  final _eventTeams = TextEditingController();
  final _eventVenue = TextEditingController();
  String? _eventError;

  OrganizerController get _org => ref.read(organizerProvider.notifier);

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _eventName, _eventDate, _eventTeams, _eventVenue]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picked = await ref.read(fileSourceProvider).pickOne(const ['png', 'svg']);
    if (picked == null || !mounted) return;
    if (picked.sizeBytes > _maxLogo) {
      MuToast.show(context,
          tone: MuToastTone.error,
          title: '${picked.name} pèse ${formatFileSize(picked.sizeBytes)} (max 5 Mo).');
      return;
    }
    final id = 'logo-${DateTime.now().microsecondsSinceEpoch}';
    await ref.read(uploadServiceProvider).upload(picked.name, picked.sizeBytes).drain<void>();
    if (picked.bytes != null && !picked.name.toLowerCase().endsWith('.svg')) {
      ref.read(uploadedBytesProvider)[id] = picked.bytes!;
    }
    await _org.edit((d) =>
        d.copyWith(logo: DraftFile(id: id, name: picked.name, sizeBytes: picked.sizeBytes)));
  }

  // ORG-01: PNG or SVG · 5 Mo max.
  static const _maxLogo = 5 * 1000 * 1000;

  void _openEvent(PastEvent e, {bool isNew = false}) {
    if (_editing != null && !_saveEvent()) return;
    setState(() {
      _editing = e;
      _isNew = isNew;
      _eventError = null;
      _eventName.text = e.name;
      _eventDate.text = e.date;
      _eventTeams.text = e.teams?.toString() ?? '';
      _eventVenue.text = e.venue;
    });
  }

  bool _saveEvent() {
    final e = _editing;
    if (e == null) return true;
    final name = _eventName.text.trim();
    if (name.isEmpty) {
      setState(() => _eventError = 'Donne un nom à l’événement.');
      return false;
    }
    final saved = PastEvent(
      id: e.id,
      name: name,
      sport: e.sport,
      date: _eventDate.text.trim(),
      teams: int.tryParse(_eventTeams.text),
      venue: _eventVenue.text.trim(),
    );
    _org.edit((d) => d.copyWith(events: [
          for (final x in d.events) x.id == saved.id ? saved : x,
          if (!d.events.any((x) => x.id == saved.id)) saved,
        ]));
    setState(() {
      _editing = null;
      _isNew = false;
    });
    return true;
  }

  void _removeEvent(PastEvent e) {
    final index = ref.read(organizerProvider).requireValue.events.indexOf(e);
    _org.edit((d) => d.copyWith(events: d.events.where((x) => x.id != e.id).toList()));
    MuToast.show(
      context,
      title: '${e.name} retiré',
      action: MuAction('Annuler', () {
        _org.edit((d) {
          final events = [...d.events]..insert(index.clamp(0, d.events.length), e);
          return d.copyWith(events: events);
        });
      }),
    );
  }

  bool _validate() {
    setState(() {
      _nameError = _name.text.trim().isEmpty ? 'Indique le nom de ton organisation.' : null;
      _emailError = AuthMessages.validateEmail(_email.text);
      _phoneError = MuPhoneFormatter.digitsOf(_phone.text).length == 8
          ? null
          : 'Le numéro doit contenir 8 chiffres.';
    });
    return _saveEvent() && _nameError == null && _emailError == null && _phoneError == null;
  }

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      if (!_validate()) return;
      await _org.complete(0);
      if (mounted) context.go(Routes.organizerDashboard);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final d = ref.watch(organizerProvider).requireValue;
    final logo = d.logo == null ? null : ref.read(uploadedBytesProvider)[d.logo!.id];
    final events = [
      ...d.events,
      if (_isNew && _editing != null) _editing!,
    ];

    return ProWizardScaffold(
      space: ProSpace.organizer,
      railTitle: 'Organise tes tournois',
      railMeta: '${_steps.length} étapes · environ 3 min',
      steps: [for (final s in _steps) MuWizardStep(s)],
      current: 0,
      title: 'Présente ton organisation',
      lead: 'Les équipes voient ces infos sur chaque tournoi que tu publies.',
      onBack: () => context.go(Routes.roles),
      onSaveAndQuit: () => context.go(Routes.organizerDashboard),
      onContinue: _busy ? null : _continue,
      continueLoading: _busy,
      savedAt: d.savedAt,
      body: ProFormCard(
        children: [
          ProFormSection(
            title: 'Ton organisation',
            children: [
              ProFieldGrid(children: [
                MuFileUpload.avatar(
                  label: 'Logo',
                  name: d.name,
                  helper: 'PNG ou SVG · 5 Mo max',
                  image: logo == null ? null : MemoryImage(logo),
                  onAdd: _pickLogo,
                  onRemove: (_) => _org.edit((d) => d.copyWith(clearLogo: true)),
                ),
                MuTextField(
                  label: 'Nom de l’organisation',
                  controller: _name,
                  size: MuFieldSize.m,
                  helper: 'Affiché sur tes tournois et tes annonces.',
                  error: _nameError,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (v) {
                    if (_nameError != null) setState(() => _nameError = null);
                    _org.edit((d) => d.copyWith(name: v));
                  },
                ),
                MuTextField(
                  label: 'Email de contact',
                  controller: _email,
                  size: MuFieldSize.m,
                  leadingIcon: PhosphorIcons.envelopeSimple(),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  error: _emailError,
                  onChanged: (v) {
                    if (_emailError != null) setState(() => _emailError = null);
                    _org.edit((d) => d.copyWith(email: v.trim()));
                  },
                ),
                MuPhoneField(
                  label: 'Téléphone',
                  controller: _phone,
                  size: MuFieldSize.m,
                  helper: 'Pour les questions des équipes le jour du tournoi.',
                  error: _phoneError,
                  onChanged: (digits) {
                    if (_phoneError != null) setState(() => _phoneError = null);
                    _org.edit((d) => d.copyWith(phone: digits));
                  },
                ),
              ]),
            ],
          ),
          ProFormSection(
            title: 'Événements passés',
            optionalNote: '(facultatif)',
            description: 'Jusqu’à 3 : les équipes s’inscrivent plus volontiers chez un '
                'organisateur qui a de l’expérience.',
            trailing: MuButton.tertiary(
              label: 'Passer',
              trailing: PhosphorIcons.arrowRight(),
              onPressed: () async {
                await _org.complete(0);
                if (context.mounted) context.go(Routes.organizerDashboard);
              },
            ),
            children: [
              for (final e in events)
                if (e.id == _editing?.id) _editor(c) else _EventRow(
                  event: e,
                  onEdit: () => _openEvent(e),
                  onRemove: () => _removeEvent(e),
                ),
              Row(
                children: [
                  if (events.length < maxPastEvents)
                    MuButton.secondary(
                      label: 'Ajouter un événement',
                      leading: PhosphorIcons.plus(),
                      onPressed: () => _openEvent(
                        PastEvent(id: 'e${DateTime.now().microsecondsSinceEpoch}', name: ''),
                        isNew: true,
                      ),
                    ),
                  const Spacer(),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: '${d.events.length}/$maxPastEvents',
                        style: MuType.numXs.copyWith(color: c.textSecondary),
                      ),
                      const TextSpan(text: ' événements'),
                    ]),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editor(MuColors c) {
    final e = _editing!;
    return Container(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, MuSpace.s5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: c.primary, width: _EventRow.editEdge),
        boxShadow: MuElevation.of(context).level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_isNew ? 'Nouvel événement' : 'Modification en cours',
                    style: MuType.labelL.copyWith(color: c.text)),
              ),
              MuButton.tertiary(
                label: 'Annuler',
                onPressed: () => setState(() {
                  _editing = null;
                  _isNew = false;
                }),
              ),
              const SizedBox(width: MuSpace.s2),
              MuButton.secondary(
                label: 'Enregistrer',
                leading: PhosphorIcons.check(),
                onPressed: _saveEvent,
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          ProFieldGrid(children: [
            MuTextField(
              label: 'Nom de l’événement',
              controller: _eventName,
              size: MuFieldSize.m,
              error: _eventError,
              autofocus: _isNew,
              onChanged: (_) => setState(() => _eventError = null),
            ),
            MuSelect<MuSport>(
              label: 'Sport',
              size: MuFieldSize.m,
              value: e.sport,
              options: [
                for (final (sport, label) in CoachCatalog.sports)
                  MuSelectOption(
                    value: sport,
                    label: label,
                    icon: MuSportIcon(sport, size: MuSize.iconS, color: sport.text(c)),
                  ),
              ],
              onChanged: (v) => setState(() => _editing = e.copyWith(sport: v)),
            ),
            MuTextField(
              label: 'Date',
              controller: _eventDate,
              size: MuFieldSize.m,
              placeholder: 'mars 2026',
            ),
            MuTextField(
              label: 'Équipes',
              controller: _eventTeams,
              size: MuFieldSize.m,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
            ),
          ]),
          const SizedBox(height: MuSpace.s5),
          MuTextField(label: 'Lieu', controller: _eventVenue, size: MuFieldSize.m),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.onEdit, required this.onRemove});

  final PastEvent event;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  // ORG-01 source: 48 sport tile; the open row has a 2 px primary edge; 2 px between the lines.
  static const double _tile = 48;
  static const double editEdge = 2;
  static const double _lineGap = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: const EdgeInsets.all(MuSpace.s3),
      decoration: BoxDecoration(
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: _tile,
            height: _tile,
            decoration: BoxDecoration(color: event.sport.soft(c), borderRadius: MuRadius.smAll),
            child: Center(
              child: MuSportIcon(event.sport, size: MuSize.iconM, color: event.sport.text(c)),
            ),
          ),
          const SizedBox(width: MuSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.name, style: MuType.labelL.copyWith(color: c.text)),
                if (event.summary.isNotEmpty) ...[
                  const SizedBox(height: _lineGap),
                  Text(event.summary, style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ],
            ),
          ),
          MuIconButton(
            icon: PhosphorIcons.pencilSimple(),
            label: 'Modifier ${event.name}',
            onPressed: onEdit,
          ),
          MuIconButton(
            icon: PhosphorIcons.trash(),
            label: 'Retirer ${event.name}',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
