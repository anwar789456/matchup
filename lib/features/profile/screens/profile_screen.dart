import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../player_onboarding/controllers/onboarding_controller.dart';
import '../../states/widgets/state_widgets.dart';
import '../../games/widgets/game_widgets.dart';
import '../data/profile_repository.dart';
import '../widgets/profile_widgets.dart';
import '../widgets/why_level_sheet.dart';
import '../../../l10n/l10n.dart';

/// PRF-01 · Mon profil: cover and avatar, identity, stats, the AI levels per sport, reliability,
/// badges, the last matches and teammates' reviews.
class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  static const double _bottomRoom = MuSpace.s8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final profile = ref.watch(myProfileProvider);
    return Scaffold(
      backgroundColor: c.bg,
      body: switch (profile) {
        AsyncData(:final value) => _body(context, ref, value),
        AsyncError() => Center(
          child: MuEmptyState(
            title: l10n.profilIndisponible,
            actions: [
              MuButton.secondary(
                label: l10n.reessayer,
                onPressed: () => ref.invalidate(myProfileProvider),
              ),
            ],
          ),
        ),
        _ => MuSkeletonGroup(
          label: l10n.chargementDuProfil,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MuSkeleton(height: 188, radius: BorderRadius.zero),
              Padding(padding: EdgeInsets.all(MuSpace.s4), child: MuSkeleton.text(lines: 5)),
            ],
          ),
        ),
      },
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, PlayerProfile p) {
    final c = context.mu;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ProfileHeader(
          profile: p,
          onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
          actions: [
            MuBarAction(
              icon: PhosphorIcons.shareNetwork(),
              label: l10n.partagerMonProfil,
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: l10n.monProfilMatchupHttpsMatchup(p.handle)),
              ),
            ),
            MuBarAction(
              icon: PhosphorIcons.gearSix(),
              label: l10n.parametres,
              onPressed: () => context.push(Routes.settings),
            ),
          ],
          action: MuButton.secondary(
            label: l10n.modifierLeProfil,
            leading: PhosphorIcons.pencilSimple(),
            size: MuButtonSize.s,
            onPressed: () => context.push(Routes.profileEdit),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, _bottomRoom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileIdentity(profile: p),
              // STA-08: what is missing from the profile, until « Plus tard ».
              if (!ref.watch(_completionHiddenProvider))
                Builder(
                  builder: (context) {
                    final items = [
                      (l10n.sportsEtNiveaux, p.sports.isNotEmpty),
                      (l10n.photoDeProfil, ref.watch(profilePhotoProvider) != null),
                      (l10n.zonesDeJeu, p.zone.isNotEmpty),
                      (l10n.bioLignes, p.bio.trim().isNotEmpty),
                    ];
                    final done = items.where((i) => i.$2).length;
                    // 40 % for the account, then 15 % per item (70 % with sports and zones).
                    final percent = 40 + done * 15;
                    if (percent >= 100) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: MuSpace.s4),
                      child: ProfileCompletionCard(
                        percent: percent,
                        items: items,
                        onComplete: () => context.push(Routes.profileEdit),
                        onLater: () => ref.read(_completionHiddenProvider.notifier).hide(),
                      ),
                    );
                  },
                ),
              const SizedBox(height: MuSpace.s5),
              ProfileStats(profile: p),
              const SizedBox(height: MuSpace.s6),
              Row(
                children: [
                  Semantics(
                    header: true,
                    child: Text(l10n.mesNiveaux, style: MuType.h2.copyWith(color: c.text)),
                  ),
                  const SizedBox(width: MuSpace.s2),
                  MuAiLabel(size: MuAiLabelSize.s),
                ],
              ),
              const SizedBox(height: MuSpace.s1),
              Text(
                l10n.estimesParLIaApres,
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
              for (final l in p.levels) ...[
                const SizedBox(height: MuSpace.s3),
                LevelCard(level: l, onWhy: () => showWhyLevelSheet(context, ref, p, l)),
              ],
              const SizedBox(height: MuSpace.s6),
              SectionHead(l10n.fiabilite),
              const SizedBox(height: MuSpace.s3),
              ReliabilityCard(reliability: p.reliability),
              const SizedBox(height: MuSpace.s6),
              SeeAllHead(l10n.badges, action: l10n.voirLes(p.badgeCount)),
              const SizedBox(height: MuSpace.s3),
              BadgesRow(badges: p.badges),
              const SizedBox(height: MuSpace.s6),
              SeeAllHead(
                l10n.derniersMatchs,
                action: l10n.voirTout,
                onAction: () => context.go(Routes.matches),
              ),
              const SizedBox(height: MuSpace.s3),
              RecentMatches(matches: p.recentMatches),
              const SizedBox(height: MuSpace.s6),
              SeeAllHead(l10n.avisDesCoequipiers, action: l10n.voirLes(p.reviews.count)),
              const SizedBox(height: MuSpace.s3),
              ReviewsCard(reviews: p.reviews),
            ],
          ),
        ),
      ],
    );
  }
}

/// « Plus tard » on the STA-08 card hides it for this session.
class _CompletionHidden extends Notifier<bool> {
  @override
  bool build() => false;

  void hide() => state = true;
}

final _completionHiddenProvider = NotifierProvider<_CompletionHidden, bool>(_CompletionHidden.new);
