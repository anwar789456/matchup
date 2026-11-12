import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import 'matches_models.dart';

/// Someone else holds or booked the slot (Supabase's no-overlap rule, error 23P01).
class SlotTaken implements Exception {
  const SlotTaken();

  @override
  String toString() => 'SlotTaken';
}

/// A slot taken at a venue, by anyone (the slot grid does not say by whom).
@immutable
class TakenSlot {
  const TakenSlot({required this.court, required this.start, required this.end});

  final String court;
  final DateTime start;
  final DateTime end;
}

/// A booking as Supabase keeps it: the booking and, when cancelled, its cancellation.
typedef RemoteBooking = ({MuBooking booking, CancelledBooking? cancellation});

/// Where booked courts live for everyone (supabase/reservation.sql). [SupabaseReservationRemote]
/// in the app, a map in tests.
abstract interface class ReservationRemote {
  /// « MU-50001 », unique across every phone.
  Future<String> nextReference();

  /// Holds [booking]'s slot for 15 minutes before the checkout. Throws [SlotTaken].
  Future<void> hold(MuBooking booking);

  /// After payment: the hold becomes the booking, with its players. Throws [SlotTaken].
  Future<void> confirm(MuBooking booking);

  Future<void> cancel(CancelledBooking cancellation);

  /// The signed-in player's bookings (paid or cancelled), by date.
  Future<List<RemoteBooking>> mine();

  /// Slots of [venue] taken by anyone between [from] and [to].
  Future<List<TakenSlot>> taken(String venue, DateTime from, DateTime to);
}

/// Dates go to Supabase in UTC (timestamptz) and come back in the phone's time zone.
String _utc(DateTime d) => d.toUtc().toIso8601String();
DateTime _local(Object? v) => DateTime.parse(v! as String).toLocal();

class SupabaseReservationRemote implements ReservationRemote {
  SupabaseClient get _client => Supabase.instance.client;

  static Map<String, Object?> _row(MuBooking b) => {
        'reference': b.id,
        'sport': b.sport.name,
        'etablissement': b.venue,
        'terrain': b.court ?? b.venue,
        'lieu': b.place,
        'debut': _utc(b.start),
        'fin': _utc(b.end),
        'part': b.share,
      };

  /// Runs [call], turning the no-overlap error into [SlotTaken].
  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PostgrestException catch (e) {
      if (e.code == '23P01') throw const SlotTaken();
      rethrow;
    }
  }

  @override
  Future<String> nextReference() async => await _client.rpc('prochaine_reference') as String;

  @override
  Future<void> hold(MuBooking booking) =>
      _guard(() => _client.rpc('bloquer_creneau', params: {'r': _row(booking)}));

  @override
  Future<void> confirm(MuBooking booking) => _guard(() => _client.rpc(
        'confirmer_reservation',
        params: {
          'r': _row(booking),
          'joueurs': [
            for (final (i, p) in booking.players.indexed)
              {'position': i, 'nom': p.name, 'image_url': p.imageUrl},
          ],
        },
      ));

  @override
  Future<void> cancel(CancelledBooking c) async {
    await _client.from('reservations').update({
      'statut': MuBookingStatus.cancelled.name,
      'annule_par': c.cancelledBy.name,
      'par_moi': c.byMe,
      'raison': c.reason,
      'rembourse_le': _utc(c.refundedAt),
      'remboursement': c.refund,
      'joueurs_rembourses': c.playersRefunded,
      'total_rembourse': c.totalRefund,
    }).eq('reference', c.booking.id!);
  }

  @override
  Future<List<RemoteBooking>> mine() async {
    // Only the player's own: an owner may also read the bookings made at their venue.
    final rows = await _client
        .from('reservations')
        .select('*, reservation_joueurs(position, nom, image_url)')
        .eq('organisateur_id', _client.auth.currentUser!.id)
        .neq('statut', MuBookingStatus.pendingPayment.name)
        .order('debut');
    return [for (final r in rows) readRemote(r)];
  }

  /// A `reservations` row (with its `reservation_joueurs`) as the app's booking.
  static RemoteBooking readRemote(Map<String, Object?> r) {
    final players = [...(r['reservation_joueurs'] as List? ?? const [])]
      ..sort((a, b) => ((a as Map)['position'] as int).compareTo((b as Map)['position'] as int));
    final booking = MuBooking(
      id: r['reference']! as String,
      sport: MuSport.values.byName(r['sport']! as String),
      venue: r['etablissement']! as String,
      court: r['terrain'] as String?,
      place: r['lieu']! as String,
      start: _local(r['debut']),
      end: _local(r['fin']),
      share: r['part']! as num,
      status: MuBookingStatus.values.byName(r['statut']! as String),
      refund: r['remboursement'] as num?,
      players: [
        for (final p in players)
          MuPerson((p as Map)['nom'] as String, imageUrl: p['image_url'] as String?),
      ],
    );
    final cancelled = booking.status == MuBookingStatus.cancelled && r['rembourse_le'] != null;
    return (
      booking: booking,
      cancellation: cancelled
          ? CancelledBooking(
              booking: booking,
              cancelledBy: MuPerson(r['annule_par'] as String? ?? ''),
              byMe: r['par_moi'] == true,
              reason: r['raison'] as String?,
              refundedAt: _local(r['rembourse_le']),
              refund: r['remboursement'] as num? ?? booking.share,
              playersRefunded: r['joueurs_rembourses'] as int? ?? 1,
              totalRefund: r['total_rembourse'] as num?,
            )
          : null,
    );
  }

  @override
  Future<List<TakenSlot>> taken(String venue, DateTime from, DateTime to) async {
    final rows = await _client.rpc('creneaux_pris', params: {
      'p_etablissement': venue,
      'p_de': _utc(from),
      'p_a': _utc(to),
    }) as List;
    return [
      for (final r in rows)
        TakenSlot(
          court: (r as Map)['terrain'] as String,
          start: _local(r['debut']),
          end: _local(r['fin']),
        ),
    ];
  }
}
