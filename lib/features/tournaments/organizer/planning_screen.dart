import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/tournoi_providers.dart';
import '../data/tournoi_repository.dart';
import '../logic/bracket_logic.dart';
import 'org_widgets.dart';

/// ORG-11 · Planning: the constraints (courts, hours, match length, rest), « Générer » draws the
/// validated teams and schedules them, then « Publier » shows the bracket to the players.
class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  int _courts = 2;
  int _debutH = 9;
  int _finH = 20;
  int _duree = 60;
  int _repos = 30;
  bool _busy = false;

  Future<void> _generer(Tournoi t) async {
    setState(() => _busy = true);
    final days = <TimeWindow>[];
    for (var d = DateTime(t.draft.debut.year, t.draft.debut.month, t.draft.debut.day);
        !d.isAfter(t.draft.fin);
        d = d.add(const Duration(days: 1))) {
      days.add((debut: d.add(Duration(hours: _debutH)), fin: d.add(Duration(hours: _finH))));
    }
    try {
      await ref.read(tournoiRepositoryProvider).generer(
            widget.id,
            terrains: [for (var i = 1; i <= _courts; i++) l10n.trnCourtN(i)],
            creneaux: days,
            dureeMatch: Duration(minutes: _duree),
            repos: Duration(minutes: _repos),
          );
      if (mounted) MuToast.show(context, tone: MuToastTone.success, title: l10n.trnPlanningGenere);
    } on ScheduleError catch (e) {
      if (mounted) {
        MuToast.show(context, tone: MuToastTone.error, title: l10n.trnPasAssezCreneaux(e.manquants));
      }
    } on TournoiRefus catch (e) {
      if (mounted) toastRefus(context, e);
    } finally {
      refreshTournoi(ref, widget.id);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publier() async {
    await ref.read(tournoiRepositoryProvider).publierTableau(widget.id);
    refreshTournoi(ref, widget.id);
    if (mounted) MuToast.show(context, tone: MuToastTone.success, title: l10n.trnTableauPublie);
  }

  @override
  Widget build(BuildContext context) => TournoiLoader(
        id: widget.id,
        builder: (context, t) {
          final c = context.mu;
          final matches = ref.watch(matchsProvider(widget.id)).value ?? const <MatchPlan>[];
          final names = teamNames(ref.watch(equipesProvider(widget.id)).value ?? const []);
          final played = matches.where((m) => !m.exempt).toList()
            ..sort((a, b) => (a.debut ?? DateTime(9999)).compareTo(b.debut ?? DateTime(9999)));
          final hours = [for (var h = 7; h <= 23; h++) MuSelectOption(value: h, label: formatHour(h * 60))];
          return OrgPage(
            title: l10n.trnPlanning,
            subtitle: t.draft.nom,
            back: Routes.organizerTournoi(widget.id),
            bottom: Row(
              children: [
                Expanded(
                  child: MuButton.secondary(
                    label: matches.isEmpty ? l10n.trnGenerer : l10n.trnRegenerer,
                    leading: PhosphorIcons.sparkle(),
                    fullWidth: true,
                    loading: _busy,
                    onPressed: _busy || t.tableauPublie ? null : () => _generer(t),
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: MuButton.primary(
                    label: t.tableauPublie ? l10n.trnPublie2 : l10n.trnPublierTableau,
                    fullWidth: true,
                    onPressed: matches.isEmpty || t.tableauPublie ? null : _publier,
                  ),
                ),
              ],
            ),
            children: [
              Text(l10n.trnTesContraintes, style: MuType.h3.copyWith(color: c.text)),
              const SizedBox(height: MuSpace.s3),
              MuStepper(
                label: l10n.trnCourtsDisponibles,
                value: _courts,
                min: 1,
                max: 8,
                onChanged: (v) => setState(() => _courts = v),
              ),
              const SizedBox(height: MuSpace.s4),
              Row(
                children: [
                  Expanded(
                    child: MuSelect<int>(
                      label: l10n.trnDe,
                      value: _debutH,
                      options: hours,
                      onChanged: (v) => setState(() => _debutH = v),
                    ),
                  ),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: MuSelect<int>(
                      label: l10n.trnA,
                      value: _finH,
                      options: hours,
                      onChanged: (v) => setState(() => _finH = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MuSpace.s4),
              MuSelect<int>(
                label: l10n.trnDureeMatch,
                value: _duree,
                options: [
                  for (final m in const [30, 45, 60, 90]) MuSelectOption(value: m, label: formatClockMinutes(m)),
                ],
                onChanged: (v) => setState(() => _duree = v),
              ),
              const SizedBox(height: MuSpace.s4),
              MuSelect<int>(
                label: l10n.trnReposEntreMatchs,
                value: _repos,
                options: [
                  for (final m in const [0, 15, 30, 60, 90]) MuSelectOption(value: m, label: formatClockMinutes(m)),
                ],
                onChanged: (v) => setState(() => _repos = v),
              ),
              const SizedBox(height: MuSpace.s6),
              Text(l10n.trnPlanningPropose, style: MuType.h3.copyWith(color: c.text)),
              const SizedBox(height: MuSpace.s2),
              if (matches.isEmpty)
                Text(l10n.trnPlanningVide, style: MuType.body.copyWith(color: c.textSecondary))
              else ...[
                Text(
                  t.tableauPublie ? l10n.trnPlanningPublie : l10n.trnRienPublie,
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: MuSpace.s3),
                for (final m in played) MatchLine(match: m, names: names, sizes: roundSizes(matches)),
              ],
            ],
          );
        },
      );
}

/// « 45 min », « 1 h », « 1 h 30 ».
String formatClockMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m';
}

/// « Poule A », « Demie 2 », « Finale ».
String matchLabel(MatchPlan m, List<int> sizes) {
  if (m.phase == Phase.poule) return l10n.trnPouleJ(m.poule ?? '', m.tour);
  final count = m.tour < sizes.length ? sizes[m.tour] : 1;
  return switch (count) {
    1 => l10n.trnFinale,
    2 => l10n.trnDemie(m.ordre + 1),
    4 => l10n.trnQuart(m.ordre + 1),
    _ => l10n.trnTourDe(count * 2, m.ordre + 1),
  };
}

/// One match: time and court, the two teams (or « À déterminer »), the score once played.
class MatchLine extends StatelessWidget {
  const MatchLine({super.key, required this.match, required this.names, required this.sizes, this.onTap});

  final MatchPlan match;
  final Map<String, String> names;
  final List<int> sizes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final m = match;
    String team(String? id) => id == null ? l10n.trnADeterminer : (names[id] ?? l10n.trnADeterminer);
    final score = m.score1 == null ? null : '${m.score1} – ${m.score2}';
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: MuSpace.s2),
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MuRadius.md),
          side: BorderSide(color: m.statut == MatchStatus.enDirect ? c.primary : c.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(MuRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(MuSpace.s3),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.debut == null ? '—' : formatTime(m.debut!), style: MuType.label.copyWith(color: c.text)),
                      Text(m.terrain ?? '', style: MuType.caption.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(matchLabel(m, sizes), style: MuType.caption.copyWith(color: c.textSecondary)),
                      Text(team(m.equipe1),
                          style: MuType.body.copyWith(
                              color: c.text,
                              fontWeight: m.vainqueur != null && m.vainqueur == m.equipe1 ? FontWeight.w700 : null)),
                      Text(team(m.equipe2),
                          style: MuType.body.copyWith(
                              color: c.text,
                              fontWeight: m.vainqueur != null && m.vainqueur == m.equipe2 ? FontWeight.w700 : null)),
                    ],
                  ),
                ),
                if (m.statut == MatchStatus.enDirect)
                  MuStatusBadge(status: MuStatus.live, label: score ?? l10n.trnEnDirect, size: MuBadgeSize.s)
                else if (score != null)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(score, style: MuType.labelL.copyWith(color: c.text)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
