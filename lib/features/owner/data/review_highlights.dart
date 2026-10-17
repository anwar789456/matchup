import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/data/story_data.dart';

/// One of the venue's latest reviews, as OWN-10 « Derniers avis » shows it.
@immutable
class OwnerReviewHighlight {
  const OwnerReviewHighlight({
    required this.author,
    required this.court,
    required this.date,
    required this.stars,
    required this.text,
    this.answeredAt,
  });

  final String author;
  final int court;
  final DateTime date;
  final int stars;
  final String text;

  /// When the owner answered; null while it waits for an answer.
  final DateTime? answeredAt;
}

/// The venue's rating and its latest reviews (OWN-10).
@immutable
class OwnerReviewHighlights {
  const OwnerReviewHighlights({
    required this.average,
    required this.count,
    required this.unanswered,
    required this.latest,
  });

  final double average;
  final int count;
  final int unanswered;

  /// Unanswered first, then the latest.
  final List<OwnerReviewHighlight> latest;
}

/// Until a backend exists [FakeReviewHighlightsRepository] serves Arena Five's story.
abstract interface class ReviewHighlightsRepository {
  Future<OwnerReviewHighlights> highlights();
}

class FakeReviewHighlightsRepository implements ReviewHighlightsRepository {
  FakeReviewHighlightsRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;

  @override
  Future<OwnerReviewHighlights> highlights() async {
    await Future<void>.delayed(latency);
    return OwnerReviewHighlights(
      average: 4.7,
      count: 128,
      unanswered: 1,
      latest: [
        OwnerReviewHighlight(
          author: 'Omar D.',
          court: 2,
          date: Story.at(15, 21),
          stars: 3,
          text: 'Vestiaires à rafraîchir, l’eau chaude manquait après 21h. Le terrain reste top.',
        ),
        OwnerReviewHighlight(
          author: 'Mariem K.',
          court: 1,
          date: Story.at(13, 20),
          stars: 5,
          text: 'Gazon impeccable et éclairage parfait le soir. Accueil au top, on revient jeudi.',
          answeredAt: Story.at(14, 10),
        ),
      ],
    );
  }
}

final reviewHighlightsRepositoryProvider = Provider<ReviewHighlightsRepository>(
  (ref) => FakeReviewHighlightsRepository(),
);

final ownerReviewHighlightsProvider = FutureProvider<OwnerReviewHighlights>(
  (ref) => ref.watch(reviewHighlightsRepositoryProvider).highlights(),
);
