import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/coming_soon.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../games/widgets/game_widgets.dart';
import '../../home/controllers/home_providers.dart';
import '../data/profile_repository.dart';
import '../widgets/profile_widgets.dart';
import '../../../l10n/l10n.dart';

/// PRF-02 · Profil public: another player's profile — « Suivre », the AI fit with their games,
/// their next game, stats, levels, reliability, badges, matches, reviews; « Inviter à une partie ».
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.name});

  final String name;

  static const double _bottomRoom = MuSpace.s16 + MuSpace.s8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final profile = ref.watch(playerProfileProvider(name));
    return Scaffold(
      backgroundColor: c.bg,
      body: switch (profile) {
        AsyncData(:final value) => _body(context, ref, value),
        AsyncError() => Center(
          child: MuEmptyState(
            title: l10n.profilIntrouvable,
            actions: [MuButton.primary(label: l10n.retour, onPressed: () => context.pop())],
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
      bottomNavigationBar: profile.value == null
          ? null
          : StickyActionBar(
              children: [
                MuButton.primary(
                  label: l10n.inviterAUnePartie,
                  leading: PhosphorIcons.calendarPlus(),
                  size: MuButtonSize.xl,
                  fullWidth: true,
                  onPressed: () => context.push(Routes.bookingType),
                ),
              ],
            ),
    );
  }

  Future<void> _follow(BuildContext context, WidgetRef ref, PlayerProfile p) async {
    await ref.read(playerProfileRepositoryProvider).follow(p.name, follow: !p.followed);
    ref.invalidate(playerProfileProvider(name));
    if (context.mounted) {
      MuToast.show(context, title: p.followed ? l10n.tuNeSuisPlus(p.name) : l10n.tuSuis(p.name));
    }
  }

  Widget _body(BuildContext context, WidgetRef ref, PlayerProfile p) {
    final c = context.mu;
    final myLevels = ref.watch(meProvider).value?.levels ?? Story.myLevels;
    final next = Story.g1;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ProfileHeader(
          profile: p,
          onBack: () => context.pop(),
          actions: [
            MuBarAction(
              icon: PhosphorIcons.shareNetwork(),
              label: l10n.partagerLeProfil,
              onPressed: () =>
                  SharePlus.instance.share(ShareParams(text: 'https://matchup.tn/@${p.handle}')),
            ),
            MuBarAction(
              icon: PhosphorIcons.dotsThree(),
              label: l10n.plusDActions,
              onPressed: () => MuBottomSheet.show<void>(
                context,
                title: l10n.actionsSurLeProfilDe(p.name),
                height: MuSheetHeight.auto,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.prohibit(),
                      title: l10n.bloquer(p.name),
                      chevron: false,
                      onTap: () => showComingSoon(context),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.flag(),
                      title: l10n.signalerCeProfil,
                      destructive: true,
                      chevron: false,
                      onTap: () => showComingSoon(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
          action: p.followed
              ? MuButton.secondary(
                  label: l10n.suivi,
                  leading: PhosphorIcons.check(),
                  size: MuButtonSize.s,
                  onPressed: () => _follow(context, ref, p),
                )
              : MuButton.primary(
                  label: l10n.suivre,
                  leading: PhosphorIcons.userPlus(),
                  size: MuButtonSize.s,
                  onPressed: () => _follow(context, ref, p),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, _bottomRoom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileIdentity(
                profile: p,
                extraChips: [MuReliabilityBadge(score: p.reliability.score, size: MuBadgeSize.s)],
              ),
              if (p.fit != null) ...[
                const SizedBox(height: MuSpace.s5),
                Container(
                  padding: const EdgeInsets.all(MuSpace.s4),
                  decoration: BoxDecoration(color: c.aiSoft, borderRadius: MuRadius.mdAll),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          MuAiLabel(size: MuAiLabelSize.s, onAiSurface: true),
                          const SizedBox(width: MuSpace.s2),
                          Expanded(
                            child: Text(
                              l10n.sesPartiesTeCorrespondent,
                              style: MuType.h3.copyWith(color: c.text),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MuSpace.s3),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: MuMatchFitScore.pill(value: p.fit!, reason: p.fitReason),
                      ),
                      const SizedBox(height: MuSpace.s3),
                      Text(p.fitReason ?? '', style: MuType.body.copyWith(color: c.text)),
                      const SizedBox(height: MuSpace.s3),
                      MuCardSurface(
                        padding: const EdgeInsets.all(MuSpace.s3),
                        onTap: () => context.push(Routes.game(next.id!)),
                        semanticLabel:
                            l10n.voirSaProchainePartiePlaces(formatDateTime(next.start), next.venue, next.spotsLeft, formatDT(next.pricePerPlayer)),
                        child: Row(
                          children: [
                            MuSportIcon(next.sport, size: MuSize.iconM),
                            const SizedBox(width: MuSpace.s3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${formatDateTime(next.start)} · ${next.venue}',
                                    style: MuType.label.copyWith(color: c.text),
                                  ),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: l10n.ilOrganise),
                                        TextSpan(
                                          text: '${next.spotsLeft}',
                                          style: MuType.labelS.copyWith(color: c.text),
                                        ),
                                        TextSpan(text: l10n.places2),
                                        TextSpan(
                                          text: formatDT(next.pricePerPlayer),
                                          style: MuType.labelS.copyWith(color: c.text),
                                        ),
                                        const TextSpan(text: ' /pers.'),
                                      ],
                                    ),
                                    style: MuType.caption.copyWith(color: c.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              PhosphorIcons.caretRight(),
                              size: MuSize.iconS,
                              color: c.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      if (p.together != null) ...[
                        const SizedBox(height: MuSpace.s3),
                        Row(
                          children: [
                            const MuAvatarStack(
                              people: [Story.skander, Story.yassine],
                              size: MuAvatarSize.xs,
                            ),
                            const SizedBox(width: MuSpace.s2),
                            Expanded(
                              child: Text(
                                p.together!,
                                style: MuType.caption.copyWith(color: c.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: MuSpace.s5),
              ProfileStats(profile: p),
              const SizedBox(height: MuSpace.s6),
              Row(
                children: [
                  Semantics(
                    header: true,
                    child: Text(l10n.niveaux, style: MuType.h2.copyWith(color: c.text)),
                  ),
                  const SizedBox(width: MuSpace.s2),
                  MuAiLabel(size: MuAiLabelSize.s),
                ],
              ),
              for (final l in p.levels) ...[
                const SizedBox(height: MuSpace.s3),
                LevelCard(
                  level: l,
                  yours: myLevels[l.sport] == null
                      ? null
                      : (myLevels[l.sport]!, (l.level - myLevels[l.sport]!).abs()),
                ),
              ],
              if (p.otherSportNote != null) ...[
                const SizedBox(height: MuSpace.s3),
                MuCardSurface(
                  padding: const EdgeInsets.all(MuSpace.s3),
                  child: Row(
                    children: [
                      MuChip.sport(p.otherSportNote!.$1, size: MuChipSize.s),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MuLevelIndicator(level: p.otherSportNote!.$2),
                            Text(
                              p.otherSportNote!.$3,
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
              SectionHead(l10n.derniersMatchs),
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
