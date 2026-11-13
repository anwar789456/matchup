import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../theme/theme.dart';
import 'mu_avatar.dart';
import 'mu_chip.dart';
import 'mu_icon_button.dart';
import 'mu_skeleton.dart';
import 'mu_sport_icon.dart';
import 'mu_status_badge.dart';
import 'src/card_surface.dart';

enum MuCardVariant { regular, compact }

/// How moderation shows on the card (ForumPostCard.md « Variants »).
enum MuModeration { none, hidden, reported }

/// What a [MuForumPostCard] shows. Built by the forum feature from its post.
@immutable
class MuForumPostData {
  const MuForumPostData({
    required this.category,
    required this.title,
    required this.authorName,
    required this.time,
    this.categoryIcon,
    this.categoryGlyph,
    this.sport,
    this.excerpt,
    this.tags = const [],
    this.authorLevel,
    this.authorImage,
    this.votes = 0,
    this.replies = 0,
    this.bestAnswer = false,
    this.pinned = false,
  });

  /// « Conseils & technique ».
  final String category;

  /// Phosphor icon of the category, or [categoryGlyph] for the custom ones (Terrains, Tournois).
  final IconData? categoryIcon;
  final String? categoryGlyph;
  final MuSport? sport;
  final String title;
  final String? excerpt;

  /// Already formatted: « #bandeja ».
  final List<String> tags;
  final String authorName;
  final double? authorLevel;
  final String? authorImage;

  /// « il y a 2 h », « hier ».
  final String time;
  final int votes;
  final int replies;
  final bool bestAnswer;
  final bool pinned;
}

/// ForumPostCard (components/ForumPostCard.md): a thread in the Communauté feed — category
/// eyebrow, sport chip, title, two-line excerpt, tags, author with level, vote capsule and
/// replies. `compact` for « Discussions similaires » and search; `hidden` collapses a moderated
/// post; `reported` adds the « Tu as signalé ce message » strip. [header] goes under the title
/// (a listing's price), [media] edge to edge between the text and the author (photos, videos).
class MuForumPostCard extends StatelessWidget {
  const MuForumPostCard({
    super.key,
    required this.post,
    this.vote = 0,
    this.onVote,
    this.moderation = MuModeration.none,
    this.variant = MuCardVariant.regular,
    this.onTap,
    this.onMore,
    this.onUndoReport,
    this.header,
    this.media,
  }) : _skeleton = false;

  /// The loading shape (top row, title, two excerpt lines, footer).
  const MuForumPostCard.skeleton({super.key, this.variant = MuCardVariant.regular})
    : post = const MuForumPostData(category: '', title: '', authorName: '', time: ''),
      vote = 0,
      onVote = null,
      moderation = MuModeration.none,
      onTap = null,
      onMore = null,
      onUndoReport = null,
      header = null,
      media = null,
      _skeleton = true;

  final MuForumPostData post;

  /// 1, −1 or 0 (the reader's vote).
  final int vote;

  /// Called with the new vote (tap the chosen arrow again to remove: 0).
  final ValueChanged<int>? onVote;
  final MuModeration moderation;
  final MuCardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onMore;
  final VoidCallback? onUndoReport;

  /// Under the title: what the post adds (a listing's price and condition).
  final Widget? header;

  /// Full width, between the text and the author: the post's photos and videos.
  final Widget? media;
  final bool _skeleton;

  // ForumPostCard.md: category icon 16, compact category circle 40.
  static const double _compactCircle = 40;

  @override
  Widget build(BuildContext context) {
    if (_skeleton) return _Skeleton(compact: variant == MuCardVariant.compact);
    if (moderation == MuModeration.hidden) return const _Hidden();
    if (variant == MuCardVariant.compact) return _compact(context);

    final c = context.mu;
    final secondary = MuType.caption.copyWith(color: c.textSecondary);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _CategoryIcon(icon: post.categoryIcon, glyph: post.categoryGlyph, size: MuSize.iconXs, color: c.textSecondary),
            const SizedBox(width: MuSpace.s2),
            // The eyebrow takes what the chip leaves; only it shortens on narrow cards.
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      post.category.toUpperCase(),
                      style: MuType.overline.copyWith(color: c.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (post.sport != null) ...[const SizedBox(width: MuSpace.s2), MuChip.sport(post.sport!, size: MuChipSize.s)],
                ],
              ),
            ),
            if (post.pinned)
              Semantics(
                label: l10n.forumEpingle,
                child: Icon(PhosphorIcons.pushPin(PhosphorIconsStyle.fill), size: MuSize.iconXs, color: c.text),
              ),
            if (onMore != null)
              MuIconButton(icon: PhosphorIcons.dotsThree(), label: l10n.plusDOptions, size: MuIconButtonSize.s, onPressed: onMore),
          ],
        ),
        const SizedBox(height: MuSpace.s2),
        Text(post.title, style: MuType.labelL, maxLines: 2, overflow: TextOverflow.ellipsis),
        if (header != null) ...[const SizedBox(height: MuSpace.s2), header!],
        if (post.excerpt != null && post.excerpt!.isNotEmpty) ...[
          const SizedBox(height: MuSpace.s1),
          Text(
            post.excerpt!,
            style: MuType.body.copyWith(color: c.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (post.tags.isNotEmpty || post.bestAnswer) ...[
          const SizedBox(height: MuSpace.s3),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: MuSpace.s3,
                  runSpacing: MuSpace.s1,
                  children: [for (final t in post.tags) Text(t, style: MuType.labelS.copyWith(color: c.textSecondary))],
                ),
              ),
              if (post.bestAnswer) MuStatusBadge(status: MuStatus.confirmed, label: l10n.forumMeilleureReponse, size: MuBadgeSize.s),
            ],
          ),
        ],
      ],
    );
    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (media == null) ...[
          Divider(height: 1, thickness: 1, color: c.border),
          const SizedBox(height: MuSpace.s3),
        ],
        Row(
          children: [
            MuAvatar(name: post.authorName, imageUrl: post.authorImage, level: post.authorLevel),
            const SizedBox(width: MuSpace.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.authorName, style: MuType.labelS, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(post.time, style: secondary, maxLines: 1),
                ],
              ),
            ),
            MuVoteCapsule(score: post.votes, vote: vote, onVote: onVote),
            const SizedBox(width: MuSpace.s3),
            _Replies(count: post.replies),
          ],
        ),
      ],
    );

    final card = MuCardSurface(
      onTap: onTap,
      semanticLabel: post.title,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            // The « Plus d’options » target is 44 high: less room above and at the end, so the
            // top row sits where the design has it.
            padding: EdgeInsets.fromLTRB(MuSpace.s4, onMore != null ? MuSpace.s1 : MuSpace.s4, MuSpace.s4, MuSpace.s3),
            child: body,
          ),
          ?media,
          Padding(
            padding: EdgeInsets.fromLTRB(MuSpace.s4, media == null ? 0 : MuSpace.s3, MuSpace.s4, MuSpace.s4),
            child: footer,
          ),
          if (moderation == MuModeration.reported) _ReportedStrip(onUndo: onUndoReport),
        ],
      ),
    );
    return card;
  }

  Widget _compact(BuildContext context) {
    final c = context.mu;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    return MuCardSurface(
      onTap: onTap,
      semanticLabel: post.title,
      padding: const EdgeInsets.all(MuSpace.s3),
      child: Row(
        children: [
          Container(
            width: _compactCircle,
            height: _compactCircle,
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              shape: BoxShape.circle,
              border: Border.all(color: c.border),
            ),
            alignment: Alignment.center,
            child: _CategoryIcon(icon: post.categoryIcon, glyph: post.categoryGlyph, size: MuSize.iconS, color: c.text),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, style: MuType.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: MuSpace.s1),
                Row(
                  children: [
                    if (post.sport != null) ...[MuSportIcon(post.sport!, size: MuSize.iconXs), const SizedBox(width: MuSpace.s1)],
                    if (post.pinned) ...[
                      Icon(PhosphorIcons.pushPin(PhosphorIconsStyle.fill), size: MuSize.iconXs, color: c.textSecondary),
                      const SizedBox(width: MuSpace.s1),
                    ],
                    Flexible(
                      child: Text(
                        [if (post.sport != null) post.sport!.label, post.authorName, post.time].join(' · '),
                        style: caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: MuSpace.s2),
          Semantics(
            label: '${l10n.forumNVotes(post.votes)}, ${l10n.forumNReponses(post.replies)}',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Count(icon: PhosphorIcons.arrowFatUp(), value: post.votes),
                const SizedBox(height: MuSpace.s1),
                _Count(icon: PhosphorIcons.chatCircle(), value: post.replies),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The vote capsule (ForumPostCard.md): up · score · down on `surface-muted` with a `border`
/// ring. The chosen arrow is a Volt disc with the fill icon; tap it again to remove the vote.
class MuVoteCapsule extends StatelessWidget {
  const MuVoteCapsule({super.key, required this.score, required this.vote, this.onVote});

  final int score;
  final int vote;
  final ValueChanged<int>? onVote;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      decoration: ShapeDecoration(
        color: c.surfaceMuted,
        shape: StadiumBorder(side: BorderSide(color: c.border)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MuIconButton(
            icon: PhosphorIcons.arrowFatUp(),
            selectedIcon: PhosphorIcons.arrowFatUp(PhosphorIconsStyle.fill),
            label: l10n.forumVoterPour,
            size: MuIconButtonSize.s,
            pressed: vote == 1,
            onPressed: onVote == null ? null : () => onVote!(vote == 1 ? 0 : 1),
          ),
          Semantics(
            liveRegion: true,
            label: l10n.forumNVotes(score),
            excludeSemantics: true,
            child: AnimatedSwitcher(
              duration: MuMotion.durationOf(context, MuMotion.fast),
              transitionBuilder: (child, a) => FadeTransition(opacity: a, child: child),
              child: Directionality(
                key: ValueKey(score),
                textDirection: TextDirection.ltr,
                child: Text(formatScore(score), style: MuType.numS),
              ),
            ),
          ),
          MuIconButton(
            icon: PhosphorIcons.arrowFatDown(),
            selectedIcon: PhosphorIcons.arrowFatDown(PhosphorIconsStyle.fill),
            label: l10n.forumVoterContre,
            size: MuIconButtonSize.s,
            pressed: vote == -1,
            onPressed: onVote == null ? null : () => onVote!(vote == -1 ? 0 : -1),
          ),
        ],
      ),
    );
  }

  /// « −3 » with a real minus sign.
  static String formatScore(int score) => score < 0 ? '−${-score}' : '$score';
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({this.icon, this.glyph, required this.size, required this.color});

  final IconData? icon;
  final String? glyph;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => glyph != null
      ? SvgPicture.asset(
          glyph!,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          excludeFromSemantics: true,
        )
      : Icon(icon ?? PhosphorIcons.chatsCircle(), size: size, color: color);
}

class _Replies extends StatelessWidget {
  const _Replies({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      label: l10n.forumNReponses(count),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.chatCircle(), size: MuSize.iconXs, color: c.textSecondary),
          const SizedBox(width: MuSpace.s1),
          Text('$count', style: MuType.numXs.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: MuSize.iconXs, color: c.textSecondary),
        const SizedBox(width: MuSpace.s1),
        Text(MuVoteCapsule.formatScore(value), style: MuType.numXs.copyWith(color: c.textSecondary)),
      ],
    );
  }
}

/// « Masqué par la modération · en cours de vérification »: no text, no votes, no menu.
class _Hidden extends StatelessWidget {
  const _Hidden();

  @override
  Widget build(BuildContext context) => MuHiddenNotice(title: l10n.forumMasqueParLaModeration);
}

/// The dashed `border-strong` well on `surface-muted` with the eye-slash circle, used for hidden
/// posts and replies. [description] and [action] add the author's view (« seul toi vois ce
/// message », « Pourquoi ? »).
class MuHiddenNotice extends StatelessWidget {
  const MuHiddenNotice({super.key, required this.title, this.description, this.action});

  final String title;
  final String? description;
  final Widget? action;

  static const double _circle = 32;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      container: true,
      label: l10n.forumMessageMasque,
      child: CustomPaint(
        painter: _DashedRRect(color: c.borderStrong, radius: MuRadius.md),
        child: Container(
          decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
          padding: const EdgeInsets.all(MuSpace.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: _circle,
                height: _circle,
                decoration: BoxDecoration(
                  color: c.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.border),
                ),
                alignment: Alignment.center,
                child: Icon(PhosphorIcons.eyeSlash(), size: MuSize.iconXs, color: c.textSecondary),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: MuType.label),
                    if (description != null) ...[
                      const SizedBox(height: MuSpace.s1),
                      Text(description!, style: MuType.caption.copyWith(color: c.textSecondary)),
                    ],
                    if (action != null) ...[const SizedBox(height: MuSpace.s2), action!],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRRect extends CustomPainter {
  _DashedRRect({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.5));
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRect old) => old.color != color || old.radius != radius;
}

/// « Tu as signalé ce message. La modération va le vérifier. » + « Annuler ».
class _ReportedStrip extends StatelessWidget {
  const _ReportedStrip({this.onUndo});

  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      liveRegion: true,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(MuRadius.md)),
        child: ColoredBox(
          color: c.warningSoft,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s4, MuSpace.s2, MuSpace.s2, MuSpace.s2),
            child: Row(
              children: [
                Icon(PhosphorIcons.flag(), size: MuSize.iconXs, color: c.warningText),
                const SizedBox(width: MuSpace.s2),
                Expanded(
                  child: Text(l10n.forumTuAsSignale, style: MuType.caption.copyWith(color: c.text)),
                ),
                if (onUndo != null)
                  TextButton(
                    onPressed: onUndo,
                    style: TextButton.styleFrom(minimumSize: const Size(MuSize.touchTarget, MuSize.touchTarget)),
                    child: Text(
                      l10n.annuler,
                      style: MuType.labelS.copyWith(color: c.link, decoration: TextDecoration.underline, decorationColor: c.link),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.compact});

  final bool compact;

  // The top row (eyebrow + chip) and the vote capsule, as wide as their content.
  static const double _eyebrow = 140;
  static const double _capsule = 96;

  @override
  Widget build(BuildContext context) => MuCardSurface(
    padding: EdgeInsets.all(compact ? MuSpace.s3 : MuSpace.s4),
    child: compact
        ? const Row(
            children: [
              MuSkeleton.circle(size: MuForumPostCard._compactCircle),
              SizedBox(width: MuSpace.s3),
              Expanded(child: MuSkeleton.text(lines: 2)),
            ],
          )
        : const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MuSkeleton.pill(width: _eyebrow, height: MuSpace.s4),
              SizedBox(height: MuSpace.s3),
              MuSkeleton.text(lines: 1),
              SizedBox(height: MuSpace.s3),
              MuSkeleton.text(lines: 2),
              SizedBox(height: MuSpace.s4),
              Row(
                children: [
                  MuSkeleton.circle(size: MuSize.avatarM),
                  SizedBox(width: MuSpace.s2),
                  Expanded(child: MuSkeleton.text(lines: 2)),
                  SizedBox(width: MuSpace.s8),
                  MuSkeleton.pill(width: _capsule),
                ],
              ),
            ],
          ),
  );
}
