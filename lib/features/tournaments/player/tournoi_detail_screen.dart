import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../home/controllers/home_providers.dart';
import '../controllers/tournoi_providers.dart';
import '../data/tournoi_repository.dart';
import '../organizer/org_widgets.dart';
import 'inscrire_equipe_screen.dart';
import 'match_screen.dart';

/// TRN-02 · Détail du tournoi: dates, fees, places, prize, format, venue, the confirmed teams, and
/// what I can do: register my team, see it, join one with a code, follow the bracket.
class TournoiDetailScreen extends ConsumerWidget {
  const TournoiDetailScreen({super.key, required this.id});

  final String id;

  Future<void> _rejoindre(BuildContext context, WidgetRef ref) async {
    final code = TextEditingController();
    final ok = await MuDialog.show<bool>(
      context,
      title: l10n.trnRejoindreEquipe,
      description: l10n.trnRejoindreDescription,
      content: MuTextField(label: l10n.trnCodeInvitation, controller: code),
      actions: [
        MuButton.tertiary(label: l10n.annuler, onPressed: () => Navigator.of(context, rootNavigator: true).pop(false)),
        MuButton.primary(label: l10n.trnRejoindre, onPressed: () => Navigator.of(context, rootNavigator: true).pop(true)),
      ],
    );
    if (ok != true || code.text.trim().isEmpty) return;
    try {
      final me = await ref.read(meProvider.future);
      await ref.read(tournoiRepositoryProvider).rejoindre(code.text, nom: me.displayName);
      refreshTournoi(ref, id);
      if (context.mounted) context.push(Routes.tournoiEquipe(id));
    } on TournoiRefus catch (e) {
      if (context.mounted) toastRefus(context, e);
    }
  }

  /// TRN-03 « S'inscrire »: an event registers me alone (a one-player team), then I pay.
  Future<void> _inscrireSeul(BuildContext context, WidgetRef ref, Tournoi t) async {
    try {
      final me = await ref.read(meProvider.future);
      final team = await ref.read(tournoiRepositoryProvider).inscrire(id, nom: me.displayName, capitaineNom: me.displayName);
      refreshTournoi(ref, id);
      if (!context.mounted) return;
      if (team.paye) {
        context.push(Routes.tournoiEquipe(id));
      } else {
        payerInscription(context, ref, t, team);
      }
    } on TournoiRefus catch (e) {
      if (context.mounted) toastRefus(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final repo = ref.watch(tournoiRepositoryProvider);
    return TournoiLoader(
      id: id,
      builder: (context, t) {
        final d = t.draft;
        final teams = ref.watch(equipesProvider(id)).value ?? const <Equipe>[];
        final mine = ref.watch(monEquipeProvider(id)).value;
        final confirmed = [for (final e in teams) if (e.statut == EquipeStatut.confirmee) e];
        final organiser = t.organisateurId != null && t.organisateurId == repo.me();
        final open = t.statut == TournoiStatut.inscriptionsOuvertes && t.organisateurId != null;
        final full = confirmed.length >= d.equipesMax;

        final Widget cta;
        if (organiser) {
          cta = MuButton.primary(
            label: l10n.trnGererTournoi,
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: () => context.push(Routes.organizerTournoi(id)),
          );
        } else if (mine != null) {
          cta = MuButton.primary(
            label: d.evenement ? l10n.trnMonInscription : l10n.trnMonEquipe(mine.nom),
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: () => context.push(Routes.tournoiEquipe(id)),
          );
        } else {
          cta = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MuButton.primary(
                label: !open
                    ? (t.organisateurId == null ? l10n.trnInscriptionsBientot : l10n.trnStatutFerme)
                    : (full ? l10n.trnComplet : (d.evenement ? l10n.trnSInscrire : l10n.trnInscrireEquipe)),
                price: open && !full ? formatDT(d.fraisEquipe) : null,
                size: MuButtonSize.l,
                fullWidth: true,
                onPressed: !open || full
                    ? null
                    : (d.evenement ? () => _inscrireSeul(context, ref, t) : () => context.push(Routes.tournoiInscrire(id))),
              ),
              if (open && !d.evenement)
                MuButton.tertiary(label: l10n.trnJaiUnCode, onPressed: () => _rejoindre(context, ref)),
            ],
          );
        }

        Widget fact(IconData icon, String title, String value, String? caption) => Expanded(
              child: Container(
                padding: const EdgeInsetsDirectional.all(MuSpace.s3),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(MuRadius.md),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 20, color: c.textSecondary),
                    const SizedBox(height: MuSpace.s2),
                    Text(title, style: MuType.caption.copyWith(color: c.textSecondary)),
                    Text(value, style: MuType.labelL.copyWith(color: c.text)),
                    if (caption != null) Text(caption, style: MuType.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            );

        return OrgPage(
          title: l10n.trnDetailDuTournoi,
          back: Routes.home,
          bottom: cta,
          children: [
            Row(children: [MuSportTile(d.sport, size: MuMediaTileSize.row), const SizedBox(width: MuSpace.s3), statutBadge(t.statut)]),
            const SizedBox(height: MuSpace.s3),
            Text(d.nom, style: MuType.h2.copyWith(color: c.text)),
            const SizedBox(height: MuSpace.s1),
            Text(
              [
                d.sport.label,
                if (d.niveauMin != null && d.niveauMax != null)
                  l10n.trnNiveauFourchette(formatLevel(d.niveauMin!), formatLevel(d.niveauMax!)),
              ].join(' · '),
              style: MuType.body.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: MuSpace.s5),
            Row(children: [
              fact(PhosphorIcons.calendarBlank(), l10n.trnDates, formatDateRange(d.debut, d.fin), null),
              const SizedBox(width: MuSpace.s3),
              fact(PhosphorIcons.ticket(), l10n.trnInscription, formatDT(d.fraisEquipe), d.evenement ? l10n.trnParPersonne : l10n.trnParEquipeDe(d.joueursParEquipe)),
            ]),
            const SizedBox(height: MuSpace.s3),
            Row(children: [
              fact(PhosphorIcons.usersThree(), l10n.trnPlaces, l10n.trnInscritesSur(confirmed.length, d.equipesMax), null),
              const SizedBox(width: MuSpace.s3),
              fact(PhosphorIcons.trophy(), l10n.trnDotation, d.dotation == null ? '—' : formatDT(d.dotation!), l10n.trnAuTotal),
            ]),
            const SizedBox(height: MuSpace.s5),
            Text(l10n.trnFormat, style: MuType.h3.copyWith(color: c.text)),
            const SizedBox(height: MuSpace.s2),
            Text(
              d.evenement
                  ? l10n.trnEvenementResume(d.equipesMax)
                  : (d.format == TournoiFormat.elimination ? l10n.trnEliminationResume(d.equipesMax) : l10n.trnPoulesResume(d.nbPoules)),
              style: MuType.body.copyWith(color: c.text),
            ),
            if (d.description != null) ...[
              const SizedBox(height: MuSpace.s3),
              Text(d.description!, style: MuType.body.copyWith(color: c.textSecondary)),
            ],
            const SizedBox(height: MuSpace.s5),
            Text(l10n.trnLieu, style: MuType.h3.copyWith(color: c.text)),
            const SizedBox(height: MuSpace.s2),
            Text(d.etablissement, style: MuType.labelL.copyWith(color: c.text)),
            Text(d.lieu, style: MuType.body.copyWith(color: c.textSecondary)),
            AnnoncesSection(id: id),
            if (t.tableauPublie) ...[
              const SizedBox(height: MuSpace.s5),
              MuButton.secondary(
                label: l10n.trnLeTableau,
                leading: PhosphorIcons.treeStructure(),
                fullWidth: true,
                onPressed: () => context.push(Routes.tournoiTableau(id)),
              ),
            ],
            const SizedBox(height: MuSpace.s5),
            Text(d.evenement ? l10n.trnParticipantsN(confirmed.length) : l10n.trnEquipesInscrites(confirmed.length),
                style: MuType.h3.copyWith(color: c.text)),
            const SizedBox(height: MuSpace.s2),
            if (confirmed.isEmpty)
              Text(l10n.trnAucuneEquipeValidee, style: MuType.body.copyWith(color: c.textSecondary))
            else
              for (final e in confirmed)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: MuSpace.s2),
                  child: Row(children: [
                    MuAvatar(name: e.nom, size: MuAvatarSize.s),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.nom, style: MuType.label.copyWith(color: c.text)),
                        Text(e.membres.map((m) => m.$2).join(' · '), style: MuType.caption.copyWith(color: c.textSecondary)),
                      ]),
                    ),
                  ]),
                ),
          ],
        );
      },
    );
  }
}
