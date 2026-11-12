import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/training_models.dart';

/// The average, its stars and the split by stars (ENT-03 « Avis des élèves », the reviews page).
class RatingSummary extends StatelessWidget {
  const RatingSummary({super.key, required this.program});

  final TrainingProgram program;

  static const double _stars = 16;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final p = program;
    final total = p.ratingCounts.fold(0, (a, b) => a + b);
    return MuCardSurface(
      child: Row(
        children: [
          Column(
            children: [
              Text(formatLevel(p.card.rating), style: MuType.numHero.copyWith(color: c.text)),
              MuStarRating.display(value: p.card.rating, size: _stars, showValue: false),
              const SizedBox(height: MuSpace.s1),
              Text(l10n.entReviews(p.card.reviews), style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
          const SizedBox(width: MuSpace.s5),
          Expanded(
            child: Semantics(
              container: true,
              label: l10n.entRatingSplit,
              child: Column(
                children: [
                  for (final (i, n) in p.ratingCounts.indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: MuSpace.s1 / 2),
                      child: Semantics(
                        label: l10n.entStarsCount(5 - i, n),
                        excludeSemantics: true,
                        child: Row(
                          children: [
                            SizedBox(
                              width: MuSpace.s6,
                              child: Text('${5 - i} ★', style: MuType.caption.copyWith(color: c.textSecondary)),
                            ),
                            Expanded(
                              child: MuProgressBar(
                                value: n.toDouble(),
                                max: total == 0 ? 1 : total.toDouble(),
                                size: MuProgressSize.s,
                                showValue: false,
                              ),
                            ),
                            SizedBox(
                              width: MuSpace.s8,
                              child: Text(
                                '$n',
                                textAlign: TextAlign.end,
                                style: MuType.numXs.copyWith(color: c.text),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A student's review: avatar, name, « Programme terminé · il y a 5 jours », stars, text.
class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review});

  final ProgramReview review;

  static const double _stars = 16;

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
              MuAvatar(name: r.author, size: MuAvatarSize.s),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.author, style: MuType.label.copyWith(color: c.text)),
                    Text(
                      r.finished ? l10n.entFinishedAgo(r.daysAgo) : l10n.entDaysAgo(r.daysAgo),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              MuStarRating.display(value: r.stars.toDouble(), size: _stars, showValue: false),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Text(r.text, style: MuType.body.copyWith(color: c.text)),
        ],
      ),
    );
  }
}

/// « Noter le programme »: stars and an optional comment. Returns (stars, text) when published.
Future<(int, String?)?> showRateSheet(
  BuildContext context, {
  required String programTitle,
  (int, String?)? current,
}) {
  final text = TextEditingController(text: current?.$2 ?? '');
  var stars = current?.$1 ?? 0;
  return MuBottomSheet.show<(int, String?)>(
    context,
    title: l10n.entRateProgram,
    child: StatefulBuilder(
      builder: (context, setState) {
        final c = context.mu;
        return Padding(
          padding: const EdgeInsets.all(MuSpace.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(programTitle, style: MuType.label.copyWith(color: c.text)),
              const SizedBox(height: MuSpace.s3),
              MuStarRating.input(
                value: stars.toDouble(),
                label: l10n.entYourRating,
                onChanged: (v) => setState(() => stars = v),
              ),
              const SizedBox(height: MuSpace.s3),
              MuTextField(
                label: l10n.entYourReview,
                optional: true,
                controller: text,
                multiline: true,
                minLines: 3,
                maxLength: 500,
                helper: l10n.entReviewPublic,
              ),
              const SizedBox(height: MuSpace.s3),
              MuButton.primary(
                label: l10n.entPublishRating,
                size: MuButtonSize.l,
                fullWidth: true,
                onPressed: stars == 0
                    ? null
                    : () => Navigator.of(context).pop((
                        stars,
                        text.text.trim().isEmpty ? null : text.text.trim(),
                      )),
              ),
            ],
          ),
        );
      },
    ),
  );
}
