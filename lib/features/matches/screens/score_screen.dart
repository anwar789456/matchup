import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/matches_providers.dart';
import '../data/bookings_repository.dart';
import '../../../l10n/l10n.dart';

/// MAT-09 · Score du match: the padel scoreboard, the sets with steppers, « Ajouter un 3e set »,
/// then « Enregistrer le score ».
class ScoreScreen extends ConsumerStatefulWidget {
  const ScoreScreen({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends ConsumerState<ScoreScreen> {
  List<(int, int)>? _sets;
  bool _saving = false;

  // A padel set goes to 7 at most; three sets at most.
  static const int _maxGames = 7;
  static const int _maxSets = 3;

  PastMatch? _match(List<PastMatch> all) => all.where((m) => m.id == widget.matchId).firstOrNull;

  Future<void> _save(PastMatch m) async {
    setState(() => _saving = true);
    await ref.read(matchesActionsProvider).submitScore(m.id, _sets!);
    if (!mounted) return;
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: l10n.scoreEnregistre,
      description: l10n.ontHPourLeConfirmer(_opponents(m)),
    );
    _back();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.matches);
    }
  }

  String _opponents(PastMatch m) {
    final names = [
      for (final mate in m.mates)
        if (!mate.partner) mate.person.name.split(' ').first,
    ];
    return names.length >= 2 ? '${names.first} et ${names.last}' : names.join();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final past = ref.watch(pastMatchesProvider);
    final m = past.value == null ? null : _match(past.value!);
    if (m == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(
          child: past.isLoading
              ? MuSpinner(semanticLabel: l10n.chargement)
              : MuEmptyState(
                  title: l10n.matchIntrouvable,
                  actions: [MuButton.primary(label: l10n.retour, onPressed: _back)],
                ),
        ),
      );
    }
    _sets ??= [
      ...(m.sets ?? const [(0, 0), (0, 0)]),
    ];
    final sets = _sets!;
    final home = m.match.teams[0];
    final away = m.match.teams[1];
    final homeNames = home.name.split(' / ');
    final awayNames = away.name.split(' / ');
    final homeShort = home.short;
    final awayShort = away.short;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(MuSpace.s2, MuSpace.s2, MuSpace.s3, 0),
              child: Row(
                children: [
                  MuIconButton(
                    icon: PhosphorIcons.arrowLeft(),
                    label: l10n.retour,
                    size: MuIconButtonSize.l,
                    onPressed: _back,
                  ),
                  const Spacer(),
                  MuButton.tertiary(label: l10n.passer, onPressed: _back),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                FlowTitle(
                  l10n.leScoreDuMatch,
                  lead: l10n.facultatifCaAideLIa,
                ),
                const SizedBox(height: MuSpace.s5),
                MuScoreboard(
                  sport: m.sport,
                  status: MuMatchStatus.finished,
                  date: formatDay(m.date),
                  venue: m.court == null ? m.venue : '${m.venue} · ${m.court}',
                  teams: [
                    MuScoreTeam(name: home.name, players: homeNames, you: home.you),
                    MuScoreTeam(name: away.name, players: awayNames, you: away.you),
                  ],
                  sets: sets,
                ),
                const SizedBox(height: MuSpace.s5),
                _SetsHeader(home: homeShort, away: awayShort),
                for (final (i, s) in sets.indexed)
                  _SetRow(
                    index: i,
                    set: s,
                    homeName: homeShort,
                    awayName: awayShort,
                    max: _maxGames,
                    onChanged: (v) => setState(() => _sets![i] = v),
                  ),
                if (sets.length < _maxSets)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: MuButton.tertiary(
                      label: l10n.ajouterUnESet(sets.length + 1),
                      leading: PhosphorIcons.plus(),
                      onPressed: () => setState(() => _sets = [...sets, (0, 0)]),
                    ),
                  ),
                const SizedBox(height: MuSpace.s3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(PhosphorIcons.info(), size: MuSize.iconXs, color: c.textSecondary),
                    const SizedBox(width: MuSpace.s2),
                    Expanded(
                      child: Text(
                        l10n.confirmerontLeScoreSansReponse(_opponents(m)),
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
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
            label: l10n.enregistrerLeScore,
            size: MuButtonSize.xl,
            fullWidth: true,
            loading: _saving,
            onPressed: _saving ? null : () => _save(m),
          ),
        ],
      ),
    );
  }
}

/// « Sets · Toi / Mariem · Ines / Nour ».
class _SetsHeader extends StatelessWidget {
  const _SetsHeader({required this.home, required this.away});

  final String home;
  final String away;

  // mat-set: grid 56px 1fr 16px 1fr.
  static const double _label = 56;
  static const double _dash = 16;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _label,
            child: Text(l10n.sets, style: MuType.h3.copyWith(color: c.text)),
          ),
          Expanded(
            child: Text(
              home,
              textAlign: TextAlign.center,
              style: MuType.labelS.copyWith(color: c.textSecondary),
            ),
          ),
          const SizedBox(width: _dash),
          Expanded(
            child: Text(
              away,
              textAlign: TextAlign.center,
              style: MuType.labelS.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.index,
    required this.set,
    required this.homeName,
    required this.awayName,
    required this.max,
    required this.onChanged,
  });

  final int index;
  final (int, int) set;
  final String homeName;
  final String awayName;
  final int max;
  final ValueChanged<(int, int)> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _SetsHeader._label,
            child: Text(l10n.setText(index + 1), style: MuType.label.copyWith(color: c.text)),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: MuStepper(
                value: set.$1,
                min: 0,
                max: max,
                size: MuStepperSize.s,
                layout: MuStepperLayout.bare,
                label: l10n.setText2(index + 1, homeName),
                decrementLabel: l10n.retirerUnJeuA(homeName.replaceAll(' / ', ' et ')),
                incrementLabel: l10n.ajouterUnJeuA(homeName.replaceAll(' / ', ' et ')),
                onChanged: (v) => onChanged((v, set.$2)),
              ),
            ),
          ),
          SizedBox(
            width: _SetsHeader._dash,
            child: Text(
              '–',
              textAlign: TextAlign.center,
              style: MuType.numS.copyWith(color: c.textSecondary),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: MuStepper(
                value: set.$2,
                min: 0,
                max: max,
                size: MuStepperSize.s,
                layout: MuStepperLayout.bare,
                label: l10n.setText2(index + 1, awayName),
                decrementLabel: l10n.retirerUnJeuA(awayName.replaceAll(' / ', ' et ')),
                incrementLabel: l10n.ajouterUnJeuA(awayName.replaceAll(' / ', ' et ')),
                onChanged: (v) => onChanged((set.$1, v)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
