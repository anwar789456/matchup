import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../common/data/story_data.dart';

/// A player's review of the venue, and the venue's public reply (OWN-19).
@immutable
class VenueReview {
  const VenueReview({
    required this.id,
    required this.author,
    required this.rating,
    required this.date,
    required this.court,
    required this.text,
    this.reply,
    this.replyDate,
    this.draft,
  });

  final String id;
  final String author;

  /// 1 to 5 stars.
  final int rating;
  final DateTime date;
  final int court;
  final String text;
  final String? reply;
  final DateTime? replyDate;

  /// A reply the owner started and has not published yet.
  final String? draft;

  bool get answered => reply != null;

  VenueReview withReply(String answer, DateTime at) => VenueReview(
    id: id,
    author: author,
    rating: rating,
    date: date,
    court: court,
    text: text,
    reply: answer,
    replyDate: at,
  );
}

/// The venue's rating and its latest reviews (OWN-19 « 4,7 · 128 avis »).
@immutable
class ReviewsSummary {
  const ReviewsSummary({
    required this.average,
    required this.total,
    required this.byStars,
    required this.latest,
  });

  final double average;
  final int total;

  /// Reviews per star, 5 → 1.
  final Map<int, int> byStars;

  /// The latest reviews, newest first.
  final List<VenueReview> latest;

  /// Reviews still waiting for a reply (the older ones are all answered).
  int get unanswered => latest.where((r) => !r.answered).length;

  int get lowRated => (byStars[3] ?? 0) + (byStars[2] ?? 0) + (byStars[1] ?? 0);

  ReviewsSummary withReview(VenueReview review) => ReviewsSummary(
    average: average,
    total: total,
    byStars: byStars,
    latest: [for (final r in latest) r.id == review.id ? review : r],
  );
}

abstract interface class ReviewsRepository {
  Future<ReviewsSummary> reviews();

  /// Publishes the venue's public reply to review [id].
  Future<VenueReview> reply(String id, String text);
}

/// Arena Five's reviews (STORY-DATA: 4,7 · 128 avis).
class FakeReviewsRepository implements ReviewsRepository {
  FakeReviewsRepository({
    this.latency = const Duration(milliseconds: 300),
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => storyNow);

  final Duration latency;
  final DateTime Function() _clock;

  late ReviewsSummary _summary = ReviewsSummary(
    average: 4.7,
    total: 128,
    byStars: const {5: 100, 4: 20, 3: 5, 2: 2, 1: 1},
    latest: [
      VenueReview(
        id: 'r-omar',
        author: 'Omar D.',
        rating: 3,
        date: Story.at(15, 21),
        court: 2,
        text:
            'Vestiaires à rafraîchir : une seule douche marchait mardi soir. Le terrain, lui, est '
            'top et l’éclairage nickel.',
        draft:
            'Merci Omar pour ton retour ! La douche est réparée depuis mercredi et on rénove les '
            'vestiaires début novembre. À dimanche sur le terrain.',
      ),
      VenueReview(
        id: 'r-mariem',
        author: 'Mariem K.',
        rating: 5,
        date: Story.at(13, 22),
        court: 1,
        text:
            'Gazon impeccable, éclairage parfait pour les matchs du soir et accueil très sympa. On '
            'revient avec l’équipe des filles samedi.',
        reply: 'Merci Mariem ! Le Terrain 1 vous attend samedi à 19h00, chasubles prêtes.',
        replyDate: Story.at(14, 10),
      ),
      VenueReview(
        id: 'r-hamza',
        author: 'Hamza R.',
        rating: 4,
        date: Story.at(10, 19),
        court: 1,
        text:
            'On joue ici tous les jeudis : réservation simple, terrain prêt à l’heure. Il manque '
            'juste un peu d’eau fraîche au café.',
        reply:
            'Bien noté Hamza, le frigo du café est rempli avant chaque créneau du soir maintenant.',
        replyDate: Story.at(11, 11),
      ),
    ],
  );

  Future<void> _wait() => Future<void>.delayed(latency);

  @override
  Future<ReviewsSummary> reviews() async {
    await _wait();
    return _summary;
  }

  @override
  Future<VenueReview> reply(String id, String text) async {
    await _wait();
    final review = _summary.latest.firstWhere((r) => r.id == id).withReply(text, _clock());
    _summary = _summary.withReview(review);
    return review;
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => FakeReviewsRepository(clock: ref.watch(clockProvider)),
);

final ownerReviewsProvider = FutureProvider<ReviewsSummary>(
  (ref) => ref.watch(reviewsRepositoryProvider).reviews(),
);
