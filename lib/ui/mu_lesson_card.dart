import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../theme/theme.dart';
import 'mu_court_art.dart';
import 'mu_skeleton.dart';
import 'src/card_surface.dart';
import 'src/card_variant.dart';

/// The data a lesson card shows: one session of a program.
@immutable
class MuLesson {
  const MuLesson({
    required this.index,
    required this.title,
    required this.minutes,
    required this.drills,
    this.sport = MuSport.padel,
    this.downloaded = false,
  });

  /// 1-based number in the program (« Séance 3 »).
  final int index;
  final String title;
  final int minutes;

  /// Number of exercises.
  final int drills;
  final MuSport sport;

  /// Saved on the phone: « Hors ligne ».
  final bool downloaded;
}

enum MuLessonStatus { available, current, done, locked }

/// LessonCard (components/LessonCard.md): one session — video thumbnail with play and duration
/// (or the index circle in compact), « Séance 3 · Placement au filet », drill count and its state.
class MuLessonCard extends StatelessWidget {
  const MuLessonCard({
    super.key,
    required MuLesson this.lesson,
    this.status = MuLessonStatus.available,
    this.progress,
    this.variant = MuCardVariant.regular,
    this.onTap,
  });

  const MuLessonCard.loading({super.key, this.variant = MuCardVariant.regular})
    : lesson = null,
      status = MuLessonStatus.available,
      progress = null,
      onTap = null;

  final MuLesson? lesson;
  final MuLessonStatus status;

  /// Watched part of the video (0–1): the Volt bar along the thumbnail bottom.
  final double? progress;
  final MuCardVariant variant;
  final VoidCallback? onTap;

  // LessonCard.md: thumbnail 128 wide at 16:10, play disc 36, index circle 36, watched bar 3,
  // current ring 2.
  static const double _thumbWidth = 128;
  static const double _disc = 36;
  static const double _discIcon = 16;
  static const double _watched = 3;
  static const double _ring = 2;
  static const double _badgeHeight = 20;
  static const double _metaIcon = 14;

  String _semantics(MuLesson l) {
    final state = switch (status) {
      MuLessonStatus.current => l10n.entTodayLower,
      MuLessonStatus.done => l10n.terminee.toLowerCase(),
      MuLessonStatus.locked => l10n.entPremium,
      MuLessonStatus.available => null,
    };
    final name = l10n.entLessonLabel(l.index, l.title);
    return state == null ? name : '$name · $state';
  }

  String _drills(int n) => l10n.entDrills(n);

  @override
  Widget build(BuildContext context) {
    final l = lesson;
    if (l == null) {
      return MuCardSurface(
        padding: const EdgeInsets.all(MuSpace.s3),
        child: Row(
          children: [
            variant == MuCardVariant.compact
                ? const MuSkeleton.circle(size: _disc)
                : const SizedBox(
                    width: _thumbWidth,
                    child: AspectRatio(aspectRatio: 16 / 10, child: MuSkeleton()),
                  ),
            const SizedBox(width: MuSpace.s3),
            const Expanded(child: MuSkeleton.text(lines: 3)),
          ],
        ),
      );
    }
    final card = variant == MuCardVariant.compact ? _compact(context, l) : _regular(context, l);
    if (status != MuLessonStatus.current) return card;
    final c = context.mu;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: c.primary, width: _ring),
      ),
      child: card,
    );
  }

  Widget _badge(BuildContext context, String label, IconData icon) {
    final c = context.mu;
    return Container(
      height: _badgeHeight,
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
      decoration: ShapeDecoration(color: c.accent, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _metaIcon, color: c.onAccent),
          const SizedBox(width: MuSpace.s1),
          Text(label, style: MuType.labelS.copyWith(color: c.onAccent)),
        ],
      ),
    );
  }

  Widget _doneLabel(BuildContext context) {
    final c = context.mu;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), size: _metaIcon, color: c.successText),
        const SizedBox(width: MuSpace.s1),
        Text(l10n.terminee, style: MuType.labelS.copyWith(color: c.successText)),
      ],
    );
  }

  /// « 4 exercices · ☁ Hors ligne » on one line.
  Widget _meta(BuildContext context, String text, {required bool downloaded}) {
    final c = context.mu;
    final style = MuType.caption.copyWith(color: c.textSecondary);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text),
          if (downloaded) ...[
            const TextSpan(text: ' · '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: MuSpace.s1 / 2),
                child: Icon(PhosphorIcons.cloudCheck(), size: _metaIcon, color: c.textSecondary),
              ),
            ),
            TextSpan(text: l10n.horsLigne),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }

  Widget _regular(BuildContext context, MuLesson l) {
    final c = context.mu;
    final current = status == MuLessonStatus.current;
    final locked = status == MuLessonStatus.locked;
    final thumb = SizedBox(
      width: _thumbWidth,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: ClipRRect(
          borderRadius: MuRadius.smAll,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MuCourtArt(sport: l.sport),
              if (locked) ColoredBox(color: c.scrim),
              Center(
                child: Container(
                  width: _disc,
                  height: _disc,
                  decoration: BoxDecoration(
                    // A media overlay: the same white disc in both themes (LessonCard.md).
                    color: current ? c.accent : MuPalette.white,
                    shape: BoxShape.circle,
                    boxShadow: MuElevation.of(context).level2,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    locked
                        ? PhosphorIcons.lockSimple(PhosphorIconsStyle.fill)
                        : PhosphorIcons.play(PhosphorIconsStyle.fill),
                    size: _discIcon,
                    color: current ? c.onAccent : MuPalette.ink900,
                  ),
                ),
              ),
              PositionedDirectional(
                end: MuSpace.s2,
                bottom: MuSpace.s1,
                child: Text(
                  l10n.entMinutes(l.minutes),
                  style: MuType.numXs.copyWith(color: MuPalette.white),
                ),
              ),
              if (progress != null)
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  height: _watched,
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: progress!.clamp(0, 1),
                    child: ColoredBox(color: c.accent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return MuCardSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(MuSpace.s3),
      semanticLabel: _semantics(l),
      child: Row(
        children: [
          thumb,
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.entLessonEyebrow(l.index).toUpperCase(),
                  style: MuType.overline.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: MuSpace.s1 / 2),
                Text(
                  l.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MuType.label.copyWith(color: c.text),
                ),
                const SizedBox(height: MuSpace.s1 / 2),
                _meta(context, _drills(l.drills), downloaded: l.downloaded),
                if (status != MuLessonStatus.available) ...[
                  const SizedBox(height: MuSpace.s2),
                  switch (status) {
                    MuLessonStatus.current => _badge(
                      context,
                      l10n.entToday,
                      PhosphorIcons.target(),
                    ),
                    MuLessonStatus.locked => _badge(
                      context,
                      l10n.entPremium,
                      PhosphorIcons.lockSimple(PhosphorIconsStyle.fill),
                    ),
                    _ => _doneLabel(context),
                  },
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compact(BuildContext context, MuLesson l) {
    final c = context.mu;
    final done = status == MuLessonStatus.done;
    final index = Container(
      width: _disc,
      height: _disc,
      decoration: BoxDecoration(
        color: done ? c.successSoft : c.surfaceMuted,
        shape: BoxShape.circle,
        border: done ? null : Border.all(color: c.border),
      ),
      alignment: Alignment.center,
      child: done
          ? Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: _discIcon, color: c.successText)
          : Text('${l.index}', style: MuType.numS.copyWith(color: c.text)),
    );
    return MuCardSurface(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s3, MuSpace.s3, MuSpace.s4, MuSpace.s3),
      semanticLabel: _semantics(l),
      child: Row(
        children: [
          index,
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MuType.label.copyWith(color: c.text),
                ),
                const SizedBox(height: MuSpace.s1 / 2),
                _meta(
                  context,
                  l10n.entLessonMetaCompact(l.minutes, _drills(l.drills)),
                  downloaded: l.downloaded,
                ),
              ],
            ),
          ),
          switch (status) {
            MuLessonStatus.current => _badge(context, l10n.entTodayShort, PhosphorIcons.target()),
            MuLessonStatus.locked => _badge(
              context,
              l10n.entPremium,
              PhosphorIcons.lockSimple(PhosphorIconsStyle.fill),
            ),
            MuLessonStatus.done => _doneLabel(context),
            MuLessonStatus.available => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}
