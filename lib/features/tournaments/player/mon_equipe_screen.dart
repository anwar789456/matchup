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
import '../controllers/tournoi_providers.dart';
import '../data/tournoi_repository.dart';
import '../logic/bracket_logic.dart';
import '../organizer/org_widgets.dart';
import '../organizer/planning_screen.dart';
import 'inscrire_equipe_screen.dart';

/// TRN-06 / TRN-07 · Mon équipe: where the registration stands (paid, validation, draw), the
/// invite code, the members and my matches once the bracket is out.
class MonEquipeScreen extends ConsumerWidget {
  const MonEquipeScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TournoiLoader(
        id: id,
        builder: (context, t) {
          final c = context.mu;
          final team = ref.watch(monEquipeProvider(id)).value;
          if (team == null) {
            return OrgPage(
              title: l10n.trnMonEquipe(''),
              back: Routes.tournoi(id),
              children: [MuEmptyState(title: l10n.trnPasDEquipe, compact: true)],
            );
          }
          final matches = ref.watch(matchsProvider(id)).value ?? const <MatchPlan>[];
          final names = teamNames(ref.watch(equipesProvider(id)).value ?? const []);
          final mine = [
            for (final m in matches)
              if (!m.exempt && (m.equipe1 == team.id || m.equipe2 == team.id)) m,
          ]..sort((a, b) => (a.debut ?? DateTime(9999)).compareTo(b.debut ?? DateTime(9999)));
          final captain = team.capitaineId == ref.watch(tournoiRepositoryProvider).me();

          Widget step(bool done, bool current, String title, String? text) => Padding(
                padding: const EdgeInsetsDirectional.only(bottom: MuSpace.s3),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(
                    done ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill) : (current ? PhosphorIcons.hourglassMedium() : PhosphorIcons.circle()),
                    color: done ? c.successText : (current ? c.warningText : c.textSecondary),
                  ),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: MuType.label.copyWith(color: c.text)),
                      if (text != null) Text(text, style: MuType.caption.copyWith(color: c.textSecondary)),
                    ]),
                  ),
                ]),
              );

          final refused = team.statut == EquipeStatut.refusee;
          final confirmed = team.statut == EquipeStatut.confirmee;
          return OrgPage(
            title: confirmed ? l10n.trnInscriptionConfirmee : l10n.trnInscriptionEnvoyee,
            subtitle: t.draft.nom,
            back: Routes.tournoi(id),
            bottom: !team.paye && captain
                ? MuButton.primary(
                    label: l10n.trnPayerInscription,
                    price: formatDT(t.draft.fraisEquipe),
                    size: MuButtonSize.l,
                    fullWidth: true,
                    onPressed: () => payerInscription(context, ref, t, team),
                  )
                : (t.tableauPublie
                    ? MuButton.primary(
                        label: l10n.trnLeTableau,
                        size: MuButtonSize.l,
                        fullWidth: true,
                        onPressed: () => context.push(Routes.tournoiTableau(id)),
                      )
                    : null),
            children: [
              Text(team.nom, style: MuType.h2.copyWith(color: c.text)),
              const SizedBox(height: MuSpace.s4),
              step(true, false, l10n.trnEquipeCreee, l10n.trnCapitaineNom(team.membres.first.$2)),
              step(team.paye, !team.paye, l10n.trnInscriptionPayee(formatDT(t.draft.fraisEquipe)),
                  team.paye ? null : l10n.trnPaiementAttendu),
              step(
                confirmed,
                team.paye && team.statut == EquipeStatut.enAttente,
                refused ? l10n.trnRefuseeParOrga : l10n.trnValidationOrga,
                refused ? (team.motif ?? l10n.trnRembourseSiRefus) : (confirmed ? l10n.trnValidee : l10n.trnEnCoursValidation),
              ),
              step(t.tableauPublie && confirmed, confirmed && !t.tableauPublie, l10n.trnTirage,
                  t.tableauPublie ? l10n.trnTableauPublie : l10n.trnTirageNote),
              const SizedBox(height: MuSpace.s3),
              Text(l10n.trnMembresN(team.membres.length, t.draft.joueursParEquipe), style: MuType.h3.copyWith(color: c.text)),
              const SizedBox(height: MuSpace.s2),
              for (final (i, (_, nom)) in team.membres.indexed)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: MuSpace.s2),
                  child: Row(children: [
                    MuAvatar(name: nom, size: MuAvatarSize.s),
                    const SizedBox(width: MuSpace.s3),
                    Text(i == 0 ? '$nom · ${l10n.trnCapitaine}' : nom, style: MuType.body.copyWith(color: c.text)),
                  ]),
                ),
              if (team.membres.length < t.draft.joueursParEquipe) ...[
                const SizedBox(height: MuSpace.s3),
                Container(
                  padding: const EdgeInsetsDirectional.all(MuSpace.s4),
                  decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(MuRadius.md)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(l10n.trnPartageCode, style: MuType.label.copyWith(color: c.text)),
                    const SizedBox(height: MuSpace.s2),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(team.codeInvitation, style: MuType.h2.copyWith(color: c.text, letterSpacing: 4)),
                    ),
                    const SizedBox(height: MuSpace.s2),
                    MuButton.secondary(
                      label: l10n.trnCopierCode,
                      leading: PhosphorIcons.copy(),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: team.codeInvitation));
                        if (context.mounted) MuToast.show(context, tone: MuToastTone.success, title: l10n.trnCodeCopie);
                      },
                    ),
                  ]),
                ),
              ],
              if (mine.isNotEmpty) ...[
                const SizedBox(height: MuSpace.s5),
                Text(l10n.trnTesMatchs, style: MuType.h3.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s2),
                for (final m in mine) MatchLine(match: m, names: names, sizes: roundSizes(matches)),
              ],
              if (captain && team.statut == EquipeStatut.enAttente) ...[
                const SizedBox(height: MuSpace.s5),
                MuButton.tertiary(
                  label: l10n.trnAnnulerInscription,
                  onPressed: () async {
                    await ref.read(tournoiRepositoryProvider).annulerEquipe(team.id);
                    refreshTournoi(ref, id);
                    if (context.mounted) context.go(Routes.tournoi(id));
                  },
                ),
              ],
            ],
          );
        },
      );
}
