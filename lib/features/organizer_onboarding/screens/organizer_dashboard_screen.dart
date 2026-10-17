import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/pro_providers.dart';
import '../../common/widgets/pro_dashboard_scaffold.dart';
import '../../common/widgets/pro_wizard_scaffold.dart' show ProSpace, showComingSoon;
import '../controllers/organizer_controller.dart';
import '../../../l10n/l10n.dart';

/// ORG-02 — the organiser dashboard before the first tournament, as a phone page: the « Premier
/// pas » hero (text over the court art), how it works in three stacked steps, and the AI planning
/// teaser.
class OrganizerDashboardScreen extends ConsumerWidget {
  const OrganizerDashboardScreen({super.key});

  // ORG-02 source: the hero art 260 high; 40 step tiles; 2 px between the AI lines.
  static const double _heroArt = 260;
  static const double _tile = 40;
  static const double _lineGap = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final d = ref.watch(organizerProvider).requireValue;
    final firstName = d.manager.split(' ').first;
    final org = d.name.trim().isEmpty ? l10n.tonOrganisation : d.name.trim();
    final logo = d.logo == null ? null : ref.read(uploadedBytesProvider)[d.logo!.id];
    final last = d.events.firstOrNull;

    final heroText = Padding(
      padding: const EdgeInsets.all(MuSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.premierPas, style: MuType.overline.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s4),
          Semantics(
            header: true,
            child: Text(l10n.creeTonPremierTournoi, style: MuType.h2.copyWith(color: c.text)),
          ),
          const SizedBox(height: MuSpace.s4),
          Text(
            l10n.formatTerrainsDatesFraisD,
            style: MuType.bodyL.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: MuSpace.s6),
          Wrap(
            spacing: MuSpace.s3,
            runSpacing: MuSpace.s3,
            children: [
              MuButton.primary(
                label: l10n.creerUnTournoi,
                leading: PhosphorIcons.plus(),
                size: MuButtonSize.l,
                onPressed: () => showComingSoon(context),
              ),
              if (last != null)
                MuButton.secondary(
                  label: l10n.reprendre(last.name),
                  leading: PhosphorIcons.copy(),
                  size: MuButtonSize.l,
                  onPressed: () => showComingSoon(context),
                ),
            ],
          ),
        ],
      ),
    );

    final art = SizedBox(
      height: _heroArt,
      child: MuCourtArt(
        sport: MuSport.padel,
        semanticLabel: l10n.courtDePadelEclaireLe,
      ),
    );

    final hero = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        boxShadow: MuElevation.of(context).level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [heroText, art],
      ),
    );

    Widget stepCard(int n, IconData icon, String title, String body) => Semantics(
          container: true,
          label: l10n.etape(n),
          child: ProCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: _tile,
                      height: _tile,
                      decoration:
                          BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
                      child: Icon(icon, size: MuSize.iconS, color: c.text),
                    ),
                    const Spacer(),
                    ExcludeSemantics(
                      child: Text(n.toString().padLeft(2, '0'),
                          style: MuType.numL.copyWith(color: c.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s3),
                Text(title, style: MuType.labelL.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s3),
                Text(body, style: MuType.body.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
        );

    return ProDashboardScaffold(
      space: ProSpace.organizer,
      userName: d.manager,
      userRole: d.managerRole,
      userEmail: d.email,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // The organisation's logo, or its initials until there is one.
              MuAvatar(
                name: org,
                image: logo == null ? null : MemoryImage(logo),
                size: MuAvatarSize.s,
              ),
              const SizedBox(width: MuSpace.s2),
              Expanded(
                child: Text(
                  [l10n.organisateur, org].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MuType.labelS.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s2),
          Semantics(
            header: true,
            child: Text(l10n.bienvenue(firstName), style: MuType.h1.copyWith(color: c.text)),
          ),
          const SizedBox(height: MuSpace.s1),
          Text(
            l10n.estPreteLanceTonPremier(org),
            style: MuType.bodyL.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: MuSpace.s2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: MuButton.tertiary(
              label: l10n.modifierLOrganisation,
              leading: PhosphorIcons.pencilSimple(),
              onPressed: () => context.go(Routes.organizerOrganisation),
            ),
          ),
          const SizedBox(height: MuSpace.s4),
          hero,
          const SizedBox(height: MuSpace.s6),
          Semantics(
            header: true,
            child: Text(l10n.commentCaMarche, style: MuType.h3.copyWith(color: c.text)),
          ),
          const SizedBox(height: MuSpace.s4),
          stepCard(1, PhosphorIcons.trophy(), l10n.cree, l10n.choisisLeFormatLesTerrains),
          const SizedBox(height: MuSpace.s3),
          stepCard(
            2,
            PhosphorIcons.usersThree(),
            l10n.ouvreLesInscriptions,
            l10n.partageLeLienLesEquipes,
          ),
          const SizedBox(height: MuSpace.s3),
          stepCard(
            3,
            PhosphorIcons.listNumbers(),
            l10n.publieLeTableau,
            l10n.poulesEtTableauFinalPuis,
          ),
          const SizedBox(height: MuSpace.s6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s5, vertical: MuSpace.s4),
            decoration: BoxDecoration(color: c.aiSoft, borderRadius: MuRadius.mdAll),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MuAiLabel(),
                const SizedBox(width: MuSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.bientotLIaPrepareTon,
                          style: MuType.label.copyWith(color: c.text)),
                      const SizedBox(height: _lineGap),
                      Text(
                        l10n.aPartirDeTesTerrains,
                        style: MuType.body.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
