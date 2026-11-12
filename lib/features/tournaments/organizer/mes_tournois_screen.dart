import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/tournoi_providers.dart';
import '../data/tournoi_repository.dart';
import 'org_widgets.dart';

/// ORG-04 · Mes tournois: in progress, then finished; « Créer un tournoi ».
class MesTournoisScreen extends ConsumerWidget {
  const MesTournoisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final list = ref.watch(mesTournoisProvider);
    final all = list.value ?? const <Tournoi>[];
    final done = {TournoiStatut.termine, TournoiStatut.annule};
    final active = [for (final t in all) if (!done.contains(t.statut)) t];
    final finished = [for (final t in all) if (done.contains(t.statut)) t];
    return OrgPage(
      title: l10n.trnMesTournois,
      bottom: MuButton.primary(
        label: l10n.creerUnTournoi,
        leading: PhosphorIcons.plus(),
        size: MuButtonSize.l,
        fullWidth: true,
        onPressed: () => context.push(Routes.organizerCreer),
      ),
      children: [
        if (list.isLoading && all.isEmpty) Center(child: MuSpinner(semanticLabel: l10n.chargement)),
        if (!list.isLoading && all.isEmpty)
          MuEmptyState(title: l10n.creeTonPremierTournoi, description: l10n.trnCreerDescription),
        if (active.isNotEmpty) ...[
          Text(l10n.trnEnCoursN(active.length), style: MuType.overline.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s3),
          for (final t in active) _TournoiRow(t),
        ],
        if (finished.isNotEmpty) ...[
          const SizedBox(height: MuSpace.s6),
          Text(l10n.trnTerminesN(finished.length), style: MuType.overline.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s3),
          for (final t in finished) _TournoiRow(t),
        ],
      ],
    );
  }
}

class _TournoiRow extends ConsumerWidget {
  const _TournoiRow(this.t);

  final Tournoi t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final teams = ref.watch(equipesProvider(t.id)).value ?? const <Equipe>[];
    final pending = teams.where((e) => e.statut == EquipeStatut.enAttente).length;
    final confirmed = teams.where((e) => e.statut == EquipeStatut.confirmee).length;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: MuSpace.s3),
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MuRadius.lg),
          side: BorderSide(color: c.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(MuRadius.lg),
          onTap: () => context.push(Routes.organizerTournoi(t.id)),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(MuSpace.s4),
            child: Row(
              children: [
                MuSportTile(t.draft.sport, size: MuMediaTileSize.row),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.draft.nom, style: MuType.labelL.copyWith(color: c.text)),
                      const SizedBox(height: MuSpace.s1),
                      Text(
                        '${formatDateRange(t.draft.debut, t.draft.fin)} · ${t.draft.etablissement}',
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: MuSpace.s2),
                      Wrap(
                        spacing: MuSpace.s2,
                        runSpacing: MuSpace.s2,
                        children: [
                          statutBadge(t.statut),
                          MuStatusBadge(
                            status: MuStatus.neutral,
                            label: l10n.trnEquipesSur(confirmed, t.draft.equipesMax),
                          ),
                          if (pending > 0)
                            MuStatusBadge(status: MuStatus.pending, label: l10n.trnAValiderN(pending)),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(PhosphorIcons.caretRight(), color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One tournament's management (the shortcuts of an ORG-04 card): registrations, planning,
/// live scores, announcement; close or reopen registrations.
class TournoiHubScreen extends ConsumerWidget {
  const TournoiHubScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TournoiLoader(
        id: id,
        builder: (context, t) {
          final c = context.mu;
          final teams = ref.watch(equipesProvider(id)).value ?? const <Equipe>[];
          final matches = ref.watch(matchsProvider(id)).value ?? const [];
          final pending = teams.where((e) => e.statut == EquipeStatut.enAttente).length;
          final confirmed = teams.where((e) => e.statut == EquipeStatut.confirmee).length;
          final paid = teams.where((e) => e.statut == EquipeStatut.confirmee && e.paye).length;
          return OrgPage(
            title: t.draft.nom,
            subtitle: '${formatDateRange(t.draft.debut, t.draft.fin)} · ${t.draft.etablissement}',
            back: Routes.organizerTournois,
            children: [
              Row(children: [statutBadge(t.statut)]),
              const SizedBox(height: MuSpace.s4),
              Row(
                children: [
                  Expanded(child: MuKpiCard(label: l10n.trnEncaisse, value: formatDT(paid * t.draft.fraisEquipe))),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(child: MuKpiCard(label: l10n.trnEquipes, value: '$confirmed/${t.draft.equipesMax}')),
                ],
              ),
              const SizedBox(height: MuSpace.s5),
              MuSettingsGroup(
                children: [
                  MuSettingsRow(
                    icon: PhosphorIcons.usersThree(),
                    title: l10n.trnInscriptions,
                    description: pending == 0 ? l10n.trnRienAValider : l10n.trnAValiderN(pending),
                    onTap: () => context.push(Routes.organizerInscriptions(id)),
                  ),
                  if (!t.draft.evenement) MuSettingsRow(
                    icon: PhosphorIcons.calendarDots(),
                    title: l10n.trnPlanning,
                    description: matches.isEmpty
                        ? l10n.trnPlanningAGenerer
                        : (t.tableauPublie ? l10n.trnPlanningPublie : l10n.trnPlanningBrouillon),
                    onTap: () => context.push(Routes.organizerPlanning(id)),
                  ),
                  if (!t.draft.evenement) MuSettingsRow(
                    icon: PhosphorIcons.scroll(),
                    title: l10n.trnScores,
                    description: matches.isEmpty ? l10n.trnScoresApresPlanning : l10n.trnScoresDescription,
                    onTap: matches.isEmpty ? null : () => context.push(Routes.organizerScores(id)),
                  ),
                  MuSettingsRow(
                    icon: PhosphorIcons.megaphone(),
                    title: l10n.trnAnnonce,
                    description: l10n.trnAnnonceDescription(confirmed),
                    onTap: () => context.push(Routes.organizerAnnonce(id)),
                  ),
                ],
              ),
              const SizedBox(height: MuSpace.s5),
              if (t.statut == TournoiStatut.inscriptionsOuvertes)
                MuButton.secondary(
                  label: l10n.trnCloturer,
                  fullWidth: true,
                  onPressed: () => _set(context, ref, () => ref.read(tournoiRepositoryProvider).cloturer(id)),
                ),
              if (t.statut == TournoiStatut.inscriptionsFermees && !t.tableauPublie)
                MuButton.secondary(
                  label: l10n.trnRouvrir,
                  fullWidth: true,
                  onPressed: () => _set(context, ref, () => ref.read(tournoiRepositoryProvider).rouvrir(id)),
                ),
              const SizedBox(height: MuSpace.s3),
              Text(l10n.trnVisibleExplorer, style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          );
        },
      );

  Future<void> _set(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    try {
      await action();
    } on TournoiRefus catch (e) {
      if (context.mounted) toastRefus(context, e);
    }
    refreshTournoi(ref, id);
  }
}
