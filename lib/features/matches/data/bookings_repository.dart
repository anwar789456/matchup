import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import 'matches_models.dart';

export 'matches_models.dart';

/// An invitation to a game, waiting for an answer (« Mariem K. t’invite au padel »).
@immutable
class MatchInvitation {
  const MatchInvitation({
    required this.id,
    required this.from,
    required this.sport,
    required this.venue,
    required this.place,
    required this.start,
    required this.share,
    required this.spotsTotal,
    required this.spotsLeft,
  });

  final String id;
  final MuPerson from;
  final MuSport sport;
  final String venue;
  final String place;
  final DateTime start;

  /// The share per person, « 25 DT /pers. ».
  final num share;
  final int spotsTotal;
  final int spotsLeft;
}

/// What « À venir » shows: invitations first, then the games the player joined and the courts
/// they booked, by date.
@immutable
class UpcomingMatches {
  const UpcomingMatches({required this.invitations, required this.bookings, this.games = const []});

  final List<MatchInvitation> invitations;

  /// Games joined (« Tu joues »), status joined.
  final List<MuGame> games;

  /// Courts booked (« Tu organises »).
  final List<MuBooking> bookings;

  /// Games and bookings together, by date — a game as the booking card shows it.
  List<MuBooking> get all =>
      [...bookings, for (final g in games) bookingOf(g)]
        ..sort((a, b) => a.start.compareTo(b.start));

  int get count => invitations.length + games.length + bookings.length;

  static MuBooking bookingOf(MuGame g) => MuBooking(
    id: g.id,
    sport: g.sport,
    venue: g.venue,
    court: g.court,
    place: g.place,
    start: g.start,
    end: g.start.add(const Duration(hours: 1)),
    share: g.pricePerPlayer,
    players: g.players,
  );
}

/// The player's bookings and games (« Mes matchs »).
abstract interface class BookingsRepository {
  /// Invitations and the courts booked; the games joined come from the games repository.
  Future<UpcomingMatches> upcoming();

  /// Saves a paid booking; returns it with its reference (« MU-48214 »).
  Future<MuBooking> add(MuBooking booking);

  /// The reference the next booking will get (its share link exists before the payment).
  Future<String> nextReference();

  Future<BookingDetails> details(String id);

  /// Cancels a booking the player organises: everyone is refunded to their balance.
  Future<CancelledBooking> cancel(String id);

  Future<List<PastMatch>> past();
  Future<List<CancelledBooking>> cancelled();

  /// Accepts or declines an invitation; accepted, the game joins « À venir ».
  Future<void> respond(String invitationId, {required bool accept});

  Future<void> rate(String matchId, List<MateRating> ratings);
  Future<void> submitScore(String matchId, List<(int, int)> sets);
}

/// The story's « Mes matchs » (design/screens/STORY-DATA.md): Mariem's invitation, MU-48213,
/// three played matches and the game Skander cancelled; then what happens in the app, in memory.
class FakeBookingsRepository implements BookingsRepository {
  FakeBookingsRepository({this.latency = const Duration(milliseconds: 700)});

  final Duration latency;
  final _bookings = [Story.myBooking];
  final _accepted = <MuGame>[];
  final _cancelled = <CancelledBooking>[_storyCancelled];
  final _rated = <String>{};
  final _scores = <String, List<(int, int)>>{};
  var _invitations = [
    MatchInvitation(
      id: 'inv-mariem',
      from: Story.invitation.from,
      sport: Story.invitation.sport,
      venue: Story.invitation.venue,
      place: 'Lac 2',
      start: Story.invitation.start,
      share: Story.invitation.share,
      spotsTotal: Story.invitation.spotsTotal,
      spotsLeft: Story.invitation.spotsLeft,
    ),
  ];

  // References follow the story's MU-48213.
  static const int _firstRef = 48213;

  static const _levels = <String, double>{
    'Skander T.': 4.0,
    'Hamza R.': 3.5,
    'Nour A.': 3.0,
    'Aziz H.': 4.5,
    'Omar D.': 3.5,
    'Yassine B.': 3.0,
  };

  /// Skander's game of sam. 10 oct., cancelled the day before.
  static final _storyCancelled = CancelledBooking(
    booking: MuBooking(
      id: 'g-cancelled-oct10',
      sport: MuSport.football,
      venue: 'Arena Five',
      court: 'Terrain 2',
      place: 'La Marsa',
      start: Story.at(10, 20),
      end: Story.at(10, 21),
      share: 15,
      status: MuBookingStatus.cancelled,
      refund: 15,
      players: const [Story.skander, Story.hamza, Story.aziz, Story.yassine],
    ),
    cancelledBy: Story.skander,
    reason: 'Pas assez de joueurs confirmés, désolé !',
    refundedAt: Story.at(9, 14, 12),
    refund: 15,
  );

  static final _storyPast = <PastMatch>[
    PastMatch(
      id: 'pm-padel-oct9',
      sport: MuSport.padel,
      date: Story.at(9, 19),
      venue: 'Smash Padel Club',
      court: 'Court 3',
      match: const MuMatch(
        sport: MuSport.padel,
        status: MuMatchStatus.finished,
        round: 'Ven. 9 oct.',
        court: 'Smash Padel Club',
        teams: [
          MuMatchTeam(
            name: 'Yassine B. / Mariem K.',
            shortName: 'Toi / Mariem',
            monogram: 'YM',
            sets: [6, 6],
            you: true,
          ),
          MuMatchTeam(
            name: 'Ines M. / Nour A.',
            shortName: 'Ines / Nour',
            monogram: 'IN',
            sets: [4, 3],
          ),
        ],
      ),
      mates: const [
        MatchMate(
          person: Story.mariem,
          role: 'Ta partenaire · côté droit',
          announcedLevel: 4.0,
          partner: true,
        ),
        MatchMate(person: Story.ines, role: 'Adversaire', announcedLevel: 4.0),
        MatchMate(person: Story.nour, role: 'Adversaire', announcedLevel: 3.0),
      ],
      sets: const [(6, 4), (6, 3)],
    ),
    PastMatch(
      id: 'pm-foot-oct3',
      sport: MuSport.football,
      date: Story.at(3, 20),
      venue: 'Arena Five',
      court: 'Terrain 2',
      rated: true,
      match: const MuMatch(
        sport: MuSport.football,
        status: MuMatchStatus.finished,
        round: 'Sam. 3 oct.',
        court: 'Arena Five',
        teams: [
          MuMatchTeam(
            name: 'Blancs · ton équipe',
            shortName: 'Toi',
            monogram: 'BL',
            score: 5,
            you: true,
          ),
          MuMatchTeam(name: 'Bleus', monogram: 'BE', score: 7),
        ],
      ),
      mates: const [],
    ),
    PastMatch(
      id: 'pm-basket-sep27',
      sport: MuSport.basketball,
      date: DateTime(2026, 9, 27, 18),
      venue: 'Hoop Zone',
      court: 'Terrain A',
      rated: true,
      match: const MuMatch(
        sport: MuSport.basketball,
        status: MuMatchStatus.finished,
        round: 'Dim. 27 sept.',
        court: 'Hoop Zone',
        teams: [
          MuMatchTeam(name: 'Noirs', shortName: 'Toi', monogram: 'NO', score: 21, you: true),
          MuMatchTeam(name: 'Oranges', monogram: 'OR', score: 16),
        ],
      ),
      mates: const [],
    ),
  ];

  @override
  Future<UpcomingMatches> upcoming() async {
    await Future<void>.delayed(latency);
    return UpcomingMatches(
      invitations: [..._invitations],
      games: [..._accepted],
      bookings: [..._bookings]..sort((a, b) => a.start.compareTo(b.start)),
    );
  }

  @override
  Future<String> nextReference() async {
    final used = [
      for (final b in [..._bookings, for (final c in _cancelled) c.booking])
        if (b.id != null && b.id!.startsWith('MU-')) int.tryParse(b.id!.substring(3)) ?? 0,
    ];
    return 'MU-${used.fold(_firstRef - 1, (a, b) => a > b ? a : b) + 1}';
  }

  @override
  Future<MuBooking> add(MuBooking booking) async {
    final ref = booking.id ?? await nextReference();
    final saved = MuBooking(
      id: ref,
      sport: booking.sport,
      venue: booking.venue,
      court: booking.court,
      place: booking.place,
      start: booking.start,
      end: booking.end,
      share: booking.share,
      status: booking.status,
      payBefore: booking.payBefore,
      players: booking.players,
    );
    _bookings.add(saved);
    return saved;
  }

  MuBooking? _booking(String id) {
    for (final b in _bookings) {
      if (b.id == id) return b;
    }
    return null;
  }

  @override
  Future<BookingDetails> details(String id) async {
    await Future<void>.delayed(latency);
    final b = _booking(id);
    if (b == null) throw StateError('Réservation introuvable : $id');
    final venue = Story.venues.firstWhere(
      (v) => v.name == b.venue,
      orElse: () => Story.venues.first,
    );
    MuLineupPlayer player(MuPerson p) => MuLineupPlayer(
      p.name,
      level: _levels[p.name] ?? 3.0,
      role: p.name == Story.myName ? MuLineupRole.organizer : null,
      you: p.name == Story.myName,
    );
    final List<MuLineupTeam> teams;
    if (id == Story.myBooking.id) {
      // MAT-05: Blancs 4/5 · Bleus 2/5.
      teams = [
        MuLineupTeam(
          name: 'Blancs',
          players: [
            player(Story.hamza),
            player(Story.nour),
            null,
            player(Story.skander),
            player(Story.yassine),
          ],
        ),
        MuLineupTeam(
          name: 'Bleus',
          players: [null, player(Story.omar), null, player(Story.aziz), null],
        ),
      ];
    } else {
      final sides = [List<MuLineupPlayer?>.filled(5, null), List<MuLineupPlayer?>.filled(5, null)];
      var i = 0;
      for (final p in b.players) {
        if (i >= 10) break;
        sides[i % 2][i ~/ 2] = player(p);
        i++;
      }
      teams = [
        MuLineupTeam(name: 'Blancs', players: sides[0]),
        MuLineupTeam(name: 'Bleus', players: sides[1]),
      ];
    }
    final isStory = id == Story.myBooking.id;
    return BookingDetails(
      booking: b,
      venue: venue,
      teams: teams,
      courtPrice: b.share * 10,
      levelMin: 2.5,
      levelMax: 4.0,
      payments: [
        for (final p in b.players)
          BookingPayment(
            person: p,
            amount: b.share,
            paidAt: Story.at(16, 18, 2),
            organizer: p.name == Story.myName,
            you: p.name == Story.myName,
          ),
      ],
      messages: isStory
          ? [
              (
                author: Story.skander,
                time: Story.at(16, 17, 42),
                text: 'Je ramène un ballon neuf. On se retrouve au parking ?',
              ),
              (
                author: Story.hamza,
                time: Story.at(16, 17, 50),
                text: 'Je prends les gants, je serai gardien.',
              ),
            ]
          : const [],
      unreadMessages: isStory ? 2 : 0,
    );
  }

  @override
  Future<CancelledBooking> cancel(String id) async {
    await Future<void>.delayed(latency);
    final b = _booking(id);
    if (b == null) throw StateError('Réservation introuvable : $id');
    _bookings.remove(b);
    final c = CancelledBooking(
      booking: MuBooking(
        id: b.id,
        sport: b.sport,
        venue: b.venue,
        court: b.court,
        place: b.place,
        start: b.start,
        end: b.end,
        share: b.share,
        status: MuBookingStatus.cancelled,
        refund: b.share,
        players: b.players,
      ),
      cancelledBy: Story.yassine,
      byMe: true,
      refundedAt: DateTime.now(),
      refund: b.share,
      playersRefunded: b.players.length,
      totalRefund: b.share * b.players.length,
    );
    _cancelled.insert(0, c);
    return c;
  }

  @override
  Future<List<PastMatch>> past() async {
    await Future<void>.delayed(latency);
    return [
      for (final m in _storyPast)
        PastMatch(
          id: m.id,
          sport: m.sport,
          date: m.date,
          venue: m.venue,
          court: m.court,
          match: m.match,
          mates: m.mates,
          rated: m.rated || _rated.contains(m.id),
          sets: _scores[m.id] ?? m.sets,
          scoreConfirmed: !_scores.containsKey(m.id),
        ),
    ];
  }

  @override
  Future<List<CancelledBooking>> cancelled() async {
    await Future<void>.delayed(latency);
    return [..._cancelled];
  }

  @override
  Future<void> respond(String invitationId, {required bool accept}) async {
    final inv = _invitations.where((i) => i.id == invitationId).firstOrNull;
    if (inv == null) return;
    _invitations = [
      for (final i in _invitations)
        if (i.id != invitationId) i,
    ];
    if (accept) {
      _accepted.add(
        MuGame(
          id: inv.id,
          sport: inv.sport,
          venue: inv.venue,
          place: inv.place,
          start: inv.start,
          spotsTotal: inv.spotsTotal,
          spotsLeft: inv.spotsLeft - 1,
          pricePerPlayer: inv.share,
          players: [inv.from, Story.yassine],
          organiser: inv.from.name,
          status: MuGameStatus.joined,
        ),
      );
    }
  }

  @override
  Future<void> rate(String matchId, List<MateRating> ratings) async {
    await Future<void>.delayed(latency);
    _rated.add(matchId);
  }

  @override
  Future<void> submitScore(String matchId, List<(int, int)> sets) async {
    await Future<void>.delayed(latency);
    _scores[matchId] = sets;
  }
}

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) => FakeBookingsRepository());
