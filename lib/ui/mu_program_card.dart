import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../l10n/l10n.dart';
import '../theme/theme.dart';
import 'mu_avatar.dart';
import 'mu_button.dart';
import 'mu_chip.dart';
import 'mu_court_art.dart';
import 'mu_progress_ring.dart';
import 'mu_skeleton.dart';
import 'mu_status_badge.dart';
import 'src/card_surface.dart';
import 'src/card_variant.dart';

/// A coach as the training cards name them: « Coach Karim J. » with the verified seal.
@immutable
class MuCoachRef {
  const MuCoachRef(this.name, {this.verified = true});

  /// First name + initial: « Karim J. ».
  final String name;
  final bool verified;

  /// « Coach Karim J. » (ProgramCard.md « Always prefix the coach »).
  String get label => l10n.entCoachName(name);
}

/// The data a program card shows.
@immutable
class MuProgram {
  const MuProgram({
    required this.id,
    required this.title,
    required this.coach,
    required this.sport,
    required this.level,
    required this.weeks,
    required this.sessions,
    required this.minutesPerDay,
    required this.rating,
    required this.reviews,
    this.price = 0,
    this.premium = false,
  });

  final String id;
  final String title;
  final MuCoachRef coach;
  final MuSport sport;
  final double level;
  final int weeks;
  final int sessions;
  final int minutesPerDay;
  final double rating;
  final int reviews;

  /// The whole program, in DT; 0 = free.
  final num price;

  /// « Inclus dans Premium »: shown instead of the price.
  final bool premium;
}


enum MuProgramStatus { available, enrolled, completed }

/// ProgramCard (components/ProgramCard.md): cover, sport and level, coach, length, rating and
/// price — or, once joined, progress and « Continuer ».
class MuProgramCard extends StatelessWidget {
  const MuProgramCard({
    super.key,
    required MuProgram this.program,
    this.variant = MuCardVariant.regular,
    this.status = MuProgramStatus.available,
    this.progress = 0,
    this.nextLesson,
    this.completedLine,
    this.onTap,
    this.onContinue,
    this.onRate,
  });

  const MuProgramCard.loading({super.key, this.variant = MuCardVariant.regular})
    : program = null,
      status = MuProgramStatus.available,
      progress = 0,
      nextLesson = null,
      completedLine = null,
      onTap = null,
      onContinue = null,
      onRate = null;

  final MuProgram? program;
  final MuCardVariant variant;
  final MuProgramStatus status;

  /// Sessions done.
  final int progress;

  /// « Bandeja croisée »: the next session's title (enrolled).
  final String? nextLesson;

  /// « Le dim. 12 oct. · 8 séances en 13 jours » (completed).
  final String? completedLine;
  final VoidCallback? onTap;
  final VoidCallback? onContinue;
  final VoidCallback? onRate;

  // ProgramCard.md: compact thumbnail 64, compact ring 44, enrolled bar 6, seals 16 / 14.
  static const double _thumb = 64;
  static const double _ring = 44;
  static const double _bar = 6;
  static const double _sealSize = 16;
  static const double _sealCompact = 14;
  static const double _star = 14;

  String _semantics(MuProgram p) {
    final parts = [p.title, p.coach.label, l10n.entProgramMeta(p.weeks, p.sessions, p.minutesPerDay)];
    switch (status) {
      case MuProgramStatus.enrolled:
        parts.add(l10n.entSessionsOf(progress, p.sessions));
      case MuProgramStatus.completed:
        parts.add(l10n.termine);
      case MuProgramStatus.available:
        parts.add(l10n.entRatingSemantics(formatLevel(p.rating), p.reviews));
        parts.add(_priceLabel(p));
    }
    return parts.join(', ');
  }

  static String _priceLabel(MuProgram p) => p.premium
      ? l10n.entIncludedInPremium
      : p.price == 0
      ? l10n.gratuit
      : formatDT(p.price);

  @override
  Widget build(BuildContext context) {
    final p = program;
    if (p == null) return _skeleton();
    return variant == MuCardVariant.compact ? _compact(context, p) : _regular(context, p);
  }

  Widget _skeleton() => MuCardSurface(
    padding: variant == MuCardVariant.compact ? const EdgeInsets.all(MuSpace.s3) : EdgeInsets.zero,
    child: variant == MuCardVariant.compact
        ? const Row(
            children: [
              MuSkeleton(width: _thumb, height: _thumb),
              SizedBox(width: MuSpace.s3),
              Expanded(child: MuSkeleton.text(lines: 3)),
            ],
          )
        : const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(aspectRatio: 16 / 9, child: MuSkeleton()),
              Padding(
                padding: EdgeInsets.all(MuSpace.s4),
                child: MuSkeleton.text(lines: 4),
              ),
            ],
          ),
  );

  Widget _seal(BuildContext context, double size) {
    final c = context.mu;
    return Semantics(
      label: l10n.entVerifiedCoach,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(
          PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
          size: size - MuSpace.s1,
          color: c.onAccent,
        ),
      ),
    );
  }

  Widget _rating(BuildContext context, MuProgram p, {required bool withCount}) {
    final c = context.mu;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(PhosphorIcons.star(PhosphorIconsStyle.fill), size: _star, color: c.text),
        const SizedBox(width: MuSpace.s1),
        Text(
          formatLevel(p.rating),
          style: (withCount ? MuType.numS : MuType.numXs).copyWith(color: c.text),
        ),
        if (withCount) ...[
          const SizedBox(width: MuSpace.s1),
          Text('(${p.reviews})', style: MuType.caption.copyWith(color: c.textSecondary)),
        ],
      ],
    );
  }

  Widget _price(BuildContext context, MuProgram p, {required bool compact}) {
    final c = context.mu;
    if (p.premium) return MuPremiumBadge(short: compact);
    if (p.price == 0) return Text(l10n.gratuit, style: MuType.numM.copyWith(color: c.text));
    return Text(formatDT(p.price), style: MuType.numM.copyWith(color: c.text));
  }

  Widget _regular(BuildContext context, MuProgram p) {
    final c = context.mu;
    final body = <Widget>[
      Wrap(
        spacing: MuSpace.s2,
        runSpacing: MuSpace.s2,
        children: [
          MuChip.sport(p.sport, size: MuChipSize.s),
          MuChip.level(p.level, size: MuChipSize.s),
        ],
      ),
      const SizedBox(height: MuSpace.s3),
      Text(
        p.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: MuType.labelL.copyWith(color: c.text),
      ),
      const SizedBox(height: MuSpace.s2),
      Row(
        children: [
          MuAvatar(name: p.coach.name, size: MuAvatarSize.xs),
          const SizedBox(width: MuSpace.s2),
          Flexible(
            child: Text(
              p.coach.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MuType.body.copyWith(color: c.textSecondary),
            ),
          ),
          if (p.coach.verified) ...[const SizedBox(width: MuSpace.s2), _seal(context, _sealSize)],
        ],
      ),
      const SizedBox(height: MuSpace.s1),
      Text(
        l10n.entProgramMeta(p.weeks, p.sessions, p.minutesPerDay),
        style: MuType.body.copyWith(color: c.textSecondary),
      ),
      const SizedBox(height: MuSpace.s4),
      Divider(height: 1, thickness: 1, color: c.border),
      const SizedBox(height: MuSpace.s3),
      ...switch (status) {
        MuProgramStatus.available => [
          Row(
            children: [
              // A new program has no rating yet (COA-08 preview).
              if (p.reviews > 0) _rating(context, p, withCount: true),
              const Spacer(),
              _price(context, p, compact: false),
            ],
          ),
        ],
        MuProgramStatus.enrolled => _enrolledFooter(context, p),
        MuProgramStatus.completed => _completedFooter(context, p),
      },
    ];
    return MuCardSurface(
      onTap: onTap,
      padding: EdgeInsets.zero,
      semanticLabel: _semantics(p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(MuRadius.md)),
            child: AspectRatio(aspectRatio: 16 / 9, child: MuCourtArt(sport: p.sport)),
          ),
          Padding(
            padding: const EdgeInsets.all(MuSpace.s4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: body),
          ),
        ],
      ),
    );
  }

  List<Widget> _enrolledFooter(BuildContext context, MuProgram p) {
    final c = context.mu;
    final percent = p.sessions == 0 ? 0 : (progress / p.sessions * 100).round();
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('$progress/${p.sessions}', style: MuType.numM.copyWith(color: c.text)),
          const SizedBox(width: MuSpace.s1),
          Text(l10n.entSessionsUnit, style: MuType.body.copyWith(color: c.textSecondary)),
          const Spacer(),
          Text('$percent %', style: MuType.numS.copyWith(color: c.textSecondary)),
        ],
      ),
      const SizedBox(height: MuSpace.s2),
      Semantics(
        label: l10n.entSessionsOf(progress, p.sessions),
        child: ClipRRect(
          borderRadius: MuRadius.xsAll,
          child: LinearProgressIndicator(
            value: p.sessions == 0 ? 0 : progress / p.sessions,
            minHeight: _bar,
            color: c.primary,
            backgroundColor: c.border,
          ),
        ),
      ),
      if (nextLesson != null) ...[
        const SizedBox(height: MuSpace.s2),
        Text(
          l10n.entNextLesson(nextLesson!),
          style: MuType.caption.copyWith(color: c.textSecondary),
        ),
      ],
      const SizedBox(height: MuSpace.s3),
      MuButton.primary(
        label: l10n.continuer,
        leading: PhosphorIcons.play(PhosphorIconsStyle.fill),
        onPressed: onContinue,
        fullWidth: true,
      ),
    ];
  }

  List<Widget> _completedFooter(BuildContext context, MuProgram p) {
    final c = context.mu;
    return [
      Row(
        children: [
          Text('${p.sessions}/${p.sessions}', style: MuType.numM.copyWith(color: c.text)),
          const SizedBox(width: MuSpace.s1),
          Text(l10n.entSessionsUnit, style: MuType.body.copyWith(color: c.textSecondary)),
          const Spacer(),
          MuStatusBadge(status: MuStatus.confirmed, label: l10n.termine),
        ],
      ),
      const SizedBox(height: MuSpace.s2),
      ClipRRect(
        borderRadius: MuRadius.xsAll,
        child: LinearProgressIndicator(
          value: 1,
          minHeight: _bar,
          color: c.success,
          backgroundColor: c.border,
        ),
      ),
      if (completedLine != null) ...[
        const SizedBox(height: MuSpace.s2),
        Text(completedLine!, style: MuType.caption.copyWith(color: c.textSecondary)),
      ],
      const SizedBox(height: MuSpace.s3),
      MuButton.secondary(label: l10n.entRateProgram, onPressed: onRate, fullWidth: true),
    ];
  }

  Widget _compact(BuildContext context, MuProgram p) {
    final c = context.mu;
    final enrolled = status == MuProgramStatus.enrolled;
    final completed = status == MuProgramStatus.completed;
    final Widget trailing = switch (status) {
      MuProgramStatus.enrolled || MuProgramStatus.completed => MuProgressRing(
        value: completed ? p.sessions.toDouble() : progress.toDouble(),
        max: p.sessions.toDouble(),
        size: _ring,
        tone: completed ? MuTone.success : MuTone.primary,
        label: p.title,
      ),
      MuProgramStatus.available => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _price(context, p, compact: true),
          if (p.reviews > 0) ...[
            const SizedBox(height: MuSpace.s1),
            _rating(context, p, withCount: false),
          ],
        ],
      ),
    };
    return MuCardSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(MuSpace.s3),
      semanticLabel: _semantics(p),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: MuRadius.smAll,
            child: SizedBox.square(dimension: _thumb, child: MuCourtArt(sport: p.sport)),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MuType.label.copyWith(color: c.text),
                ),
                const SizedBox(height: MuSpace.s1 / 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.coach.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ),
                    if (p.coach.verified) ...[
                      const SizedBox(width: MuSpace.s1),
                      _seal(context, _sealCompact),
                    ],
                  ],
                ),
                const SizedBox(height: MuSpace.s1 / 2),
                Text(
                  enrolled && nextLesson != null
                      ? l10n.entNextLesson(nextLesson!)
                      : l10n.entProgramMetaShort(p.weeks, p.sessions, p.minutesPerDay),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: MuSpace.s3),
          trailing,
        ],
      ),
    );
  }
}

/// « Inclus dans Premium »: the Volt badge with the crown (« Premium » when [short]).
class MuPremiumBadge extends StatelessWidget {
  const MuPremiumBadge({super.key, this.short = false, this.label});

  final bool short;

  /// Overrides the label (« Inclus dans ton essai Premium »).
  final String? label;

  static const double _height = 20;
  static const double _icon = 14;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final text = label ?? (short ? l10n.entPremium : l10n.entIncludedInPremium);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Container(
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
        decoration: ShapeDecoration(color: c.accent, shape: const StadiumBorder()),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.crownSimple(PhosphorIconsStyle.fill), size: _icon, color: c.onAccent),
            const SizedBox(width: MuSpace.s1),
            Text(text, style: MuType.labelS.copyWith(color: c.onAccent)),
          ],
        ),
      ),
    );
  }
}
