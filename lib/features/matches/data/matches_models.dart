import 'package:flutter/foundation.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';

/// A teammate or opponent to rate after a match (MAT-08).
@immutable
class MatchMate {
  const MatchMate({
    required this.person,
    required this.role,
    required this.announcedLevel,
    this.partner = false,
  });

  final MuPerson person;

  /// « Ta partenaire · côté droit », « Adversaire ».
  final String role;
  final double announcedLevel;
  final bool partner;
}

/// A played match in « Passés » (MAT-02).
@immutable
class PastMatch {
  const PastMatch({
    required this.id,
    required this.sport,
    required this.date,
    required this.venue,
    required this.court,
    required this.match,
    required this.mates,
    this.rated = false,
    this.sets,
    this.scoreConfirmed = true,
  });

  final String id;
  final MuSport sport;
  final DateTime date;
  final String venue;
  final String? court;
  final MuMatch match;
  final List<MatchMate> mates;
  final bool rated;

  /// Padel sets (home, away), once a score was given.
  final List<(int, int)>? sets;
  final bool scoreConfirmed;

  /// The player's side won.
  bool get won {
    final w = match.winner;
    if (w == null) return false;
    return match.teams[w].you;
  }
}

/// A cancelled booking or game with its refund (MAT-03).
@immutable
class CancelledBooking {
  const CancelledBooking({
    required this.booking,
    required this.cancelledBy,
    required this.refundedAt,
    required this.refund,
    this.reason,
    this.byMe = false,
    this.playersRefunded = 1,
    this.totalRefund,
  });

  final MuBooking booking;
  final MuPerson cancelledBy;
  final String? reason;
  final DateTime refundedAt;

  /// The player's share back on the balance.
  final num refund;
  final bool byMe;
  final int playersRefunded;
  final num? totalRefund;
}

/// One line of the payments card of a booking (MAT-05).
@immutable
class BookingPayment {
  const BookingPayment({
    required this.person,
    required this.amount,
    this.paidAt,
    this.organizer = false,
    this.you = false,
  });

  final MuPerson person;
  final num amount;
  final DateTime? paidAt;
  final bool organizer;
  final bool you;

  bool get paid => paidAt != null;
}

/// The booking page (MAT-05): the lineup, who paid, the chat, the venue.
@immutable
class BookingDetails {
  const BookingDetails({
    required this.booking,
    required this.venue,
    required this.teams,
    required this.payments,
    required this.courtPrice,
    required this.messages,
    this.levelMin,
    this.levelMax,
    this.gameType = 'mixte',
    this.isPublic = true,
    this.organizer = true,
    this.lit = true,
    this.unreadMessages = 0,
    this.venueNote = 'Vestiaires · douches · parking · chasubles fournies. Arrive 10 min avant.',
    this.spotsTotal = 10,
  });

  final MuBooking booking;
  final MuVenue venue;
  final List<MuLineupTeam> teams;
  final List<BookingPayment> payments;
  final num courtPrice;
  final List<({MuPerson author, DateTime time, String text})> messages;
  final double? levelMin;
  final double? levelMax;
  final String gameType;
  final bool isPublic;

  /// The player organises it (« tu organises »).
  final bool organizer;
  final bool lit;
  final int unreadMessages;
  final String venueNote;
  final int spotsTotal;

  int get playersIn => booking.players.length;
  int get openSpots => spotsTotal - playersIn;
  num get received => payments.where((p) => p.paid).fold<num>(0, (a, p) => a + p.amount);

  /// Free cancellation until 24 h before, half until 6 h before.
  DateTime get freeUntil => booking.start.subtract(const Duration(hours: 24));
  DateTime get halfUntil => booking.start.subtract(const Duration(hours: 6));

  double get averageLevel {
    final levels = [
      for (final t in teams)
        for (final p in t.players)
          if (p?.level != null) p!.level!,
    ];
    if (levels.isEmpty) return 0;
    return levels.reduce((a, b) => a + b) / levels.length;
  }
}

/// What the player says about a mate after a match (MAT-08).
enum LevelVerdict { below, asAnnounced, above }

@immutable
class MateRating {
  const MateRating({required this.person, this.level, this.fairPlay = 0, this.absent = false});

  final MuPerson person;
  final LevelVerdict? level;

  /// 0–5 stars.
  final int fairPlay;
  final bool absent;
}
