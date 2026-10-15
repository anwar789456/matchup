import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/pro_providers.dart';
import '../../common/widgets/pro_dashboard_scaffold.dart';
import '../../common/widgets/pro_wizard_scaffold.dart' show showComingSoon;
import '../controllers/coach_controller.dart';
import '../data/coach_draft.dart';

List<MuNavSection> coachNav() => [
  MuNavSection(
    items: [
      MuNavItem(
        id: 'dashboard',
        label: 'Tableau de bord',
        icon: PhosphorIcons.squaresFour(),
        activeIcon: PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
      ),
    ],
  ),
  MuNavSection(
    heading: 'Coaching',
    items: [
      MuNavItem(id: 'programmes', label: 'Programmes', icon: PhosphorIcons.barbell()),
      MuNavItem(id: 'eleves', label: 'Élèves', icon: PhosphorIcons.users()),
      MuNavItem(id: 'retours', label: 'Retours', icon: PhosphorIcons.chatCircleDots()),
    ],
  ),
  MuNavSection(
    heading: 'Gestion',
    items: [
      MuNavItem(id: 'revenus', label: 'Revenus', icon: PhosphorIcons.coins()),
      MuNavItem(id: 'abonnement', label: 'Abonnement', icon: PhosphorIcons.crownSimple()),
    ],
  ),
];

/// COA-03 — the coach dashboard before the first programme: the diploma check under the bar,
/// the empty programmes card, the AI plan suggestion, the profile and the four KPIs.
class CoachDashboardScreen extends ConsumerWidget {
  const CoachDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final d = ref.watch(coachProvider).requireValue;
    final width = MediaQuery.sizeOf(context).width;
    final firstName = d.name.split(' ').first;
    final sport = d.sports.isEmpty ? null : CoachCatalog.sportName(d.sports.first);
    final photo = d.photo == null ? null : ref.read(uploadedBytesProvider)[d.photo!.id];
    final image = photo == null ? null : MemoryImage(photo);
    final sports = {for (final s in d.sports) CoachCatalog.sportName(s)};
    final focus = [
      for (final s in d.specialties)
        if (!sports.contains(s)) s.toLowerCase(),
    ];

    final banner = d.diplomaSentAt == null
        ? MuBanner(
            variant: MuBannerVariant.strip,
            tone: MuBannerTone.warning,
            title: 'Ajoute ton diplôme pour devenir « Coach vérifié »',
            detail: 'Tes programmes seront publiés dès la validation.',
            action: MuAction('Ajouter', () => context.go(Routes.coachCertification)),
          )
        : MuBanner(
            variant: MuBannerVariant.strip,
            tone: MuBannerTone.info,
            icon: PhosphorIcons.hourglassMedium(),
            title: 'Diplôme en vérification · réponse sous 48 h',
            detail: 'Prépare tes programmes : ils seront publiés dès la validation.',
          );

    final programmes = ProCard(
      padding: const EdgeInsets.all(MuSpace.s8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MuEmptyState(
            illustration: MuEmptyIllustration.programs,
            title: 'Crée ton premier programme',
            description:
                'Des semaines de séances que tes élèves suivent à leur rythme, avec '
                'tes vidéos et tes conseils.',
            actions: [
              MuButton.primary(
                label: 'Créer mon premier programme',
                leading: PhosphorIcons.plus(),
                size: MuButtonSize.l,
                onPressed: () => showComingSoon(context),
              ),
              MuButton.tertiary(
                label: 'Voir un exemple',
                leading: PhosphorIcons.playCircle(),
                size: MuButtonSize.l,
                onPressed: () => showComingSoon(context),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: MuSpace.s6,
            runSpacing: MuSpace.s2,
            children: [
              for (final (icon, text) in [
                (PhosphorIcons.calendarDots(), '4 à 12 semaines'),
                (PhosphorIcons.videoCamera(), 'Vidéos et exercices'),
                (PhosphorIcons.coins(), 'Ton prix, ou inclus dans Premium'),
              ])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: MuSize.iconXs, color: c.textSecondary),
                    const SizedBox(width: MuSpace.s2),
                    Text(text, style: MuType.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MuAiSuggestionCard(
          context: 'Assistant programme',
          title: 'L’IA peut proposer un plan de 4 semaines à partir de ta bio',
          content: 'Rien n’est publié sans toi : tu relis et modifies chaque séance.',
          reasonLead: 'Basé sur',
          reason: focus.isEmpty ? 'ta bio.' : 'ta bio et tes spécialités : ${focus.join(', ')}.',
          primary: MuAction('Proposer un plan', () => showComingSoon(context)),
          primaryIcon: PhosphorIcons.sparkle(),
          secondary: MuAction('Plus tard', () {}),
          onDismiss: () {},
        ),
        const SizedBox(height: MuSpace.s6),
        ProCard(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s5, vertical: MuSpace.s4),
          child: Row(
            children: [
              MuAvatar(name: d.name, image: image),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name, style: MuType.label.copyWith(color: c.text)),
                    const SizedBox(height: _lineGap),
                    Text(
                      'Coach${sport == null ? '' : ' ${sport.toLowerCase()}'} · ${d.district}',
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              MuButton.link(
                label: 'Modifier mon profil',
                onPressed: () => context.go(Routes.coachProfile),
              ),
            ],
          ),
        ),
      ],
    );

    return ProDashboardScaffold(
      sections: coachNav(),
      role: MuSidebarRole(
        role: 'Coach',
        name: [?sport, d.district].join(' · '),
        initials: initialsOf(d.name),
        image: image,
      ),
      user: MuSidebarUser(name: d.name, email: d.email, image: image),
      userRole: 'Coach',
      banner: banner,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Bienvenue, $firstName', style: MuType.h1.copyWith(color: c.text)),
          ),
          const SizedBox(height: MuSpace.s1),
          Text(
            'Ton profil coach est prêt. Crée ton premier programme pour accueillir tes élèves.',
            style: MuType.bodyL.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: MuSpace.s6),
          ProSplit(start: programmes, end: side, narrowRatio: (13, 10)),
          const SizedBox(height: MuSpace.s6),
          ProCardRow(
            columns: width < ProSplit.stackBelow ? 2 : 4,
            children: const [
              MuKpiCard(label: 'Élèves', value: '0', note: 'Tes élèves apparaîtront ici'),
              MuKpiCard(
                label: 'Inscriptions actives',
                value: '0',
                note: 'Dès ton premier programme publié',
              ),
              MuKpiCard(
                label: 'Revenus du mois',
                value: '0',
                unit: 'DT',
                note: 'Versés chaque lundi',
              ),
              MuKpiCard(label: 'Note moyenne', value: '—', note: 'Après les premiers retours'),
            ],
          ),
        ],
      ),
    );
  }

  // COA-03 source: 2 px between the profile lines.
  static const double _lineGap = 2;
}
