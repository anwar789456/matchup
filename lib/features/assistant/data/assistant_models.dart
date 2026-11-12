import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show IconData;

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';

/// Which space opened the assistant: the player (AI-01…06) or a venue owner (AI-07).
enum AssistantSpace { player, owner }

/// A piece of an answer, drawn in order under « MatchUp · IA ».
@immutable
sealed class AiBlock {
  const AiBlock();
}

/// A paragraph on `ai-soft`.
class AiText extends AiBlock {
  const AiText(this.text);
  final String text;
}

/// One free slot of [AiSlots] (« 20h00 · Terrain 2 »).
@immutable
class AiSlot {
  const AiSlot({required this.start, required this.court, this.indoor = false});
  final DateTime start;
  final String court;
  final bool indoor;
}

/// AI-02: the free slots of a venue, one picked (« Réserver 20h00 »).
class AiSlots extends AiBlock {
  const AiSlots({
    required this.venueId,
    required this.sport,
    required this.venue,
    required this.place,
    required this.rating,
    required this.reviews,
    required this.distanceKm,
    required this.surface,
    required this.slots,
    required this.picked,
    required this.price,
    required this.players,
    required this.reason,
  });

  final String venueId;
  final MuSport sport;
  final String venue;
  final String place;
  final double rating;
  final int reviews;
  final double distanceKm;

  /// « synthétique, extérieur, éclairé » (AI-03).
  final String surface;
  final List<AiSlot> slots;
  final int picked;

  /// The court for an hour, split between [players].
  final num price;
  final int players;
  final String reason;

  AiSlot get slot => slots[picked];
  num get share => price / players;

  AiSlots pick(int i) => AiSlots(
    venueId: venueId,
    sport: sport,
    venue: venue,
    place: place,
    rating: rating,
    reviews: reviews,
    distanceKm: distanceKm,
    surface: surface,
    slots: slots,
    picked: i,
    price: price,
    players: players,
    reason: reason,
  );
}

/// An open game to join, with its match fit (AI-02, AI-05).
class AiGame extends AiBlock {
  const AiGame({required this.game, required this.factors});
  final MuGame game;
  final List<MuFitFactor> factors;
}

/// AI-05 « Aucune partie ouverte … » (the search that found nothing).
class AiNothingFound extends AiBlock {
  const AiNothingFound(this.text, this.bold);
  final String text;

  /// The bold lead (« Aucune partie ouverte »).
  final String bold;
}

/// AI-05: « Crée ta partie demain à 19h30 » on a free court.
class AiCreateGame extends AiBlock {
  const AiCreateGame({
    required this.venueId,
    required this.sport,
    required this.start,
    required this.minutes,
    required this.venue,
    required this.meta,
    required this.price,
    required this.players,
    required this.reason,
  });

  final String venueId;
  final MuSport sport;
  final DateTime start;
  final int minutes;

  /// « Smash Padel Club · Court 1 ».
  final String venue;

  /// « Lac 2 · 3,1 km · indoor ».
  final String meta;
  final num price;
  final int players;
  final String reason;
}

/// AI-05 « Préviens-moi si ça s’ouvre ».
class AiAlert extends AiBlock {
  const AiAlert(this.detail);

  /// « Padel · sam. 17 oct. · soir · 3,0–4,0 ».
  final String detail;
}

/// Follow-up chips: each sends its text as a new request.
class AiFollowUps extends AiBlock {
  const AiFollowUps(this.items);
  final List<(IconData, String)> items;
}

/// AI-03: what « Confirmer » books and pays (nothing happens before).
class AiConfirm extends AiBlock {
  const AiConfirm(this.slots);
  final AiSlots slots;
}

/// AI-04: the court already found while the search goes on.
class AiFound extends AiBlock {
  const AiFound({
    required this.sport,
    required this.venue,
    required this.when,
    required this.meta,
    required this.price,
    required this.players,
  });

  final MuSport sport;
  final String venue;
  final String when;
  final String meta;
  final num price;
  final int players;
}

/// Training programs to open (ENT-03).
class AiPrograms extends AiBlock {
  const AiPrograms(this.ids);
  final List<String> ids;
}

/// AI-07: a bar chart (fill rate by slot).
class AiChart extends AiBlock {
  const AiChart({
    required this.title,
    required this.subtitle,
    required this.categories,
    required this.values,
  });

  final String title;
  final String subtitle;
  final List<String> categories;

  /// Percentages.
  final List<double> values;
}

/// AI-07: a price change to prepare (OWN-16), never applied without the owner.
class AiPromo extends AiBlock {
  const AiPromo({
    required this.weekday,
    required this.fromHour,
    required this.toHour,
    required this.percent,
    required this.priceBefore,
    required this.slots,
    required this.date,
    required this.players,
    required this.title,
    required this.reason,
  });

  final int weekday;
  final int fromHour;
  final int toHour;
  final int percent;
  final num priceBefore;
  final int slots;
  final DateTime date;
  final int players;
  final String title;
  final String reason;

  num get priceAfter => priceBefore * (100 - percent) / 100;
}

/// What the assistant understood (« Padel », « sam. 17 oct. · 18h–23h »…).
typedef AiUnderstood = List<(IconData, String)>;

/// An answer being written: the steps of AI-04, then the blocks.
@immutable
class AiAnswer {
  const AiAnswer({
    this.understood = const [],
    this.blocks = const [],
    this.searching,
    this.steps = const [],
    this.step = 0,
    this.found,
    this.note,
  });

  final AiUnderstood understood;
  final List<AiBlock> blocks;

  /// « Je cherche ta partie de padel » while the steps run (null once done).
  final String? searching;
  final List<String> steps;
  final int step;

  /// AI-04 « Déjà trouvé · 1 court libre ».
  final AiFound? found;

  /// The disclaimer under the feedback (« Vérifie avant de confirmer. »).
  final String? note;
}

enum TurnStatus { writing, done, failed, stopped }

/// One turn of the thread.
@immutable
sealed class AssistantTurn {
  const AssistantTurn(this.id, this.at);
  final int id;
  final DateTime at;
}

class UserTurn extends AssistantTurn {
  const UserTurn(super.id, super.at, this.text);
  final String text;
}

class AiTurn extends AssistantTurn {
  const AiTurn(
    super.id,
    super.at, {
    required this.request,
    this.answer = const AiAnswer(),
    this.status = TurnStatus.writing,
    this.feedback,
    this.dismissed = const {},
    this.offline = false,
  });

  /// The question it answers (kept to « Réessayer »).
  final String request;
  final AiAnswer answer;
  final TurnStatus status;
  final bool? feedback;

  /// Blocks closed with ✕ or « Ignorer ».
  final Set<int> dismissed;

  /// Failed because the network dropped (AI-06 banner).
  final bool offline;

  AiTurn copyWith({
    AiAnswer? answer,
    TurnStatus? status,
    bool? Function()? feedback,
    Set<int>? dismissed,
    bool? offline,
  }) => AiTurn(
    id,
    at,
    request: request,
    answer: answer ?? this.answer,
    status: status ?? this.status,
    feedback: feedback == null ? this.feedback : feedback(),
    dismissed: dismissed ?? this.dismissed,
    offline: offline ?? this.offline,
  );
}

/// « Ce que j’utilise pour te répondre » (AI-01).
@immutable
class AiContextItem {
  const AiContextItem(this.icon, this.title, this.detail);
  final IconData icon;
  final String title;
  final String detail;
}

/// The empty assistant: greeting, suggestions, what it uses.
@immutable
class AiWelcome {
  const AiWelcome({required this.greeting, required this.suggestions, required this.context});
  final String greeting;
  final List<String> suggestions;
  final List<AiContextItem> context;
}
