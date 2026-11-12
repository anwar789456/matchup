import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/tournoi_providers.dart';
import '../data/tournoi_repository.dart';
import '../logic/bracket_logic.dart';
import '../organizer/org_widgets.dart';
import '../organizer/planning_screen.dart';

enum _Vue { tableau, poules }

/// TRN-08 · Tableau final and TRN-09 · Poules et classement, one screen with a switch: the
/// knockout round by round, and each group's table (3 points a win) with its matches.
class TableauScreen extends ConsumerStatefulWidget {
  const TableauScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TableauScreen> createState() => _TableauScreenState();
}

class _TableauScreenState extends ConsumerState<TableauScreen> {
  _Vue? _vue;

  @override
  Widget build(BuildContext context) => TournoiLoader(
        id: widget.id,
        builder: (context, t) {
          final c = context.mu;
          final matches = ref.watch(matchsProvider(widget.id)).value ?? const <MatchPlan>[];
          final teams = ref.watch(equipesProvider(widget.id)).value ?? const <Equipe>[];
          final mine = ref.watch(monEquipeProvider(widget.id)).value;
          final names = teamNames(teams);
          final sizes = roundSizes(matches);
          final hasGroups = matches.any((m) => m.phase == Phase.poule);
          final vue = _vue ?? (hasGroups ? _Vue.poules : _Vue.tableau);
          final children = <Widget>[];

          if (hasGroups) {
            children
              ..add(MuSegmentedControl<_Vue>(
                semanticLabel: l10n.trnLeTableau,
                expand: true,
                value: vue,
                onChanged: (v) => setState(() => _vue = v),
                segments: [
                  MuSegment(value: _Vue.poules, label: l10n.trnLesPoules),
                  MuSegment(value: _Vue.tableau, label: l10n.trnPhaseFinale),
                ],
              ))
              ..add(const SizedBox(height: MuSpace.s4));
          }

          if (matches.isEmpty) {
            children.add(MuEmptyState(title: l10n.trnTableauPasPublie, compact: true));
          } else if (vue == _Vue.poules) {
            final letters = {for (final m in matches) if (m.poule != null) m.poule!}.toList()..sort();
            final seed = [for (final e in teams) e.id];
            for (final letter in letters) {
              final played = matches.where((m) => m.phase == Phase.poule && m.poule == letter).toList();
              final ids = {for (final m in played) ...[?m.equipe1, ?m.equipe2]};
              final table = standings([for (final s in seed) if (ids.contains(s)) s], played, qualifies: t.draft.qualifiesParPoule);
              children
                ..add(Text(l10n.trnPouleX(letter), style: MuType.h3.copyWith(color: c.text)))
                ..add(const SizedBox(height: MuSpace.s2))
                ..add(_Standings(rows: table, names: names, mine: mine?.id))
                ..add(const SizedBox(height: MuSpace.s3));
              for (final m in played) {
                children.add(MatchLine(match: m, names: names, sizes: sizes));
              }
              children.add(const SizedBox(height: MuSpace.s4));
            }
            children.add(Text(l10n.trnPointsNote, style: MuType.caption.copyWith(color: c.textSecondary)));
          } else {
            for (var tour = 0; tour < sizes.length; tour++) {
              final round = [for (final m in matches) if (m.phase == Phase.elimination && m.tour == tour && !m.exempt) m];
              if (round.isEmpty) continue;
              children
                ..add(Text(_roundName(sizes[tour]), style: MuType.h3.copyWith(color: c.text)))
                ..add(const SizedBox(height: MuSpace.s2));
              for (final m in round) {
                children.add(MatchLine(match: m, names: names, sizes: sizes));
              }
              children.add(const SizedBox(height: MuSpace.s4));
            }
          }
          return OrgPage(
            title: l10n.trnTableauDuTournoi,
            subtitle: t.draft.nom,
            back: Routes.tournoi(widget.id),
            children: children,
          );
        },
      );

  static String _roundName(int matchesInRound) => switch (matchesInRound) {
        1 => l10n.trnFinale,
        2 => l10n.trnDemiFinales,
        4 => l10n.trnQuartsDeFinale,
        8 => l10n.trnHuitiemes,
        _ => l10n.trnTourDe(matchesInRound * 2, 1),
      };
}

/// A group table: rank, team, played, wins, difference, points; qualified rows marked.
class _Standings extends StatelessWidget {
  const _Standings({required this.rows, required this.names, this.mine});

  final List<StandingRow> rows;
  final Map<String, String> names;
  final String? mine;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final head = MuType.caption.copyWith(color: c.textSecondary);
    Widget cell(String text, TextStyle style, {double width = 36}) =>
        SizedBox(width: width, child: Text(text, textAlign: TextAlign.end, style: style));
    return Container(
      padding: const EdgeInsetsDirectional.all(MuSpace.s3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MuRadius.md),
        border: Border.all(color: c.border),
      ),
      child: Directionality(
        textDirection: Directionality.of(context),
        child: Column(children: [
          Row(children: [
            Expanded(child: Text(l10n.trnEquipe, style: head)),
            cell(l10n.trnJ, head),
            cell(l10n.trnV, head),
            cell(l10n.trnDiff, head, width: 44),
            cell(l10n.trnPts, head),
          ]),
          const Divider(),
          for (final r in rows)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: MuSpace.s1),
              child: Row(children: [
                SizedBox(width: 24, child: Text('${r.rang}', style: MuType.label.copyWith(color: c.textSecondary))),
                Expanded(
                  child: Text(
                    names[r.equipe] ?? '',
                    style: (r.equipe == mine ? MuType.label : MuType.body).copyWith(color: c.text),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (r.qualifie)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: MuSpace.s2),
                    child: MuStatusBadge(status: MuStatus.confirmed, label: l10n.trnQualifie, size: MuBadgeSize.s, iconOnly: true),
                  ),
                cell('${r.joues}', MuType.body.copyWith(color: c.text)),
                cell('${r.victoires}', MuType.body.copyWith(color: c.text)),
                cell(r.diff > 0 ? '+${r.diff}' : '${r.diff}', MuType.body.copyWith(color: c.text), width: 44),
                cell('${r.points}', MuType.label.copyWith(color: c.text)),
              ]),
            ),
        ]),
      ),
    );
  }
}
