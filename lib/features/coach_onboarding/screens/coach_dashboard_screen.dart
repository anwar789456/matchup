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
import '../../../l10n/l10n.dart';

List<MuNavSection> coachNav() => [
  MuNavSection(
    items: [
      MuNavItem(
        id: 'dashboard',
        label: l10n.tableauDeBord,
        icon: PhosphorIcons.squaresFour(),
        activeIcon: PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
      ),
    ],
  ),
  MuNavSection(
    heading: l10n.coaching,
    items: [
      MuNavItem(id: 'programmes', label: l10n.programmes, icon: PhosphorIcons.barbell()),
      MuNavItem(id: 'eleves', label: l10n.eleves, icon: PhosphorIcons.users()),
      MuNavItem(id: 'retours', label: l10n.retours, icon: PhosphorIcons.chatCircleDots()),
    ],
  ),
  MuNavSection(
    heading: l10n.gestion,
    items: [
      MuNavItem(id: 'revenus', label: l10n.revenus, icon: PhosphorIcons.coins()),
      MuNavItem(id: 'abonnement', label: l10n.abonnement, icon: PhosphorIcons.crownSimple()),
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
            title: l10n.ajouteTonDiplomePourDevenir,
            detail: l10n.tesProgrammesSerontPubliesDes,
            action: MuAction(l10n.ajouter, () => context.go(Routes.coachCertification)),
          )
        : MuBanner(
            variant: MuBannerVariant.strip,
            tone: MuBannerTone.info,
            icon: PhosphorIcons.hourglassMedium(),
            title: l10n.diplomeEnVerificationReponseSous,
            detail: l10n.prepareTesProgrammesIlsSeront,
          );

    final programmes = ProCard(
      padding: const EdgeInsets.all(MuSpace.s8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MuEmptyState(
            illustration: MuEmptyIllustration.programs,
            title: l10n.creeTonPremierProgramme,
            description:
                l10n.desSemainesDeSeancesQue,
            actions: [
              MuButton.primary(
                label: l10n.creerMonPremierProgramme,
                leading: PhosphorIcons.plus(),
                size: MuButtonSize.l,
                onPressed: () => showComingSoon(context),
              ),
              MuButton.tertiary(
                label: l10n.voirUnExemple,
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
                (PhosphorIcons.calendarDots(), l10n.aSemaines),
                (PhosphorIcons.videoCamera(), l10n.videosEtExercices),
                (PhosphorIcons.coins(), l10n.tonPrixOuInclusDans),
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
          context: l10n.assistantProgramme,
          title: l10n.lIaPeutProposerUn,
          content: l10n.rienNEstPublieSans,
          reasonLead: l10n.baseSur,
          reason: focus.isEmpty ? l10n.taBio : l10n.taBioEtTesSpecialites(focus.join(', ')),
          primary: MuAction(l10n.proposerUnPlan, () => showComingSoon(context)),
          primaryIcon: PhosphorIcons.sparkle(),
          secondary: MuAction(l10n.plusTard, () {}),
          secondaryDismisses: true,
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
                      l10n.coach2(sport == null ? '' : ' ${sport.toLowerCase()}', d.district),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              MuButton.link(
                label: l10n.modifierMonProfil,
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
        role: l10n.coach,
        name: [?sport, d.district].join(' · '),
        initials: initialsOf(d.name),
        image: image,
      ),
      user: MuSidebarUser(name: d.name, email: d.email, image: image),
      userRole: l10n.coach,
      banner: banner,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.bienvenue(firstName), style: MuType.h1.copyWith(color: c.text)),
          ),
          const SizedBox(height: MuSpace.s1),
          Text(
            l10n.tonProfilCoachEstPret,
            style: MuType.bodyL.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: MuSpace.s6),
          ProSplit(start: programmes, end: side, narrowRatio: (13, 10)),
          const SizedBox(height: MuSpace.s6),
          ProCardRow(
            columns: width < ProSplit.stackBelow ? 2 : 4,
            children: [
              MuKpiCard(label: l10n.eleves, value: '0', note: l10n.tesElevesApparaitrontIci),
              MuKpiCard(
                label: l10n.inscriptionsActives,
                value: '0',
                note: l10n.desTonPremierProgrammePublie,
              ),
              MuKpiCard(
                label: l10n.revenusDuMois,
                value: '0',
                unit: 'DT',
                note: l10n.versesChaqueLundi,
              ),
              MuKpiCard(label: l10n.noteMoyenne, value: '—', note: l10n.apresLesPremiersRetours),
            ],
          ),
        ],
      ),
    );
  }

  // COA-03 source: 2 px between the profile lines.
  static const double _lineGap = 2;
}
