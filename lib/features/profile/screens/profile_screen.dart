import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../games/widgets/game_widgets.dart';
import '../data/profile_repository.dart';
import '../widgets/profile_widgets.dart';
import '../widgets/why_level_sheet.dart';

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
            title: 'Profil indisponible',
            actions: [
              MuButton.secondary(
                label: 'Réessayer',
                onPressed: () => ref.invalidate(myProfileProvider),
              ),
            ],
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
              label: 'Partager mon profil',
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: 'Mon profil MatchUp : https://matchup.tn/@${p.handle}'),
              ),
            ),
            MuBarAction(
              icon: PhosphorIcons.gearSix(),
              label: 'Paramètres',
              onPressed: () => context.push(Routes.settings),
            ),
          ],
          action: MuButton.secondary(
            label: 'Modifier le profil',
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
              const SizedBox(height: MuSpace.s5),
              ProfileStats(profile: p),
              const SizedBox(height: MuSpace.s6),
              Row(
                children: [
                  Semantics(
                    header: true,
                    child: Text('Mes niveaux', style: MuType.h2.copyWith(color: c.text)),
                  ),
                  const SizedBox(width: MuSpace.s2),
                  const MuAiLabel(size: MuAiLabelSize.s),
                ],
              ),
              const SizedBox(height: MuSpace.s1),
              Text(
                'Estimés par l’IA après chaque match. Tu peux les ajuster ou les contester.',
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
              for (final l in p.levels) ...[
                const SizedBox(height: MuSpace.s3),
                LevelCard(level: l, onWhy: () => showWhyLevelSheet(context, ref, p, l)),
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
              SeeAllHead(
                'Derniers matchs',
                action: 'Voir tout',
                onAction: () => context.go(Routes.matches),
              ),
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
