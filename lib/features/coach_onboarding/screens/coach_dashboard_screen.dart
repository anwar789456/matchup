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
import '../controllers/coach_controller.dart';
import '../data/coach_draft.dart';
import '../../../l10n/l10n.dart';

/// COA-03 — the coach dashboard before the first programme, as a phone page: the diploma check
/// under the bar, then stacked the empty programmes card, the AI plan suggestion, the profile and
/// the four KPIs two by two.
class CoachDashboardScreen extends ConsumerWidget {
  const CoachDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final d = ref.watch(coachProvider).requireValue;
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
      // The empty state brings its own side padding.
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s4),
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
                size: MuButtonSize.m,
                onPressed: () => showComingSoon(context),
              ),
              MuButton.tertiary(
                label: l10n.voirUnExemple,
                leading: PhosphorIcons.playCircle(),
                size: MuButtonSize.m,
                onPressed: () => showComingSoon(context),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: Wrap(
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
          ),
        ],
      ),
    );

    final ai = MuAiSuggestionCard(
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
    );

    final profile = ProCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: MuSpace.s2),
                MuButton.link(
                  label: l10n.modifierMonProfil,
                  onPressed: () => context.go(Routes.coachProfile),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return ProDashboardScaffold(
      space: ProSpace.coach,
      userName: d.name,
      userRole: l10n.coach,
      userEmail: d.email,
      userImage: image,
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
          const SizedBox(height: MuSpace.s5),
          programmes,
          const SizedBox(height: MuSpace.s4),
          ai,
          const SizedBox(height: MuSpace.s4),
          profile,
          const SizedBox(height: MuSpace.s4),
          ProCardRow(
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
