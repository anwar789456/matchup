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

List<MuNavSection> organizerNav() => [
      MuNavSection(items: [
        MuNavItem(
          id: 'dashboard',
          label: 'Tableau de bord',
          icon: PhosphorIcons.squaresFour(),
          activeIcon: PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
        ),
      ]),
      MuNavSection(heading: 'Compétitions', items: [
        MuNavItem(id: 'tournois', label: 'Tournois & événements', icon: PhosphorIcons.trophy()),
        MuNavItem(id: 'equipes', label: 'Équipes', icon: PhosphorIcons.usersThree()),
        MuNavItem(id: 'calendrier', label: 'Calendrier', icon: PhosphorIcons.calendarDots()),
        MuNavItem(id: 'scores', label: 'Scores en direct', icon: PhosphorIcons.broadcast()),
      ]),
      MuNavSection(heading: 'Gestion', items: [
        MuNavItem(id: 'annonces', label: 'Annonces', icon: PhosphorIcons.megaphone()),
        MuNavItem(id: 'revenus', label: 'Revenus', icon: PhosphorIcons.coins()),
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
    final org = d.name.trim().isEmpty ? 'Ton organisation' : d.name.trim();
    final logo = d.logo == null ? null : ref.read(uploadedBytesProvider)[d.logo!.id];
    final last = d.events.firstOrNull;

    final heroText = Padding(
      padding: const EdgeInsets.all(MuSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('PREMIER PAS', style: MuType.overline.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s4),
          Semantics(
            header: true,
            child: Text('Crée ton premier tournoi', style: MuType.h2.copyWith(color: c.text)),
          ),
          const SizedBox(height: MuSpace.s4),
          Text(
            'Format, terrains, dates, frais d’inscription : on te guide étape par étape. Ton '
            'brouillon est enregistré à chaque étape.',
            style: MuType.bodyL.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: MuSpace.s6),
          Wrap(
            spacing: MuSpace.s3,
            runSpacing: MuSpace.s3,
            children: [
              MuButton.primary(
                label: 'Créer un tournoi',
                leading: PhosphorIcons.plus(),
                size: MuButtonSize.l,
                onPressed: () => showComingSoon(context),
              ),
              if (last != null)
                MuButton.secondary(
                  label: 'Reprendre ${last.name}',
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
      child: const MuCourtArt(
        sport: MuSport.padel,
        semanticLabel: 'Court de padel éclairé le soir',
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
          label: 'Étape $n',
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
        role: 'Organisateur',
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
                    child: Text('Bienvenue, $firstName', style: MuType.h1.copyWith(color: c.text)),
                  ),
                  const SizedBox(height: MuSpace.s1),
                  Text(
                    '$org est prête. Lance ton premier tournoi en quelques minutes.',
                    style: MuType.bodyL.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              MuButton.tertiary(
                label: 'Modifier l’organisation',
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
            child: Text('Comment ça marche', style: MuType.h3.copyWith(color: c.text)),
          ),
          const SizedBox(height: MuSpace.s4),
          ProCardRow(
            columns: narrow ? 1 : 3,
            children: [
              stepCard(1, PhosphorIcons.trophy(), 'Crée',
                  'Choisis le format, les terrains, les dates et les frais d’inscription.'),
              stepCard(2, PhosphorIcons.usersThree(), 'Ouvre les inscriptions',
                  'Partage le lien : les équipes s’inscrivent et paient leur place en ligne.'),
              stepCard(3, PhosphorIcons.listNumbers(), 'Publie le tableau',
                  'Poules et tableau final, puis les scores en direct le jour J.'),
            ],
          ),
          const SizedBox(height: MuSpace.s6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s5, vertical: MuSpace.s4),
            decoration: BoxDecoration(color: c.aiSoft, borderRadius: MuRadius.mdAll),
            child: Row(
              children: [
                const MuAiLabel(),
                const SizedBox(width: MuSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bientôt : l’IA prépare ton tableau et ton planning',
                          style: MuType.label.copyWith(color: c.text)),
                      const SizedBox(height: _lineGap),
                      Text(
                        'À partir de tes terrains, de tes créneaux et du repos entre deux matchs. '
                        'Tu modifies et valides tout avant de publier.',
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
