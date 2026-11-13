import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/forum_providers.dart';
import '../data/forum_repository.dart';
import '../widgets/forum_feed_list.dart';

/// FRM-01 · Communauté: « Pose ta question à la communauté », the 5 categories with their
/// « nouveaux depuis ta dernière visite » badges, sport chips, Tendance / Récents / Top with the
/// number of discussions, then the feed (pinned first, « X t’a mentionné » above a post).
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final query = ref.watch(forumQueryProvider);
    final feed = ref.watch(forumFeedProvider(query));

    Future<void> refresh() async {
      ref.invalidate(forumCategoriesProvider);
      ref.invalidate(forumFeedProvider(query));
      await ref.read(forumFeedProvider(query).future).catchError((_) => const ForumFeedState(total: 0, posts: []));
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MuTopAppBar.large(
            title: l10n.communaute,
            actions: [
              MuBarAction(
                icon: PhosphorIcons.magnifyingGlass(),
                label: l10n.forumRechercherDansLaCommunaute,
                onPressed: () => context.push(Routes.forumSearch),
              ),
              MuBarAction(
                icon: PhosphorIcons.bookmarkSimple(),
                label: l10n.forumMesPostsEtFavoris,
                onPressed: () => context.push(Routes.forumMine),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              color: c.primary,
              onRefresh: refresh,
              child: ForumFeedList(
                query: query,
                header: [
                  const Padding(padding: EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6), child: _Compose()),
                  const _Categories(),
                  const SizedBox(height: MuSpace.s6),
                  _SportChips(query: query),
                  const SizedBox(height: MuSpace.s3),
                  _SortRow(query: query, total: feed.value?.total),
                  const SizedBox(height: MuSpace.s3),
                ],
                empty: MuEmptyState(
                  title: l10n.forumAucuneDiscussion,
                  description: l10n.forumAucuneDiscussionDetail,
                  actions: [
                    MuButton.primary(
                      label: l10n.forumPoseTaQuestion,
                      leading: PhosphorIcons.notePencil(),
                      onPressed: () => context.push(Routes.forumNew),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// « Pose ta question à la communauté »: the reader's avatar, the prompt and a Volt pencil.
class _Compose extends ConsumerWidget {
  const _Compose();

  // FRM-01: the field is 56 high, the pencil disc 40.
  static const double _height = 56;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final me = ref.watch(forumMeProvider).value;
    return Semantics(
      button: true,
      label: l10n.forumEcrireUnNouveauPost,
      excludeSemantics: true,
      child: MuFocusRing(
        borderRadius: MuRadius.fullAll,
        child: MuPressScale(
          child: Material(
            color: c.surface,
            shape: StadiumBorder(side: BorderSide(color: c.border)),
            elevation: 0,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => context.push(Routes.forumNew),
              child: Container(
                height: _height,
                decoration: ShapeDecoration(shape: const StadiumBorder(), shadows: MuElevation.of(context).level1),
                padding: const EdgeInsetsDirectional.only(start: MuSpace.s3, end: MuSpace.s2),
                child: Row(
                  children: [
                    MuAvatar(name: me?.name ?? '', size: MuAvatarSize.m),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: Text(
                        l10n.forumPoseTaQuestionALaCommunaute,
                        style: MuType.body.copyWith(color: c.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: MuSize.controlM,
                      height: MuSize.controlM,
                      decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                      child: Icon(PhosphorIcons.notePencil(), size: MuSize.iconS, color: c.onAccent),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// « Catégories » with the 5 tiles; a tile filters the feed (tap again to clear).
class _Categories extends ConsumerWidget {
  const _Categories();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final counts = ref.watch(forumCategoriesProvider).value;
    final selected = ref.watch(forumQueryProvider).category;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Semantics(header: true, child: Text(l10n.forumCategories, style: MuType.h3)),
              ),
              Text(l10n.forumNouveauxDepuisTaDerniereVisite, style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: MuSpace.s3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, cat) in ForumCategory.values.indexed) ...[
                if (i > 0) const SizedBox(width: MuSpace.s2),
                Expanded(
                  child: _CategoryTile(
                    category: cat,
                    fresh: counts?.where((x) => x.category == cat).firstOrNull?.fresh ?? 0,
                    selected: selected == cat,
                    onTap: () => ref.read(forumQueryProvider.notifier).category(cat),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.fresh, required this.selected, required this.onTap});

  final ForumCategory category;
  final int fresh;
  final bool selected;
  final VoidCallback onTap;

  // FRM-01: icon disc 40, badge 18, name 11/14 on two lines.
  static const double _badge = 18;
  static const double _nameSize = 11;
  static const double _nameLine = 14 / 11;
  // Tightened a little so « Équipement » and « Discussions » fit the 65 px tile unbroken.
  static const double _nameTracking = -0.3;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final fg = selected ? c.onAccent : c.text;
    final icon = category.glyph != null
        ? SvgPicture.asset(
            category.glyph!,
            width: MuSize.iconS,
            height: MuSize.iconS,
            colorFilter: ColorFilter.mode(c.text, BlendMode.srcIn),
          )
        : Icon(category.icon, size: MuSize.iconS, color: c.text);
    return Semantics(
      button: true,
      selected: selected,
      label: fresh > 0 ? '${category.label}, ${l10n.forumNNouveaux(fresh)}' : category.label,
      excludeSemantics: true,
      child: MuFocusRing(
        borderRadius: MuRadius.mdAll,
        child: MuPressScale(
          child: Material(
            color: selected ? c.accent : c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: MuRadius.mdAll,
              side: BorderSide(color: selected ? c.accent : c.border),
            ),
            child: InkWell(
              borderRadius: MuRadius.mdAll,
              onTap: onTap,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, MuSpace.s3, 0, MuSpace.s2),
                    child: Column(
                      children: [
                        Container(
                          width: MuSize.controlM,
                          height: MuSize.controlM,
                          decoration: BoxDecoration(
                            color: c.surfaceMuted,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.border),
                          ),
                          alignment: Alignment.center,
                          child: icon,
                        ),
                        const SizedBox(height: MuSpace.s1 + MuSpace.s1 / 2),
                        Text(
                          category.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: MuType.labelS.copyWith(fontSize: _nameSize, height: _nameLine, letterSpacing: _nameTracking, color: fg),
                        ),
                      ],
                    ),
                  ),
                  if (fresh > 0)
                    PositionedDirectional(
                      top: MuSpace.s1 + MuSpace.s1 / 2,
                      end: MuSpace.s1 + MuSpace.s1 / 2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: _badge),
                        height: _badge,
                        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: selected ? c.onAccent : c.accent, borderRadius: MuRadius.fullAll),
                        child: Text('$fresh', style: MuType.numXs.copyWith(color: selected ? c.accent : c.onAccent)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// « Tous les sports » then the sport chips.
class _SportChips extends ConsumerWidget {
  const _SportChips({required this.query});

  final ForumQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(forumQueryProvider.notifier);
    return Semantics(
      container: true,
      label: l10n.forumFiltrerParSport,
      child: SizedBox(
        height: MuSize.touchTarget,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
          children: [
            Center(
              child: MuChip(
                kind: MuChipKind.choice,
                label: l10n.forumTousLesSports,
                selected: query.sport == null,
                onSelected: (_) => ctrl.sport(null),
              ),
            ),
            for (final s in MuSport.values) ...[
              const SizedBox(width: MuSpace.s2),
              Center(
                child: MuChip.sport(s, selected: query.sport == s, onSelected: (on) => ctrl.sport(on ? s : null)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tendance · Récents · Top and « 248 discussions ».
class _SortRow extends ConsumerWidget {
  const _SortRow({required this.query, required this.total});

  final ForumQuery query;
  final int? total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
      child: Row(
        children: [
          MuSegmentedControl<ForumSort>(
            semanticLabel: l10n.forumTrierLesDiscussions,
            size: MuSegmentedSize.s,
            segments: [for (final s in ForumSort.values) MuSegment(value: s, label: s.label)],
            value: query.sort,
            onChanged: (s) => ref.read(forumQueryProvider.notifier).sort(s),
          ),
          const Spacer(),
          if (total != null)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatInt(total!),
                    style: MuType.numXs.copyWith(color: c.text),
                  ),
                  TextSpan(text: ' ${l10n.forumDiscussions(total!)}'),
                ],
              ),
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
        ],
      ),
    );
  }
}
