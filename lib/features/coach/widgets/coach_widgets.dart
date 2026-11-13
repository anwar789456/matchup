import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/coach_models.dart';

/// « octobre » — the month in full.
String formatMonthLong(DateTime d) => l10n.coaMonths.split('|')[d.month - 1];

/// « Revenus d’octobre » — the month with its elided « de ».
String deMonth(DateTime d) => elideDe(formatMonthLong(d));

/// « d’Omar D. », « de Yassine B. » — a person's name after « de » (no elision before a Y,
/// unlike [elideDe] for places).
String elideDeName(String name) => RegExp(r'^[aeiouàâäéèêëîïôöùûüh]', caseSensitive: false)
        .hasMatch(name)
    ? elideDe(name)
    : l10n.coaOfName(name);

/// « 2 340 DT »: the amount in [style] with « DT » smaller.
class MoneyHero extends StatelessWidget {
  const MoneyHero({super.key, required this.amount, this.style, this.color});

  final num amount;

  /// `num-xl` when null.
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: formatAmount(amount), style: style ?? MuType.numXl),
            TextSpan(text: ' $dtUnit', style: MuType.numS.copyWith(color: c.textSecondary)),
          ],
        ),
        style: TextStyle(color: color ?? c.text),
      ),
    );
  }
}

/// « ↗ +18 % vs sept. à la même date »: up in `success-text`, down in `error-text`.
class DeltaLine extends StatelessWidget {
  const DeltaLine({super.key, required this.percent, required this.period});

  final double percent;
  final String period;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final up = percent >= 0;
    final ink = up ? c.successText : c.errorText;
    final value = '${up ? '+' : '−'}${percent.abs().round()} %';
    return Semantics(
      label: '$value $period',
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(up ? PhosphorIcons.trendUp() : PhosphorIcons.trendDown(), size: MuSize.iconXs, color: ink),
          const SizedBox(width: MuSpace.s1),
          Text(value, style: MuType.numS.copyWith(color: ink)),
          const SizedBox(width: MuSpace.s2),
          Text(period, style: MuType.caption.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}

/// An info icon and a caption.
class InfoLine extends StatelessWidget {
  const InfoLine(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon ?? PhosphorIcons.info(), size: MuSize.iconXs, color: c.textSecondary),
        const SizedBox(width: MuSpace.s2),
        Expanded(child: Text(text, style: MuType.caption.copyWith(color: c.textSecondary))),
      ],
    );
  }
}

/// « Brouillon », or « Publication programmée » once scheduled.
class DraftBadge extends StatelessWidget {
  const DraftBadge({super.key, required this.draft});

  final ProgramDraft draft;

  @override
  Widget build(BuildContext context) => draft.status == DraftStatus.scheduled
      ? MuStatusBadge(status: MuStatus.pending, label: l10n.coaScheduled, size: MuBadgeSize.s)
      : const MuStatusBadge(status: MuStatus.draft, size: MuBadgeSize.s);
}

/// A student's review: avatar with level, name and date, stars and program, the text.
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final CoachReview review;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = review;
    return MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MuAvatar(name: r.author, size: MuAvatarSize.m, level: r.level),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(r.author, style: MuType.label.copyWith(color: c.text)),
                        ),
                        Text(formatDay(r.date), style: MuType.caption.copyWith(color: c.textSecondary)),
                      ],
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: MuSpace.s2,
                      children: [
                        MuStarRating.display(value: r.stars.toDouble(), size: 16, showValue: false),
                        Text(r.program, style: MuType.caption.copyWith(color: c.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Text(r.text, style: MuType.body.copyWith(color: c.text)),
        ],
      ),
    );
  }
}

/// « Répondre » to a review: the quote, a reply field, « Publier ». True when published.
Future<bool?> showReplySheet(BuildContext context, {required String who, required String quote}) {
  final text = TextEditingController();
  return MuBottomSheet.show<bool>(
    context,
    title: l10n.coaReplyTo(who),
    child: StatefulBuilder(
      builder: (context, setState) {
        final c = context.mu;
        return Padding(
          padding: const EdgeInsets.all(MuSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(quote, style: MuType.body.copyWith(color: c.textSecondary)),
              const SizedBox(height: MuSpace.s3),
              MuTextField(
                label: l10n.coaYourReply,
                controller: text,
                multiline: true,
                minLines: 3,
                maxLength: 500,
                helper: l10n.coaReplyPublic,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: MuSpace.s3),
              MuButton.primary(
                label: l10n.coaPublish,
                size: MuButtonSize.l,
                fullWidth: true,
                onPressed: text.text.trim().isEmpty ? null : () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
    ),
  );
}
