import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../../l10n/l10n.dart';

/// A section head of the game and booking pages: `h2` and, at the end, a count or an action.
class SectionHead extends StatelessWidget {
  const SectionHead(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  // gam-sec head: min 32 high.
  static const double _minHeight = 32;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: MuType.h2.copyWith(color: c.text)),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// One cell of the facts card: an overline, a big value, a caption.
@immutable
class FactCell {
  const FactCell(this.label, this.value, {this.caption, this.captionWidget, this.valueUnit});

  final String label;
  final String value;
  final String? caption;
  final Widget? captionWidget;

  /// A small unit after the value (« 15 DT »).
  final String? valueUnit;
}

/// The three-column facts card (GAM-01 « dim. 18 oct. · Ta part · Places », MAT-05 « Mercredi ·
/// Horaire · Ta part »): cells divided by 1 px rules.
class FactsCard extends StatelessWidget {
  const FactsCard({super.key, required this.cells, this.flex, this.child, this.valueStyle});

  final List<FactCell> cells;
  final List<int>? flex;

  /// `num-l` by default (GAM-01); MAT-05 uses `num-m`.
  final TextStyle? valueStyle;

  /// Content under the cells (MAT-05's QR button).
  final Widget? child;

  // gam-fact: padding 12 12 14.
  static const EdgeInsets _cell = EdgeInsets.fromLTRB(MuSpace.s3, MuSpace.s3, MuSpace.s3, 14);

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, cell) in cells.indexed) ...[
                  if (i > 0) VerticalDivider(width: 1, thickness: 1, color: c.border),
                  Expanded(
                    flex: flex?[i] ?? 1,
                    child: Padding(
                      padding: _cell,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cell.label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MuType.overline.copyWith(color: c.textSecondary),
                          ),
                          const SizedBox(height: MuSpace.s1),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: cell.value),
                                if (cell.valueUnit != null)
                                  TextSpan(
                                    text: ' ${cell.valueUnit}',
                                    style: MuType.numS.copyWith(color: c.text),
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: (valueStyle ?? MuType.numL).copyWith(color: c.text),
                          ),
                          const SizedBox(height: 2),
                          cell.captionWidget ??
                              Text(
                                cell.caption ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MuType.caption.copyWith(color: c.textSecondary),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

/// A message of a game's discussion: avatar, « Skander T. · 17h42 », the bubble.
class ChatMessage extends StatelessWidget {
  const ChatMessage({super.key, required this.author, required this.time, required this.text});

  final MuPerson author;
  final DateTime time;
  final String text;

  // gam-bubble: padding 8 12, radius 4 16 16 16, max 262.
  static const double _maxWidth = 262;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuAvatar(name: author.name, size: MuAvatarSize.s),
        const SizedBox(width: MuSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: author.name,
                      style: MuType.labelS.copyWith(color: c.text),
                    ),
                    TextSpan(
                      text: ' · ${formatTime(time)}',
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MuSpace.s1),
              Container(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(MuRadius.xs),
                    topEnd: Radius.circular(MuRadius.lg),
                    bottomStart: Radius.circular(MuRadius.lg),
                    bottomEnd: Radius.circular(MuRadius.lg),
                  ),
                ),
                child: Text(text, style: MuType.body.copyWith(color: c.text)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The dashed « Rejoins la partie pour écrire aux joueurs. » box under the chat preview.
class ChatLocked extends StatelessWidget {
  const ChatLocked(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return CustomPaint(
      painter: DashedBorderPainter(color: c.borderStrong, radius: MuRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s3),
        child: Row(
          children: [
            Icon(PhosphorIcons.lockSimple(), size: MuSize.iconXs, color: c.textSecondary),
            const SizedBox(width: MuSpace.s2),
            Expanded(
              child: Text(text, style: MuType.caption.copyWith(color: c.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 1 px dashed rounded border.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({required this.color, required this.radius, this.dash = 5});

  final Color color;
  final double radius;
  final double dash;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash * 2;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) => old.color != color || old.radius != radius;
}

/// The cancellation steps of a game (GAM-01 « Règles et annulation »): three dots — success,
/// warning, outline — with the deadline, the rule and the amount.
class CancellationSteps extends StatelessWidget {
  const CancellationSteps({
    super.key,
    required this.freeUntil,
    required this.halfUntil,
    required this.share,
  });

  final DateTime freeUntil;
  final DateTime halfUntil;
  final num share;

  // gam-step: grid 20px / 1fr / auto, a 12 dot in 20.
  static const double _dotBox = 20;
  static const double _dot = 12;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    Widget step(Color? fill, Color? ring, String when, String rule, num amount) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _dotBox,
          height: _dotBox,
          child: Center(
            child: Container(
              width: _dot,
              height: _dot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: ring == null ? null : Border.all(color: ring, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: MuSpace.s2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(when, style: MuType.label.copyWith(color: c.text)),
              Text(rule, style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: MuSpace.s2),
        Text(
          formatDT(amount),
          style: MuType.numS.copyWith(
            color: fill == c.success
                ? c.successText
                : fill == c.warning
                ? c.warningText
                : c.textSecondary,
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        step(c.success, null, l10n.jusquA2(formatDateTime(freeUntil)), l10n.annulationGratuite, share),
        const SizedBox(height: MuSpace.s3),
        step(c.warning, null, l10n.jusquA2(formatDateTime(halfUntil)), l10n.rembourses, share / 2),
        const SizedBox(height: MuSpace.s3),
        step(null, c.borderStrong, l10n.moinsDeHAvant, l10n.nonRemboursable, 0),
      ],
    );
  }
}

/// « Coup d’envoi · Dans 2 j 2 h », the dark pill over the hero (GAM-01, GAM-05).
class KickoffPill extends StatelessWidget {
  const KickoffPill({super.key, required this.start, this.onDark = true});

  final DateTime start;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MuSize.controlS,
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3),
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: onDark ? (dark ? c.surfaceElevated : c.night800) : c.surfaceMuted,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(extensions: [if (onDark && !dark) MuColors.dark else c]),
        child: Builder(
          // Never wider than the hero leaves it: the pill shrinks before it clips.
          builder: (context) => FittedBox(
            fit: BoxFit.scaleDown,
            child: MuCountdown(
              endsAt: start,
              format: MuCountdownFormat.relative,
              size: MuCountdownSize.s,
              label: l10n.coupDEnvoi,
              urgentAfter: Duration.zero,
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of the venue card: the static map, the name and « Vérifié », the address and distance,
/// the rating, then « Itinéraire » and « Voir le terrain ».
class VenueRow extends StatelessWidget {
  const VenueRow({
    super.key,
    required this.venue,
    required this.street,
    required this.distanceKm,
    required this.onDirections,
    required this.onOpen,
  });

  final MuVenue venue;

  /// « Route de la Corniche, La Marsa ».
  final String street;
  final double? distanceKm;
  final VoidCallback onDirections;
  final VoidCallback onOpen;

  // GAM-01: the static map is a 96 square.
  static const double _map = 96;
  static const double _mapZoom = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: MuRadius.smAll,
          child: SizedBox(
            width: _map,
            height: _map,
            child: MuMapView(
              center: venue.position!,
              zoom: _mapZoom,
              venues: [
                MuMapVenue(
                  id: venue.id,
                  name: venue.name,
                  sport: venue.sports.first,
                  position: venue.position!,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: MuSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      venue.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.labelL.copyWith(color: c.text),
                    ),
                  ),
                  if (venue.verified) ...[
                    const SizedBox(width: MuSpace.s2),
                    MuStatusBadge(
                      status: MuStatus.verified,
                      label: l10n.verifie,
                      size: MuBadgeSize.s,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: street),
                    if (distanceKm != null) ...[
                      const TextSpan(text: ' · '),
                      TextSpan(
                        text: '${formatLevel(distanceKm!)} km',
                        style: MuType.labelS.copyWith(color: c.text),
                      ),
                    ],
                  ],
                ),
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: MuSpace.s1),
              if (venue.rating != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: MuStarRating.display(value: venue.rating!, count: venue.reviews),
                  ),
                ),
              const SizedBox(height: MuSpace.s2),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MuButton.secondary(
                        label: l10n.itineraire,
                        leading: PhosphorIcons.navigationArrow(),
                        size: MuButtonSize.s,
                        onPressed: onDirections,
                      ),
                      const SizedBox(width: MuSpace.s1),
                      MuButton.tertiary(
                        label: l10n.voirLeTerrain,
                        size: MuButtonSize.s,
                        onPressed: onOpen,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
