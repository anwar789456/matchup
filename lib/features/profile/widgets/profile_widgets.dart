import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../../games/widgets/game_widgets.dart';
import '../data/profile_repository.dart';
import '../../../l10n/l10n.dart';

/// The cover (CourtArt photo) with the media bar over it and the 96 avatar overlapping its
/// bottom edge, then the action at the end (« Modifier le profil » / « Suivre »).
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onBack,
    required this.actions,
    required this.action,
  });

  final PlayerProfile profile;
  final VoidCallback onBack;
  final List<MuBarAction> actions;
  final Widget action;

  // PRF-01: cover 188, avatar XL overlapping by half.
  static const double _cover = 188;
  static const double _avatar = MuSize.avatarXl;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _cover,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MuCourtArt(
                sport: profile.coverSport,
                variant: MuCourtArtVariant.photo,
                semanticLabel: l10n.couvertureDuProfil,
              ),
              Align(
                alignment: Alignment.topCenter,
                child: MuTopAppBar.media(onBack: onBack, actions: actions),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
          child: SizedBox(
            height: _avatar / 2 + MuSpace.s2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                PositionedDirectional(
                  start: 0,
                  top: -_avatar / 2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
                    child: MuAvatar(name: profile.name, size: MuAvatarSize.xl),
                  ),
                ),
                PositionedDirectional(end: 0, top: MuSpace.s2, child: action),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Name, handle · zone, bio, the sport · position chips, then followers.
class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({super.key, required this.profile, this.extraChips = const []});

  final PlayerProfile profile;
  final List<Widget> extraChips;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(profile.name, style: MuType.h1.copyWith(color: c.text)),
        ),
        Text(
          '@${profile.handle} · ${profile.zone}',
          style: MuType.body.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: MuSpace.s3),
        Text(profile.bio, style: MuType.body.copyWith(color: c.text)),
        const SizedBox(height: MuSpace.s3),
        Wrap(
          spacing: MuSpace.s2,
          runSpacing: MuSpace.s2,
          children: [
            for (final s in profile.sports)
              if (profile.positions[s] != null)
                MuChip(
                  label: '${s.label} · ${profile.positions[s]}',
                  kind: MuChipKind.sport,
                  sport: s,
                  size: MuChipSize.s,
                )
              else
                MuChip.sport(s, size: MuChipSize.s),
            ...extraChips,
          ],
        ),
        const SizedBox(height: MuSpace.s3),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${profile.followers}',
                style: MuType.numS.copyWith(color: c.text),
              ),
              TextSpan(text: l10n.abonnes),
              TextSpan(
                text: '${profile.following}',
                style: MuType.numS.copyWith(color: c.text),
              ),
              const TextSpan(text: ' abonnements'),
            ],
          ),
          style: MuType.body.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}

/// The dark stats card: « DEPUIS OCT. 2025 », « 58 % de victoires », Matchs · Victoires · Tournois.
class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key, required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? c.text : c.textInverse;
    final muted = dark ? c.textSecondary : c.textInverse.withValues(alpha: 0.7);
    Widget cell(String value, String label) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: MuType.numXl.copyWith(color: ink)),
          Text(label, style: MuType.caption.copyWith(color: muted)),
        ],
      ),
    );
    return Semantics(
      label:
          l10n.statistiquesDepuisDeVictoiresMatchs(profile.since, profile.winRate, profile.matches, profile.wins, profile.tournaments),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(MuSpace.s4),
        decoration: BoxDecoration(
          color: dark ? c.night700 : c.surfaceInverse,
          borderRadius: MuRadius.mdAll,
          border: dark ? Border.all(color: c.border) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.depuis(profile.since.toUpperCase()),
                    style: MuType.overline.copyWith(color: muted),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: 2),
                  decoration: BoxDecoration(color: c.accent, borderRadius: MuRadius.fullAll),
                  child: Text(
                    l10n.deVictoires(profile.winRate),
                    style: MuType.labelS.copyWith(color: c.onAccent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MuSpace.s3),
            IntrinsicHeight(
              child: Row(
                children: [
                  cell('${profile.matches}', l10n.matchs),
                  VerticalDivider(width: MuSpace.s4, color: muted.withValues(alpha: 0.3)),
                  cell('${profile.wins}', l10n.victoires),
                  VerticalDivider(width: MuSpace.s4, color: muted.withValues(alpha: 0.3)),
                  cell('${profile.tournaments}', l10n.tournois),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One sport's level card: chip + « 18 matchs · côté gauche », the bar with trend and
/// confidence, the sparkline of the last 10 matches and « Pourquoi ce niveau ? ».
class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.level, this.onWhy, this.trailing, this.yours});

  final SportLevel level;
  final VoidCallback? onWhy;
  final Widget? trailing;

  /// PRF-02: « Ton niveau football 3,0 · écart 1,0 ».
  final (double, double)? yours;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final l = level;
    return MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MuChip.sport(l.sport, size: MuChipSize.s),
              const Spacer(),
              Text(
                l10n.matchs2(l.matches, l.position),
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          Text(
            l10n.niveau4(l.sport.label.toUpperCase()),
            style: MuType.overline.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: MuSpace.s1),
          MuLevelIndicator(
            level: l.level,
            variant: MuLevelVariant.bar,
            label: l10n.niveau2(l.sport.label),
            ai: true,
            showValue: true,
            trend: l.trend,
            trendLabel: l10n.surJours2,
            confidence: l.confidence,
            reason: l.reason,
          ),
          const SizedBox(height: MuSpace.s3),
          Divider(height: 1, thickness: 1, color: c.border),
          const SizedBox(height: MuSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.derniersMatchs2,
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: MuSpace.s1),
                  MuSparkline(
                    values: l.history,
                    color: l.sport.color(c),
                    area: true,
                    min: 1,
                    max: 7,
                    size: const Size(120, 40),
                    semanticLabel:
                        l10n.niveauSurLesDerniersMatchs(l.sport.label, formatLevel(l.history.first), formatLevel(l.history.last)),
                  ),
                ],
              ),
              const Spacer(),
              if (trailing != null)
                trailing!
              else if (yours != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.tonNiveau2(l.sport.label.toLowerCase()),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: formatLevel(yours!.$1),
                            style: MuType.numS.copyWith(color: c.text),
                          ),
                          TextSpan(text: l10n.ecart),
                          TextSpan(
                            text: formatLevel(yours!.$2),
                            style: MuType.numS.copyWith(color: c.text),
                          ),
                        ],
                      ),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                )
              else if (onWhy != null)
                MuButton.tertiary(
                  label: l10n.pourquoiCeNiveau,
                  leading: PhosphorIcons.info(),
                  size: MuButtonSize.s,
                  onPressed: onWhy,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReliabilityCard extends StatelessWidget {
  const ReliabilityCard({super.key, required this.reliability});

  final Reliability reliability;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = reliability;
    return MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MuReliabilityBadge(score: r.score),
              const Spacer(),
              Text(l10n.derniersMois, style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          MuProgressBar(
            value: r.honored.toDouble(),
            max: r.total.toDouble(),
            size: MuProgressSize.s,
            tone: MuTone.success,
            showValue: false,
          ),
          const SizedBox(height: MuSpace.s2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${r.honored}/${r.total}',
                  style: MuType.numS.copyWith(color: c.text),
                ),
                TextSpan(text: l10n.matchsHonores),
              ],
            ),
            style: MuType.body.copyWith(color: c.text),
          ),
          const SizedBox(height: MuSpace.s2),
          Text(r.note, style: MuType.caption.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}

class BadgesRow extends StatelessWidget {
  const BadgesRow({super.key, required this.badges});

  final List<ProfileBadge> badges;

  // prf-badge: padding 14 6 12, radius-md; the 48 Volt disc.
  static const double _disc = 48;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      children: [
        for (final (i, b) in badges.indexed) ...[
          if (i > 0) const SizedBox(width: MuSpace.s2),
          Expanded(
            child: Semantics(
              label: l10n.badge(b.name, b.detail, b.progress == null ? '' : l10n.enCours),
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: MuRadius.mdAll,
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: _disc,
                      height: _disc,
                      child: b.progress == null
                          ? Container(
                              decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                              child: Icon(b.icon, size: MuSize.iconM, color: c.onAccent),
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: b.progress,
                                  strokeWidth: 4,
                                  color: c.primary,
                                  backgroundColor: c.border,
                                ),
                                Icon(b.icon, size: MuSize.iconM, color: c.text),
                              ],
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      b.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.labelS.copyWith(color: c.text),
                    ),
                    Text(
                      b.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class RecentMatches extends StatelessWidget {
  const RecentMatches({super.key, required this.matches});

  final List<ProfileMatch> matches;

  // prf-res: a 28 result square.
  static const double _res = 28;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return MuCardSurface(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, m) in matches.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
              decoration: i == 0
                  ? null
                  : BoxDecoration(
                      border: Border(top: BorderSide(color: c.border)),
                    ),
              child: Row(
                children: [
                  Container(
                    width: _res,
                    height: _res,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: switch (m.outcome) {
                        MatchOutcome.win => c.accent,
                        MatchOutcome.loss => c.surfaceMuted,
                        MatchOutcome.friendly => c.surfaceMuted,
                      },
                      borderRadius: MuRadius.smAll,
                    ),
                    child: Text(
                      switch (m.outcome) {
                        MatchOutcome.win => 'V',
                        MatchOutcome.loss => 'D',
                        MatchOutcome.friendly => '–',
                      },
                      style: MuType.labelS.copyWith(
                        color: m.outcome == MatchOutcome.win ? c.onAccent : c.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.title, style: MuType.label.copyWith(color: c.text)),
                        Text(m.meta, style: MuType.caption.copyWith(color: c.textSecondary)),
                      ],
                    ),
                  ),
                  if (m.delta != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          m.delta == 0 ? '0,0' : '+${formatLevel(m.delta!)}',
                          style: MuType.numS.copyWith(
                            color: m.delta! > 0 ? c.successText : c.textSecondary,
                          ),
                        ),
                        Text('niveau', style: MuType.caption.copyWith(color: c.textSecondary)),
                      ],
                    )
                  else
                    Icon(PhosphorIcons.caretRight(), size: MuSize.iconXs, color: c.textSecondary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ReviewsCard extends StatelessWidget {
  const ReviewsCard({super.key, required this.reviews});

  final ReviewSummary reviews;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = reviews;
    return MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatLevel(r.average), style: MuType.numXl.copyWith(color: c.text)),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MuStarRating.display(value: r.average, showValue: false),
                    Text(
                      l10n.avis2(r.count, r.note),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            children: [
              for (final (label, n) in r.tags) MuChip(label: label, count: n, size: MuChipSize.s),
            ],
          ),
          for (final review in r.latest) ...[
            const SizedBox(height: MuSpace.s4),
            Divider(height: 1, thickness: 1, color: c.border),
            const SizedBox(height: MuSpace.s3),
            Row(
              children: [
                MuAvatar(name: review.author.name, size: MuAvatarSize.s),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.author.name, style: MuType.label.copyWith(color: c.text)),
                      Text(review.meta, style: MuType.caption.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                Icon(
                  PhosphorIcons.star(PhosphorIconsStyle.fill),
                  size: MuSize.iconXs,
                  color: c.warning,
                ),
                const SizedBox(width: MuSpace.s1),
                Text(formatLevel(review.rating), style: MuType.numS.copyWith(color: c.text)),
              ],
            ),
            const SizedBox(height: MuSpace.s2),
            Text(review.text, style: MuType.body.copyWith(color: c.text)),
          ],
        ],
      ),
    );
  }
}

/// « Badges · Voir les 12 » section heads with a text action.
class SeeAllHead extends StatelessWidget {
  const SeeAllHead(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => SectionHead(
    title,
    trailing: action == null
        ? null
        : MuButton.tertiary(
            label: action!,
            size: MuButtonSize.s,
            onPressed: onAction ?? () => showComingSoon(context),
          ),
  );
}
