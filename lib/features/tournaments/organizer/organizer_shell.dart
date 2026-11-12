import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../organizer_onboarding/screens/organizer_dashboard_screen.dart';
import '../controllers/tournoi_providers.dart';
import '../data/tournoi_repository.dart';
import '../logic/bracket_logic.dart';
import 'org_widgets.dart';
import 'planning_screen.dart';

/// The organiser space's frame (CLAUDE.md rule 14): Tableau · Tournois · Scores · Annonces, each
/// tab keeping its own stack; the teams to validate on Tableau.
class OrganizerShell extends ConsumerWidget {
  const OrganizerShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final pending = ref.watch(orgOverviewProvider).value?.aValider ?? 0;
    return Scaffold(
      backgroundColor: c.bg,
      body: shell,
      bottomNavigationBar: MuTabBar(
        index: shell.currentIndex,
        onChanged: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: [
          MuTabItem(
            icon: PhosphorIcons.gauge(),
            selectedIcon: PhosphorIcons.gauge(PhosphorIconsStyle.fill),
            label: l10n.trnTabTableau,
            badge: pending,
            badgeLabel: l10n.trnAValiderN(pending),
          ),
          MuTabItem(
            icon: PhosphorIcons.trophy(),
            selectedIcon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
            label: l10n.trnTabTournois,
          ),
          MuTabItem(
            icon: PhosphorIcons.scroll(),
            selectedIcon: PhosphorIcons.scroll(PhosphorIconsStyle.fill),
            label: l10n.trnScores,
          ),
          MuTabItem(
            icon: PhosphorIcons.megaphone(),
            selectedIcon: PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
            label: l10n.trnTabAnnonces,
          ),
        ],
      ),
    );
  }
}

/// What ORG-03 sums over my tournaments.
class OrgOverview {
  const OrgOverview({
    required this.tournois,
    required this.inscrites,
    required this.encaisse,
    required this.aValider,
    required this.prochains,
  });

  final List<Tournoi> tournois;
  final int inscrites;
  final num encaisse;
  final int aValider;

  /// (tournament, match), soonest first: the next matches with both teams known.
  final List<(Tournoi, MatchPlan)> prochains;
}

final orgOverviewProvider = FutureProvider<OrgOverview>((ref) async {
  final tournois = await ref.watch(mesTournoisProvider.future);
  var inscrites = 0;
  num encaisse = 0;
  var aValider = 0;
  final prochains = <(Tournoi, MatchPlan)>[];
  for (final t in tournois) {
    final teams = await ref.watch(equipesProvider(t.id).future);
    for (final e in teams) {
      if (e.statut == EquipeStatut.confirmee) inscrites++;
      if (e.statut == EquipeStatut.enAttente) aValider++;
      if (e.statut == EquipeStatut.confirmee && e.paye) encaisse += t.draft.fraisEquipe;
    }
    for (final m in await ref.watch(matchsProvider(t.id).future)) {
      if (!m.exempt && m.statut != MatchStatus.termine && m.equipe1 != null && m.equipe2 != null) {
        prochains.add((t, m));
      }
    }
  }
  prochains.sort((a, b) => (a.$2.debut ?? DateTime(9999)).compareTo(b.$2.debut ?? DateTime(9999)));
  return OrgOverview(
    tournois: tournois,
    inscrites: inscrites,
    encaisse: encaisse,
    aValider: aValider,
    prochains: prochains,
  );
});

/// Tab « Tableau »: ORG-02 « Prêt » until the first tournament, then ORG-03 · Tableau de bord.
class OrgDashboardTab extends ConsumerWidget {
  const OrgDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final o = ref.watch(orgOverviewProvider).value;
    if (o == null || o.tournois.isEmpty) return const OrganizerDashboardScreen();
    final names = <String, String>{};
    for (final t in o.tournois) {
      names.addAll(teamNames(ref.watch(equipesProvider(t.id)).value ?? const []));
    }
    final active = o.tournois.where((t) => t.statut != TournoiStatut.termine && t.statut != TournoiStatut.annule);
    return OrgPage(
      title: l10n.trnTableauDeBord,
      subtitle: l10n.espaceOrganisateur,
      bottom: MuButton.primary(
        label: l10n.creerUnTournoi,
        leading: PhosphorIcons.plus(),
        size: MuButtonSize.l,
        fullWidth: true,
        onPressed: () => context.push(Routes.organizerCreer),
      ),
      children: [
        Row(children: [
          Expanded(child: MuKpiCard(label: l10n.trnEquipes, value: '${o.inscrites}')),
          const SizedBox(width: MuSpace.s3),
          Expanded(child: MuKpiCard(label: l10n.trnEncaisse, value: formatDT(o.encaisse))),
        ]),
        if (o.aValider > 0) ...[
          const SizedBox(height: MuSpace.s4),
          MuBanner(
            tone: MuBannerTone.warning,
            title: l10n.trnEquipesAValider(o.aValider),
            action: MuAction(l10n.trnVoir, () {
              final t = o.tournois.firstWhere((t) => t.statut == TournoiStatut.inscriptionsOuvertes,
                  orElse: () => o.tournois.first);
              context.push(Routes.organizerInscriptions(t.id));
            }),
          ),
        ],
        const SizedBox(height: MuSpace.s5),
        Text(l10n.trnEnCoursN(active.length), style: MuType.h3.copyWith(color: c.text)),
        const SizedBox(height: MuSpace.s2),
        for (final t in active)
          MuSettingsRow(
            icon: PhosphorIcons.trophy(),
            title: t.draft.nom,
            description: '${formatDateRange(t.draft.debut, t.draft.fin)} · ${t.draft.etablissement}',
            onTap: () => context.push(Routes.organizerTournoi(t.id)),
          ),
        const SizedBox(height: MuSpace.s5),
        Text(l10n.trnProchainsMatchs, style: MuType.h3.copyWith(color: c.text)),
        const SizedBox(height: MuSpace.s2),
        if (o.prochains.isEmpty)
          Text(l10n.trnAucunMatchPret, style: MuType.body.copyWith(color: c.textSecondary))
        else
          for (final (t, m) in o.prochains.take(4))
            MatchLine(
              match: m,
              names: names,
              sizes: roundSizes(ref.watch(matchsProvider(t.id)).value ?? const []),
              onTap: () => context.push(Routes.organizerScores(t.id)),
            ),
      ],
    );
  }
}

/// Tab « Scores »: the tournaments with a planning; one opens ORG-12.
class OrgScoresTab extends ConsumerWidget {
  const OrgScoresTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournois = ref.watch(mesTournoisProvider).value ?? const <Tournoi>[];
    final rows = [
      for (final t in tournois)
        if ((ref.watch(matchsProvider(t.id)).value ?? const []).isNotEmpty) t,
    ];
    return OrgPage(
      title: l10n.trnScoresEnDirect,
      children: [
        if (rows.isEmpty) MuEmptyState(title: l10n.trnAucunPlanning, description: l10n.trnPlanningVide),
        for (final t in rows)
          MuSettingsRow(
            icon: PhosphorIcons.scroll(),
            title: t.draft.nom,
            description: formatDateRange(t.draft.debut, t.draft.fin),
            trailing: statutBadge(t.statut),
            onTap: () => context.push(Routes.organizerScores(t.id)),
          ),
      ],
    );
  }
}

/// Tab « Annonces »: each tournament's last announcement and « Nouvelle annonce » (ORG-14).
class OrgAnnoncesTab extends ConsumerWidget {
  const OrgAnnoncesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournois = ref.watch(mesTournoisProvider).value ?? const <Tournoi>[];
    return OrgPage(
      title: l10n.trnTabAnnonces,
      children: [
        if (tournois.isEmpty) MuEmptyState(title: l10n.creeTonPremierTournoi, description: l10n.trnCreerDescription),
        for (final t in tournois) ...[
          MuSettingsRow(
            icon: PhosphorIcons.megaphone(),
            title: t.draft.nom,
            description: (ref.watch(annoncesProvider(t.id)).value ?? const []).firstOrNull?.$1 ?? l10n.trnAucuneAnnonce,
            onTap: () => context.push(Routes.organizerAnnonce(t.id)),
          ),
        ],
      ],
    );
  }
}

/// ORG-14 · Annonce: a message to every team of the tournament (in the app; push and email come
/// with the backend), the ones already sent below.
class AnnonceScreen extends ConsumerStatefulWidget {
  const AnnonceScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AnnonceScreen> createState() => _AnnonceScreenState();
}

class _AnnonceScreenState extends ConsumerState<AnnonceScreen> {
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_message.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(tournoiRepositoryProvider).annoncer(widget.id, _message.text);
      _message.clear();
      refreshTournoi(ref, widget.id);
      if (mounted) MuToast.show(context, tone: MuToastTone.success, title: l10n.trnAnnonceEnvoyee);
    } on TournoiRefus catch (e) {
      if (mounted) toastRefus(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TournoiLoader(
        id: widget.id,
        builder: (context, t) {
          final c = context.mu;
          final teams = ref.watch(equipesProvider(widget.id)).value ?? const <Equipe>[];
          final confirmed = teams.where((e) => e.statut == EquipeStatut.confirmee).length;
          final sent = ref.watch(annoncesProvider(widget.id)).value ?? const <(String, DateTime)>[];
          return OrgPage(
            title: l10n.trnAnnonce,
            subtitle: t.draft.nom,
            back: Routes.organizerAnnonces,
            bottom: MuButton.primary(
              label: l10n.trnEnvoyer,
              leading: PhosphorIcons.paperPlaneRight(),
              size: MuButtonSize.l,
              fullWidth: true,
              loading: _busy,
              onPressed: _busy ? null : _send,
            ),
            children: [
              Text(l10n.trnAnnonceDescription(confirmed), style: MuType.body.copyWith(color: c.textSecondary)),
              const SizedBox(height: MuSpace.s4),
              MuTextField(label: l10n.trnMessage, controller: _message, maxLines: 6),
              const SizedBox(height: MuSpace.s2),
              Text(l10n.trnAnnonceVisible, style: MuType.caption.copyWith(color: c.textSecondary)),
              if (sent.isNotEmpty) ...[
                const SizedBox(height: MuSpace.s5),
                Text(l10n.trnDejaEnvoyees, style: MuType.h3.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s2),
                for (final (message, at) in sent)
                  MuSettingsRow(title: message, description: formatDateTime(at), chevron: false),
              ],
            ],
          );
        },
      );
}
