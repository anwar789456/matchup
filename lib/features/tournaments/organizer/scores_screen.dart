import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/tournoi_providers.dart';
import '../data/tournoi_repository.dart';
import '../logic/bracket_logic.dart';
import 'org_widgets.dart';
import 'planning_screen.dart';

/// ORG-12 · Scores en direct: live, upcoming (both teams known) and finished matches; a match
/// opens the courtside entry (ORG-13).
class ScoresScreen extends ConsumerWidget {
  const ScoresScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TournoiLoader(
        id: id,
        builder: (context, t) {
          final c = context.mu;
          final matches = ref.watch(matchsProvider(id)).value ?? const <MatchPlan>[];
          final names = teamNames(ref.watch(equipesProvider(id)).value ?? const []);
          final sizes = roundSizes(matches);
          final real = matches.where((m) => !m.exempt).toList()
            ..sort((a, b) => (a.debut ?? DateTime(9999)).compareTo(b.debut ?? DateTime(9999)));
          final live = [for (final m in real) if (m.statut == MatchStatus.enDirect) m];
          final next = [
            for (final m in real)
              if (m.statut == MatchStatus.aJouer && m.equipe1 != null && m.equipe2 != null) m,
          ];
          final done = [for (final m in real) if (m.statut == MatchStatus.termine) m].reversed.toList();
          Widget section(String title, List<MatchPlan> list) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: MuSpace.s4),
                  Text(title, style: MuType.overline.copyWith(color: c.textSecondary)),
                  const SizedBox(height: MuSpace.s2),
                  for (final m in list)
                    MatchLine(
                      match: m,
                      names: names,
                      sizes: sizes,
                      onTap: () => ScoreSheet.show(context, ref, t, m, names, sizes),
                    ),
                ],
              );
          return OrgPage(
            title: l10n.trnScoresEnDirect,
            subtitle: t.draft.nom,
            back: Routes.organizerTournoi(id),
            children: [
              Text(l10n.trnToucheUnMatch, style: MuType.caption.copyWith(color: c.textSecondary)),
              if (live.isNotEmpty) section(l10n.trnEnDirectN(live.length), live),
              if (next.isNotEmpty) section(l10n.trnAVenirN(next.length), next),
              if (done.isNotEmpty) section(l10n.trnTerminesN(done.length), done),
              if (live.isEmpty && next.isEmpty && done.isEmpty)
                MuEmptyState(title: l10n.trnAucunMatchPret, compact: true),
            ],
          );
        },
      );
}

/// ORG-13 · Saisie au bord du court: big one-hand buttons per team, the live score is saved as
/// it changes, « Confirmer le score final » moves the winner on.
class ScoreSheet extends ConsumerStatefulWidget {
  const ScoreSheet({super.key, required this.tournoi, required this.match, required this.names, required this.sizes});

  final Tournoi tournoi;
  final MatchPlan match;
  final Map<String, String> names;
  final List<int> sizes;

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    Tournoi t,
    MatchPlan m,
    Map<String, String> names,
    List<int> sizes,
  ) =>
      MuBottomSheet.show<void>(
        context,
        title: '${matchLabel(m, sizes)} · ${m.terrain ?? ''}',
        height: MuSheetHeight.full,
        child: ScoreSheet(tournoi: t, match: m, names: names, sizes: sizes),
      );

  @override
  ConsumerState<ScoreSheet> createState() => _ScoreSheetState();
}

class _ScoreSheetState extends ConsumerState<ScoreSheet> {
  late int _a = widget.match.score1 ?? 0;
  late int _b = widget.match.score2 ?? 0;
  String? _vainqueur;
  bool _busy = false;

  bool get _final => widget.match.statut == MatchStatus.termine;

  Future<void> _live() async {
    try {
      await ref.read(tournoiRepositoryProvider).scoreEnDirect(widget.tournoi.id, widget.match, _a, _b);
      refreshTournoi(ref, widget.tournoi.id);
    } on TournoiRefus catch (e) {
      if (mounted) toastRefus(context, e);
    }
  }

  void _add(bool teamA, int delta) {
    setState(() {
      if (teamA) {
        _a = (_a + delta).clamp(0, 99);
      } else {
        _b = (_b + delta).clamp(0, 99);
      }
    });
    _live();
  }

  Future<void> _confirm() async {
    final ko = widget.match.phase == Phase.elimination;
    if (ko && _a == _b && _vainqueur == null) {
      MuToast.show(context, tone: MuToastTone.error, title: l10n.trnChoisisVainqueur);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(tournoiRepositoryProvider).scoreFinal(widget.tournoi.id, widget.match, _a, _b, vainqueur: _vainqueur);
      refreshTournoi(ref, widget.tournoi.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      MuToast.show(context, tone: MuToastTone.success, title: l10n.trnScoreConfirme);
    } on TournoiRefus catch (e) {
      if (mounted) toastRefus(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final m = widget.match;
    final nameA = widget.names[m.equipe1] ?? l10n.trnADeterminer;
    final nameB = widget.names[m.equipe2] ?? l10n.trnADeterminer;
    Widget side(bool teamA) {
      final name = teamA ? nameA : nameB;
      final score = teamA ? _a : _b;
      return Expanded(
        child: Column(
          children: [
            Text(name, textAlign: TextAlign.center, style: MuType.labelL.copyWith(color: c.text)),
            const SizedBox(height: MuSpace.s3),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text('$score', style: MuType.h1.copyWith(color: c.text)),
            ),
            const SizedBox(height: MuSpace.s3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MuIconButton(
                  icon: PhosphorIcons.minus(),
                  label: l10n.trnRetirerPoint(name),
                  onPressed: _final || score == 0 ? null : () => _add(teamA, -1),
                ),
                const SizedBox(width: MuSpace.s2),
                MuIconButton(
                  icon: PhosphorIcons.plus(),
                  label: l10n.trnAjouterPoint(name),
                  variant: MuIconButtonVariant.primary,
                  onPressed: _final ? null : () => _add(teamA, 1),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.all(MuSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [side(true), side(false)]),
          const SizedBox(height: MuSpace.s5),
          if (m.phase == Phase.elimination && _a == _b && !_final) ...[
            Text(l10n.trnVainqueur, style: MuType.label.copyWith(color: c.text)),
            const SizedBox(height: MuSpace.s2),
            MuSegmentedControl<String>(
              semanticLabel: l10n.trnVainqueur,
              expand: true,
              value: _vainqueur ?? '',
              onChanged: (v) => setState(() => _vainqueur = v),
              segments: [
                if (m.equipe1 != null) MuSegment(value: m.equipe1!, label: nameA),
                if (m.equipe2 != null) MuSegment(value: m.equipe2!, label: nameB),
              ],
            ),
            const SizedBox(height: MuSpace.s4),
          ],
          Text(l10n.trnConfirmerNote, style: MuType.caption.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s4),
          MuButton.primary(
            label: _final ? l10n.trnScoreConfirme : l10n.trnConfirmerScoreFinal,
            size: MuButtonSize.l,
            fullWidth: true,
            loading: _busy,
            onPressed: _final || _busy || m.equipe1 == null || m.equipe2 == null ? null : _confirm,
          ),
        ],
      ),
    );
  }
}
