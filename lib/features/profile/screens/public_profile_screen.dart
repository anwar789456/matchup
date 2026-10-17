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
            title: 'Profil introuvable',
            actions: [MuButton.primary(label: 'Retour', onPressed: () => context.pop())],
          ),
        ),
        _ => const MuSkeletonGroup(
          label: 'Chargement du profil',
          child: Column(
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
                  label: 'Inviter à une partie',
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
      MuToast.show(context, title: p.followed ? 'Tu ne suis plus ${p.name}' : 'Tu suis ${p.name}');
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
              label: 'Partager le profil',
              onPressed: () =>
                  SharePlus.instance.share(ShareParams(text: 'https://matchup.tn/@${p.handle}')),
            ),
            MuBarAction(
              icon: PhosphorIcons.dotsThree(),
              label: 'Plus d’actions',
              onPressed: () => MuBottomSheet.show<void>(
                context,
                title: 'Actions sur le profil de ${p.name}',
                height: MuSheetHeight.auto,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MuSettingsRow(
                      icon: PhosphorIcons.prohibit(),
                      title: 'Bloquer ${p.name}',
                      chevron: false,
                      onTap: () => showComingSoon(context),
                    ),
                    MuSettingsRow(
                      icon: PhosphorIcons.flag(),
                      title: 'Signaler ce profil',
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
                  label: 'Suivi',
                  leading: PhosphorIcons.check(),
                  size: MuButtonSize.s,
                  onPressed: () => _follow(context, ref, p),
                )
              : MuButton.primary(
                  label: 'Suivre',
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
                          const MuAiLabel(size: MuAiLabelSize.s, onAiSurface: true),
                          const SizedBox(width: MuSpace.s2),
                          Expanded(
                            child: Text(
                              'Ses parties te correspondent',
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
                            'Voir sa prochaine partie : ${formatDateTime(next.start)}, '
                            '${next.venue}, ${next.spotsLeft} places, '
                            '${formatDT(next.pricePerPlayer)} par personne',
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
                                        const TextSpan(text: 'Il organise · '),
                                        TextSpan(
                                          text: '${next.spotsLeft}',
                                          style: MuType.labelS.copyWith(color: c.text),
                                        ),
                                        const TextSpan(text: ' places · '),
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
                    child: Text('Niveaux', style: MuType.h2.copyWith(color: c.text)),
                  ),
                  const SizedBox(width: MuSpace.s2),
                  const MuAiLabel(size: MuAiLabelSize.s),
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
              const SectionHead('Fiabilité'),
              const SizedBox(height: MuSpace.s3),
              ReliabilityCard(reliability: p.reliability),
              const SizedBox(height: MuSpace.s6),
              SeeAllHead('Badges', action: 'Voir les ${p.badgeCount}'),
              const SizedBox(height: MuSpace.s3),
              BadgesRow(badges: p.badges),
              const SizedBox(height: MuSpace.s6),
              const SectionHead('Derniers matchs'),
              const SizedBox(height: MuSpace.s3),
              RecentMatches(matches: p.recentMatches),
              const SizedBox(height: MuSpace.s6),
              SeeAllHead('Avis des coéquipiers', action: 'Voir les ${p.reviews.count}'),
              const SizedBox(height: MuSpace.s3),
              ReviewsCard(reviews: p.reviews),
            ],
          ),
        ),
      ],
    );
  }
}
