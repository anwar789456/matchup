import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../l10n/l10n.dart';
import '../theme/theme.dart';
import 'mu_avatar.dart';
import 'mu_button.dart';
import 'mu_chip.dart';
import 'mu_program_card.dart';
import 'mu_skeleton.dart';
import 'mu_sport_icon.dart';
import 'mu_status_badge.dart';
import 'src/card_surface.dart';
import 'src/card_variant.dart';

/// The data a coach card shows.
@immutable
class MuCoach {
  const MuCoach({
    required this.id,
    required this.name,
    required this.sport,
    required this.city,
    required this.specialties,
    required this.rating,
    required this.reviews,
    required this.students,
    required this.languages,
    this.priceFrom,
    this.certification,
  });

  final String id;

  /// First name + initial: « Karim J. ».
  final String name;
  final MuSport sport;
  final String city;

  /// 2–4 nouns: « Bandeja », « Service ».
  final List<String> specialties;
  final double rating;
  final int reviews;
  final int students;

  /// Codes: « FR », « AR ».
  final List<String> languages;

  /// Lowest price of a private session, in DT.
  final num? priceFrom;

  /// « Certifié FTT niveau 2 ».
  final String? certification;

  MuCoachRef get ref => MuCoachRef(name);
}

enum MuVerification { verified, pending, none }

/// CoachCard (components/CoachCard.md): verified avatar, specialties, rating · students · price,
/// and « Voir les programmes » (regular); one row in lists (compact).
class MuCoachCard extends StatelessWidget {
  const MuCoachCard({
    super.key,
    required MuCoach this.coach,
    this.verification = MuVerification.verified,
    this.variant = MuCardVariant.regular,
    this.onTap,
    this.onCta,
  });

  const MuCoachCard.loading({super.key, this.variant = MuCardVariant.regular})
    : coach = null,
      verification = MuVerification.verified,
      onTap = null,
      onCta = null;

  final MuCoach? coach;
  final MuVerification verification;
  final MuCardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onCta;

  // CoachCard.md: seal 22 on Avatar L, 16 on Avatar M, with a 2px `surface` ring.
  static const double _sealL = 22;
  static const double _sealM = 16;
  static const double _sealRing = 2;
  static const double _star = 14;
  static const double _metaIcon = 14;

  String _semantics(MuCoach k) => [
    k.ref.label,
    if (verification == MuVerification.verified) l10n.entVerifiedCoach,
    l10n.entRatingSemantics(formatLevel(k.rating), k.reviews),
    l10n.entStudents(k.students),
    '${k.sport.label} · ${k.specialties.join(', ')}',
  ].join(', ');

  @override
  Widget build(BuildContext context) {
    final k = coach;
    if (k == null) {
      return const MuCardSurface(
        child: Row(
          children: [
            MuSkeleton.circle(size: MuSize.avatarM),
            SizedBox(width: MuSpace.s3),
            Expanded(child: MuSkeleton.text(lines: 3)),
          ],
        ),
      );
    }
    return variant == MuCardVariant.compact ? _compact(context, k) : _regular(context, k);
  }

  Widget _avatar(BuildContext context, MuCoach k, {required bool large}) {
    final c = context.mu;
    final seal = large ? _sealL : _sealM;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        MuAvatar(name: k.name, size: large ? MuAvatarSize.l : MuAvatarSize.m),
        if (verification != MuVerification.none)
          PositionedDirectional(
            end: -_sealRing,
            bottom: -_sealRing,
            child: Semantics(
              label: verification == MuVerification.verified
                  ? l10n.entVerifiedCoach
                  : l10n.entVerificationPending,
              child: Container(
                width: seal + _sealRing * 2,
                height: seal + _sealRing * 2,
                decoration: BoxDecoration(
                  color: verification == MuVerification.verified ? c.accent : c.warningSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface, width: _sealRing),
                ),
                alignment: Alignment.center,
                child: Icon(
                  verification == MuVerification.verified
                      ? PhosphorIcons.sealCheck(PhosphorIconsStyle.fill)
                      : PhosphorIcons.hourglassMedium(PhosphorIconsStyle.fill),
                  size: seal - MuSpace.s1,
                  color: verification == MuVerification.verified ? c.onAccent : c.warningText,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _ratingLine(BuildContext context, MuCoach k) {
    final c = context.mu;
    final secondary = MuType.caption.copyWith(color: c.textSecondary);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(PhosphorIcons.star(PhosphorIconsStyle.fill), size: _star, color: c.text),
        const SizedBox(width: MuSpace.s1),
        Text(formatLevel(k.rating), style: MuType.numXs.copyWith(color: c.text)),
        const SizedBox(width: MuSpace.s1),
        Text('(${k.reviews})', style: secondary),
        Text(' · ${l10n.entStudents(k.students)}', style: secondary),
      ],
    );
  }

  Widget _compact(BuildContext context, MuCoach k) {
    final c = context.mu;
    return MuCardSurface(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s3, MuSpace.s3, MuSpace.s4, MuSpace.s3),
      semanticLabel: _semantics(k),
      child: Row(
        children: [
          _avatar(context, k, large: false),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k.ref.label, style: MuType.label.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s1 / 2),
                _ratingLine(context, k),
                const SizedBox(height: MuSpace.s1 / 2),
                Row(
                  children: [
                    MuSportIcon(k.sport, size: _metaIcon, color: k.sport.text(c)),
                    const SizedBox(width: MuSpace.s1),
                    Expanded(
                      child: Text(
                        '${k.sport.label} · ${k.specialties.take(2).join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _regular(BuildContext context, MuCoach k) {
    final c = context.mu;
    final pending = verification == MuVerification.pending;
    final secondary = MuType.caption.copyWith(color: c.textSecondary);

    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: MuType.numM.copyWith(color: pending ? c.textSecondary : c.text),
          ),
          Text(label, style: secondary, textAlign: TextAlign.center),
        ],
      ),
    );

    return MuCardSurface(
      onTap: onTap,
      semanticLabel: _semantics(k),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _avatar(context, k, large: true),
              const SizedBox(width: MuSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      k.ref.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.labelL.copyWith(color: c.text),
                    ),
                    const SizedBox(height: MuSpace.s1),
                    if (pending)
                      MuStatusBadge(status: MuStatus.pending, label: l10n.entVerificationPending)
                    else
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(PhosphorIcons.mapPin(), size: _metaIcon, color: c.textSecondary),
                          const SizedBox(width: MuSpace.s1 / 2),
                          Text(k.city, style: secondary),
                          Text(' · ', style: secondary),
                          Icon(PhosphorIcons.translate(), size: _metaIcon, color: c.textSecondary),
                          const SizedBox(width: MuSpace.s1 / 2),
                          Semantics(
                            label: l10n.entLanguages(k.languages.join(', ')),
                            excludeSemantics: true,
                            child: Text(k.languages.join(' · '), style: secondary),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            children: [
              MuChip.sport(k.sport, size: MuChipSize.s),
              for (final s in k.specialties)
                MuChip(kind: MuChipKind.input, label: s, size: MuChipSize.s),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          Container(
            padding: const EdgeInsets.all(MuSpace.s3),
            decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  stat(
                    pending ? '—' : '★ ${formatLevel(k.rating)}',
                    pending ? l10n.entNoReviews : l10n.entReviews(k.reviews),
                  ),
                  VerticalDivider(width: MuSpace.s3, color: c.border),
                  stat('${k.students}', l10n.entStudentsUnit(k.students)),
                  VerticalDivider(width: MuSpace.s3, color: c.border),
                  stat(
                    k.priceFrom == null ? '—' : l10n.entFrom(formatDT(k.priceFrom!)),
                    l10n.entPerSession,
                  ),
                ],
              ),
            ),
          ),
          if (pending) ...[
            const SizedBox(height: MuSpace.s3),
            Text(l10n.entPendingInfo, style: secondary),
          ],
          const SizedBox(height: MuSpace.s4),
          pending
              ? MuButton.secondary(
                  label: l10n.entCompleteProfile,
                  leading: PhosphorIcons.pencilSimple(),
                  onPressed: onCta,
                  fullWidth: true,
                )
              : MuButton.secondary(
                  label: l10n.entSeePrograms,
                  trailing: PhosphorIcons.arrowRight(),
                  onPressed: onCta,
                  fullWidth: true,
                ),
        ],
      ),
    );
  }
}
