import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/training_providers.dart';
import '../data/training_story.dart';
import '../training_routes.dart';
import '../widgets/review_widgets.dart';

/// « Voir les 64 avis »: the program's rating and its reviews, filtered by stars.
class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key, required this.programId});

  final String programId;

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  /// Stars to show (null: all).
  int? _stars;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final p = ref.watch(programProvider(widget.programId));
    void back() => context.canPop() ? context.pop() : context.go(TrainingRoutes.program(widget.programId));
    if (p == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Column(
          children: [
            MuTopAppBar.compact(title: l10n.entStudentReviews, onBack: back),
            const Expanded(child: Center(child: MuSpinner())),
          ],
        ),
      );
    }
    // Newest first.
    final all = [...TrainingStory.reviewsOf(p)]..sort((a, b) => a.daysAgo.compareTo(b.daysAgo));
    final shown = [for (final r in all) if (_stars == null || r.stars == _stars) r];
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(title: l10n.entStudentReviews, subtitle: p.title, onBack: back),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s8),
              children: [
                RatingSummary(program: p),
                const SizedBox(height: MuSpace.s4),
                Semantics(
                  container: true,
                  label: l10n.entFilterReviews,
                  child: Wrap(
                    spacing: MuSpace.s2,
                    runSpacing: MuSpace.s2,
                    children: [
                      MuChip(
                        kind: MuChipKind.choice,
                        label: l10n.coaAll,
                        count: all.length,
                        selected: _stars == null,
                        onSelected: (_) => setState(() => _stars = null),
                      ),
                      for (var st = 5; st >= 1; st--)
                        if (all.any((r) => r.stars == st))
                          MuChip(
                            kind: MuChipKind.choice,
                            label: '$st ★',
                            count: all.where((r) => r.stars == st).length,
                            selected: _stars == st,
                            onSelected: (_) => setState(() => _stars = st),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s2),
                Text(
                  l10n.entReviewsShown(all.length, p.card.reviews),
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: MuSpace.s3),
                for (final r in shown) ...[ReviewTile(review: r), const SizedBox(height: MuSpace.s3)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
