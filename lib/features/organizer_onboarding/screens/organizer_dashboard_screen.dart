import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/pro_providers.dart';
import '../../common/widgets/pro_dashboard_scaffold.dart';
import '../../common/widgets/pro_wizard_scaffold.dart' show showComingSoon;
import '../controllers/organizer_controller.dart';
import '../../../l10n/l10n.dart';

List<MuNavSection> organizerNav() => [
      MuNavSection(items: [
        MuNavItem(
          id: 'dashboard',
          label: l10n.tableauDeBord,
          icon: PhosphorIcons.squaresFour(),
          activeIcon: PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
        ),
      ]),
      MuNavSection(heading: l10n.competitions, items: [
        MuNavItem(id: 'tournois', label: l10n.tournoisEvenements, icon: PhosphorIcons.trophy()),
        MuNavItem(id: 'equipes', label: l10n.equipes, icon: PhosphorIcons.usersThree()),
        MuNavItem(id: 'calendrier', label: l10n.calendrier, icon: PhosphorIcons.calendarDots()),
        MuNavItem(id: 'scores', label: l10n.scoresEnDirect, icon: PhosphorIcons.broadcast()),
      ]),
      MuNavSection(heading: l10n.gestion, items: [
        MuNavItem(id: 'annonces', label: l10n.annonces, icon: PhosphorIcons.megaphone()),
        MuNavItem(id: 'revenus', label: l10n.revenus, icon: PhosphorIcons.coins()),
      ]),
    ];

/// ORG-02 — the organiser dashboard before the first tournament: the « Premier pas » hero, how it
/// works in three steps, and the AI planning teaser.
class OrganizerDashboardScreen extends ConsumerWidget {
  const OrganizerDashboardScreen({super.key});

  // ORG-02 source: hero columns 1,25fr / 1fr, art at least 260 high; 40 step tiles; 2 px between
  // the AI lines.
  static const int _heroTextFlex = 125;
  static const int _heroArtFlex = 100;
  static const double _heroArtMin = 260;
  static const double _tile = 40;
  static const double _lineGap = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final d = ref.watch(organizerProvider).requireValue;
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < ProSplit.stackBelow;
    final firstName = d.manager.split(' ').first;
    final org = d.name.trim().isEmpty ? l10n.tonOrganisation : d.name.trim();
    final logo = d.logo == null ? null : ref.read(uploadedBytesProvider)[d.logo!.id];
    final last = d.events.firstOrNull;

    final heroText = Padding(
      padding: const EdgeInsets.all(MuSpace.s8),
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

    final art = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _heroArtMin),
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
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [heroText, SizedBox(height: _heroArtMin, child: art)],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: _heroTextFlex, child: heroText),
                  Expanded(flex: _heroArtFlex, child: art),
                ],
              ),
            ),
    );

    Widget stepCard(int n, IconData icon, String title, String body) => Semantics(
          container: true,
          label: l10n.etape(n),
          child: ProCard(
            padding: const EdgeInsets.all(MuSpace.s5),
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
      sections: organizerNav(),
      role: MuSidebarRole(
        role: l10n.organisateur,
        name: org,
        image: logo == null ? null : MemoryImage(logo),
      ),
      user: MuSidebarUser(name: d.manager, email: d.email),
      userRole: d.managerRole,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: MuSpace.s6,
            runSpacing: MuSpace.s3,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(l10n.bienvenue(firstName), style: MuType.h1.copyWith(color: c.text)),
                  ),
                  const SizedBox(height: MuSpace.s1),
                  Text(
                    l10n.estPreteLanceTonPremier(org),
                    style: MuType.bodyL.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              MuButton.tertiary(
                label: l10n.modifierLOrganisation,
                leading: PhosphorIcons.pencilSimple(),
                onPressed: () => context.go(Routes.organizerOrganisation),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s6),
          hero,
          const SizedBox(height: MuSpace.s6),
          Semantics(
            header: true,
            child: Text(l10n.commentCaMarche, style: MuType.h3.copyWith(color: c.text)),
          ),
          const SizedBox(height: MuSpace.s4),
          ProCardRow(
            columns: narrow ? 1 : 3,
            children: [
              stepCard(1, PhosphorIcons.trophy(), l10n.cree,
                  l10n.choisisLeFormatLesTerrains),
              stepCard(2, PhosphorIcons.usersThree(), l10n.ouvreLesInscriptions,
                  l10n.partageLeLienLesEquipes),
              stepCard(3, PhosphorIcons.listNumbers(), l10n.publieLeTableau,
                  l10n.poulesEtTableauFinalPuis),
            ],
          ),
          const SizedBox(height: MuSpace.s6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s5, vertical: MuSpace.s4),
            decoration: BoxDecoration(color: c.aiSoft, borderRadius: MuRadius.mdAll),
            child: Row(
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
