import 'package:flutter/foundation.dart';

import '../../../ui/ui.dart';

/// Where the player stands with an open game.
enum GameMembership { none, joined, waitlisted }

/// One message of the game's discussion.
@immutable
class GameMessage {
  const GameMessage({required this.author, required this.time, required this.text});

  final MuPerson author;
  final DateTime time;
  final String text;
}

/// Everything the game page (GAM-01 / GAM-02) shows beyond the card: the two teams, the chat, the
/// AI's reasons, the waitlist and the player's membership.
@immutable
class GameDetails {
  const GameDetails({
    required this.game,
    required this.venue,
    required this.teams,
    required this.messages,
    required this.messageCount,
    required this.fitFactors,
    required this.fitNote,
    required this.membership,
    this.waitlistCount = 0,
    this.waitlistPosition,
    this.joinedTeam,
    this.joinedSlot,
    this.arrivalNote = 'Chasubles fournies, vestiaires et douches.',
  });

  final MuGame game;
  final MuVenue venue;
  final List<MuLineupTeam> teams;
  final List<GameMessage> messages;

  /// « 14 messages » — more than the two previewed.
  final int messageCount;
  final List<MuFitFactor> fitFactors;

  /// « Recommandé car … L’IA peut se tromper. »
  final String fitNote;
  final GameMembership membership;
  final int waitlistCount;

  /// 1-based, when waitlisted.
  final int? waitlistPosition;
  final int? joinedTeam;
  final int? joinedSlot;
  final String arrivalNote;

  /// The court price: the share times the places.
  num get courtPrice => game.pricePerPlayer * game.spotsTotal;

  /// Free cancellation until 24 h before, half until 6 h before.
  DateTime get freeUntil => game.start.subtract(const Duration(hours: 24));
  DateTime get halfUntil => game.start.subtract(const Duration(hours: 6));
  DateTime get end => game.start.add(const Duration(hours: 1));

  /// The average level of the players in the teams, « 3,6 ».
  double get averageLevel {
    final levels = [
      for (final t in teams)
        for (final p in t.players)
          if (p?.level != null) p!.level!,
    ];
    if (levels.isEmpty) return 0;
    return levels.reduce((a, b) => a + b) / levels.length;
  }

  int get playersIn => game.spotsTotal - game.spotsLeft;
}
