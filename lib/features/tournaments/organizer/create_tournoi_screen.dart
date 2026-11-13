import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/pro_wizard_scaffold.dart';
import '../controllers/tournoi_providers.dart';
import '../../organizer_onboarding/data/organizer_draft.dart';
import '../data/tournoi_repository.dart';

/// ORG-05 → ORG-09 · Créer un tournoi: infos, format, terrains et dates, frais et prix, aperçu,
/// then « Publier le tournoi ». One screen, the step in its state; the draft stays in memory.
class CreateTournoiScreen extends ConsumerStatefulWidget {
  const CreateTournoiScreen({super.key, this.depuis});

  /// ORG-02 « Reprendre … »: a past event whose name, sport, size and venue prefill the steps.
  final PastEvent? depuis;

  @override
  ConsumerState<CreateTournoiScreen> createState() => _CreateTournoiScreenState();
}

class _CreateTournoiScreenState extends ConsumerState<CreateTournoiScreen> {
  int _step = 0;
  bool _busy = false;

  // ORG-05 Infos
  final _nom = TextEditingController();
  final _presentation = TextEditingController();
  MuSport _sport = MuSport.padel;
  RangeValues _niveau = const RangeValues(3, 4.5);
  String? _nomError;

  // ORG-06 Format
  TournoiType _type = TournoiType.tournoi;
  TournoiFormat _format = TournoiFormat.poulesElimination;
  int _equipes = 8;

  // ORG-07 Terrains et dates
  final _club = TextEditingController();
  final _adresse = TextEditingController();
  DateTime? _debut;
  DateTime? _fin;
  String? _clubError;
  String? _datesError;

  // ORG-08 Frais et prix
  final _frais = TextEditingController(text: '100');
  final _vainqueurs = TextEditingController();
  final _finalistes = TextEditingController();
  final _troisieme = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.depuis;
    if (e == null) return;
    _nom.text = e.name;
    _club.text = e.venue;
    if (const [MuSport.football, MuSport.padel, MuSport.basketball].contains(e.sport)) _sport = e.sport;
    final teams = e.teams;
    if (teams != null) {
      _equipes = const [4, 8, 16, 32].firstWhere((n) => n >= teams, orElse: () => 32);
    }
  }

  @override
  void dispose() {
    for (final c in [_nom, _presentation, _club, _adresse, _frais, _vainqueurs, _finalistes, _troisieme]) {
      c.dispose();
    }
    super.dispose();
  }

  static int _amount(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;
  int get _dotation => _amount(_vainqueurs) + _amount(_finalistes) + _amount(_troisieme);

  /// Players per team: 2 at padel, 5 at five-a-side, 3 at 3x3 basketball.
  int get _joueurs => _type == TournoiType.evenement ? 1 : switch (_sport) {
        MuSport.padel => 2,
        MuSport.basketball => 3,
        _ => 5,
      };

  /// Groups of 4 when there are enough teams.
  int get _poules => _format == TournoiFormat.elimination ? 1 : (_equipes ~/ 4).clamp(1, 8);

  List<MuWizardStep> get _steps => [
        MuWizardStep(l10n.trnStepInfos),
        MuWizardStep(l10n.trnStepFormat),
        MuWizardStep(l10n.trnStepTerrains),
        MuWizardStep(l10n.trnStepFrais),
        MuWizardStep(l10n.trnStepApercu),
      ];

  bool _validate() {
    setState(() {
      _nomError = null;
      _clubError = null;
      _datesError = null;
    });
    switch (_step) {
      case 0:
        if (_nom.text.trim().length < 3) {
          setState(() => _nomError = l10n.trnNomTropCourt);
          return false;
        }
      case 2:
        if (_club.text.trim().isEmpty) {
          setState(() => _clubError = l10n.trnClubRequis);
          return false;
        }
        if (_debut == null || _fin == null) {
          setState(() => _datesError = l10n.trnDatesRequises);
          return false;
        }
    }
    return true;
  }

  TournoiDraft get _draft => TournoiDraft(
        nom: _nom.text.trim(),
        sport: _sport,
        debut: _debut ?? DateTime.now(),
        fin: _fin ?? _debut ?? DateTime.now(),
        etablissement: _club.text.trim(),
        lieu: _adresse.text.trim().isEmpty ? _club.text.trim() : _adresse.text.trim(),
        fraisEquipe: _amount(_frais),
        equipesMax: _equipes,
        dotation: _dotation == 0 ? null : _dotation,
        niveauMin: _niveau.start,
        niveauMax: _niveau.end,
        format: _format,
        nbPoules: _poules,
        qualifiesParPoule: 2,
        joueursParEquipe: _joueurs,
        description: _presentation.text.trim().isEmpty ? null : _presentation.text.trim(),
        type: _type,
      );

  Future<void> _continue() async {
    if (!_validate()) return;
    if (_step < 4) {
      setState(() => _step++);
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await ref.read(tournoiRepositoryProvider).create(_draft);
      ref.invalidate(mesTournoisProvider);
      if (!mounted) return;
      MuToast.show(context, tone: MuToastTone.success, title: l10n.trnPublie, description: _draft.nom);
      context.go(Routes.organizerTournoi(id));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _debut == null ? null : DateTimeRange(start: _debut!, end: _fin ?? _debut!),
      locale: const Locale('fr'),
    );
    if (range == null) return;
    setState(() {
      _debut = DateTime(range.start.year, range.start.month, range.start.day, 9);
      _fin = DateTime(range.end.year, range.end.month, range.end.day, 19);
      _datesError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      (l10n.trnInfosTitre, l10n.trnInfosLead),
      (l10n.trnFormatTitre, l10n.trnFormatLead),
      (l10n.trnTerrainsTitre, l10n.trnTerrainsLead),
      (l10n.trnFraisTitre, l10n.trnFraisLead),
      (l10n.trnApercuTitre, l10n.trnApercuLead),
    ];
    return ProWizardScaffold(
      space: ProSpace.organizer,
      flowTitle: l10n.creerUnTournoi,
      flowMeta: l10n.trnEtapes,
      steps: _steps,
      current: _step,
      onStepTap: (i) {
        if (i < _step) setState(() => _step = i);
      },
      title: titles[_step].$1,
      lead: titles[_step].$2,
      body: switch (_step) {
        0 => _infos(),
        1 => _formatStep(),
        2 => _terrains(),
        3 => _fraisStep(),
        _ => _apercu(),
      },
      onBack: () => _step == 0 ? context.go(Routes.organizerTournois) : setState(() => _step--),
      onSaveAndQuit: () => context.go(Routes.organizerTournois),
      onContinue: _busy ? null : _continue,
      continueLoading: _busy,
      continueLabel: switch (_step) {
        3 => l10n.trnVoirApercu,
        4 => l10n.trnPublier,
        _ => l10n.continuer,
      },
    );
  }

  static const _gap = SizedBox(height: MuSpace.s6);

  Widget _infos() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MuTextField(
            label: l10n.trnNomDuTournoi,
            controller: _nom,
            helper: l10n.trnNomHelper,
            error: _nomError,
            inputFormatters: [LengthLimitingTextInputFormatter(40)],
          ),
          _gap,
          MuChoiceGroup(
            label: l10n.sport,
            layout: MuChoiceLayout.tile,
            columns: 3,
            children: [
              for (final s in const [MuSport.football, MuSport.padel, MuSport.basketball])
                MuChoiceCard(
                  title: s.label,
                  leading: MuSportTile(s, size: MuMediaTileSize.tile),
                  layout: MuChoiceLayout.tile,
                  selected: _sport == s,
                  onTap: () => setState(() => _sport = s),
                ),
            ],
          ),
          _gap,
          MuRangeSlider(
            label: l10n.trnNiveauMoyen,
            values: _niveau,
            min: 1,
            max: 7,
            step: 0.5,
            format: formatLevel,
            onChanged: (v) => setState(() => _niveau = v),
          ),
          _gap,
          MuTextField(
            label: l10n.trnPresentation,
            controller: _presentation,
            optional: true,
            maxLines: 4,
            inputFormatters: [LengthLimitingTextInputFormatter(500)],
          ),
        ],
      );

  Widget _formatStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MuChoiceGroup(
            label: l10n.trnType,
            children: [
              MuChoiceCard(
                title: l10n.trnTypeTournoi,
                description: l10n.trnTypeTournoiDescription,
                leading: Icon(PhosphorIcons.trophy()),
                selected: _type == TournoiType.tournoi,
                onTap: () => setState(() {
                  _type = TournoiType.tournoi;
                  if (_equipes > 32) _equipes = 32;
                }),
              ),
              MuChoiceCard(
                title: l10n.trnTypeEvenement,
                description: l10n.trnTypeEvenementDescription,
                leading: Icon(PhosphorIcons.confetti()),
                selected: _type == TournoiType.evenement,
                onTap: () => setState(() {
                  _type = TournoiType.evenement;
                  if (_equipes < 8) _equipes = 16;
                }),
              ),
            ],
          ),
          _gap,
          if (_type == TournoiType.tournoi) ...[
          MuChoiceGroup(
            label: l10n.trnFormat,
            children: [
              MuChoiceCard(
                title: l10n.trnPoulesPhaseFinale,
                description: l10n.trnPoulesDescription,
                leading: Icon(PhosphorIcons.squaresFour()),
                selected: _format == TournoiFormat.poulesElimination,
                onTap: () => setState(() => _format = TournoiFormat.poulesElimination),
              ),
              MuChoiceCard(
                title: l10n.trnEliminationDirecte,
                description: l10n.trnEliminationDescription,
                leading: Icon(PhosphorIcons.listNumbers()),
                selected: _format == TournoiFormat.elimination,
                onTap: () => setState(() => _format = TournoiFormat.elimination),
              ),
            ],
          ),
          _gap,
          ],
          Text(_type == TournoiType.evenement ? l10n.trnNombrePlaces : l10n.trnNombreEquipes,
              style: MuType.label.copyWith(color: context.mu.text)),
          const SizedBox(height: MuSpace.s2),
          MuSegmentedControl<int>(
            semanticLabel: l10n.trnNombreEquipes,
            expand: true,
            value: _equipes,
            onChanged: (v) => setState(() => _equipes = v),
            segments: [
              for (final n in _type == TournoiType.evenement ? const [8, 16, 32, 64] : const [4, 8, 16, 32])
                MuSegment(value: n, label: '$n'),
            ],
          ),
          const SizedBox(height: MuSpace.s2),
          Text(
            _type == TournoiType.evenement
                ? l10n.trnEvenementResume(_equipes)
                : (_format == TournoiFormat.elimination
                    ? l10n.trnEliminationResume(_equipes)
                    : l10n.trnPoulesResume(_poules)),
            style: MuType.caption.copyWith(color: context.mu.textSecondary),
          ),
          if (_type == TournoiType.tournoi) ...[
            _gap,
            Text(
              l10n.trnJoueursParEquipe(_joueurs),
              style: MuType.body.copyWith(color: context.mu.textSecondary),
            ),
          ],
        ],
      );

  Widget _terrains() {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuTextField(label: l10n.trnClub, controller: _club, error: _clubError),
        _gap,
        MuTextField(label: l10n.trnAdresse, controller: _adresse, optional: true),
        _gap,
        Text(l10n.trnDates, style: MuType.label.copyWith(color: c.text)),
        const SizedBox(height: MuSpace.s2),
        MuButton.secondary(
          label: _debut == null ? l10n.trnChoisirDates : formatDateRange(_debut!, _fin ?? _debut!),
          leading: PhosphorIcons.calendarBlank(),
          size: MuButtonSize.l,
          fullWidth: true,
          onPressed: _pickDates,
        ),
        if (_datesError != null) ...[
          const SizedBox(height: MuSpace.s2),
          Text(_datesError!, style: MuType.caption.copyWith(color: c.errorText)),
        ],
        const SizedBox(height: MuSpace.s3),
        Text(l10n.trnTerrainsPlanningNote, style: MuType.caption.copyWith(color: c.textSecondary)),
      ],
    );
  }

  Widget _fraisStep() {
    final c = context.mu;
    final frais = _amount(_frais);
    final recettes = frais * _equipes;
    Widget prize(String label, TextEditingController ctl) => Padding(
          padding: const EdgeInsetsDirectional.only(bottom: MuSpace.s3),
          child: MuTextField(
            label: label,
            controller: ctl,
            optional: true,
            suffixText: dtUnit,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuTextField(
          label: l10n.trnFraisParEquipe,
          controller: _frais,
          suffixText: dtUnit,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          helper: l10n.trnFraisHelper(formatDT(_joueurs == 0 ? 0 : frais / _joueurs)),
          onChanged: (_) => setState(() {}),
        ),
        _gap,
        Text(l10n.trnDotation, style: MuType.h3.copyWith(color: c.text)),
        const SizedBox(height: MuSpace.s3),
        prize(l10n.trnVainqueurs, _vainqueurs),
        prize(l10n.trnFinalistes, _finalistes),
        prize(l10n.trnTroisieme, _troisieme),
        const SizedBox(height: MuSpace.s3),
        Container(
          padding: const EdgeInsetsDirectional.all(MuSpace.s4),
          decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(MuRadius.md)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.trnSiToutesInscrites(_equipes), style: MuType.label.copyWith(color: c.text)),
              const SizedBox(height: MuSpace.s3),
              _line(l10n.trnInscriptions, formatDT(recettes)),
              _line(l10n.trnDotation, '−${formatDT(_dotation)}'),
              const Divider(),
              _line(l10n.trnResteImpourToi, formatDT(recettes - _dotation), strong: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _line(String label, String value, {bool strong = false}) {
    final c = context.mu;
    final style = (strong ? MuType.label : MuType.body).copyWith(color: c.text);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: MuSpace.s1),
      child: Row(children: [Expanded(child: Text(label, style: style)), Text(value, style: style)]),
    );
  }

  Widget _apercu() {
    final c = context.mu;
    final d = _draft;
    Widget recap(int step, String title, String text) => MuSettingsRow(
          title: title,
          description: text,
          chevron: false,
          trailing: MuButton.link(label: l10n.modifier, onPressed: () => setState(() => _step = step)),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.trnApercuJoueur, style: MuType.overline.copyWith(color: c.textSecondary)),
        const SizedBox(height: MuSpace.s3),
        MuTournamentCard(
          tournament: MuTournament(
            sport: d.sport,
            name: d.nom,
            start: d.debut,
            end: d.fin,
            venue: d.etablissement,
            place: d.lieu,
            feePerTeam: d.fraisEquipe,
            teamsTotal: d.equipesMax,
            teamsRegistered: 0,
            prize: d.dotation,
            levelMin: d.niveauMin,
            levelMax: d.niveauMax,
          ),
        ),
        _gap,
        Text(l10n.trnRecapitulatif, style: MuType.overline.copyWith(color: c.textSecondary)),
        const SizedBox(height: MuSpace.s3),
        MuSettingsGroup(
          children: [
            recap(0, l10n.trnStepInfos,
                l10n.trnRecapInfos(d.sport.label, formatLevel(d.niveauMin ?? 1), formatLevel(d.niveauMax ?? 7))),
            recap(
              1,
              l10n.trnStepFormat,
              d.evenement
                  ? l10n.trnEvenementResume(d.equipesMax)
                  : (d.format == TournoiFormat.elimination
                      ? l10n.trnEliminationResume(d.equipesMax)
                      : l10n.trnPoulesResume(d.nbPoules)),
            ),
            recap(2, l10n.trnStepTerrains, '${d.etablissement} · ${formatDateRange(d.debut, d.fin)}'),
            recap(3, l10n.trnStepFrais,
                l10n.trnRecapFrais(formatDT(d.fraisEquipe), formatDT(d.dotation ?? 0))),
          ],
        ),
        const SizedBox(height: MuSpace.s4),
        Text(l10n.trnApercuNote, style: MuType.caption.copyWith(color: c.textSecondary)),
      ],
    );
  }
}
