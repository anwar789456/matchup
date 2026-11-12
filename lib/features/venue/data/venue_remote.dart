import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../matches/data/reservation_remote.dart';

/// A venue as Supabase keeps it (`etablissements` + `etablissement_terrains`).
@immutable
class RemoteVenue {
  const RemoteVenue({
    required this.venue,
    required this.street,
    required this.postalAddress,
    required this.format,
    required this.surface,
    required this.courts,
    required this.opens,
    required this.closes,
    required this.slotMinutes,
    required this.players,
    required this.offPeakPrice,
    required this.peakPrice,
    required this.peakFrom,
    required this.peakTo,
    required this.eveningFrom,
  });

  final MuVenue venue;
  final String street;
  final String postalAddress;
  final String format;
  final String surface;

  /// (id, name, indoor), in order.
  final List<(String, String, bool)> courts;
  final int opens;
  final int closes;
  final int slotMinutes;
  final int players;
  final num offPeakPrice;
  final num peakPrice;
  final int peakFrom;
  final int peakTo;
  final int eveningFrom;
}

/// A slot the owner closed, as every player's grid sees it.
@immutable
class RemoteBlock {
  const RemoteBlock({
    required this.id,
    required this.court,
    required this.start,
    required this.end,
    required this.reason,
    this.note,
    this.weekly = false,
  });

  final String id;

  /// The court's name (« Terrain 2 »).
  final String court;
  final DateTime start;
  final DateTime end;
  final String reason;
  final String? note;
  final bool weekly;

  /// Whether the slot [from]–[to] on [court] falls in this block (every week, if weekly).
  bool covers(String court, DateTime from, DateTime to) {
    if (court != this.court) return false;
    if (!weekly) return from.isBefore(end) && to.isAfter(start);
    if (from.isBefore(DateTime(start.year, start.month, start.day))) return false;
    if (from.weekday != start.weekday) return false;
    int minutes(DateTime d) => d.hour * 60 + d.minute;
    return minutes(from) < minutes(end) && minutes(to) > minutes(start);
  }
}

/// The venue catalogue, closed slots and the owner's side, on Supabase
/// (supabase/reservation.sql). [SupabaseVenueRemote] in the app, a map in tests.
abstract interface class VenueRemote {
  Future<List<RemoteVenue>> venues();

  /// Closed slots of [venueId] that can touch [from]–[to] (weekly ones from before included).
  Future<List<RemoteBlock>> blocks(String venueId, DateTime from, DateTime to);

  /// The owner space opens: true when [venueId] is (or now becomes) the caller's venue.
  Future<bool> claim(String venueId);

  Future<void> saveBlock(String venueId, RemoteBlock block);
  Future<void> deleteBlock(String id);

  /// The owner's prices: per slot, off-peak and peak, and the peak hours (minutes).
  Future<void> updatePrices(String venueId, {required num offPeak, required num peak, required int peakFrom, required int peakTo});

  /// Bookings players made at the owner's venue (named [venueName]) between [from] and [to].
  Future<List<RemoteBooking>> bookingsAt(String venueName, DateTime from, DateTime to);
}

String _utc(DateTime d) => d.toUtc().toIso8601String();
DateTime _local(Object? v) => DateTime.parse(v! as String).toLocal();

class SupabaseVenueRemote implements VenueRemote {
  SupabaseClient get _client => Supabase.instance.client;

  static RemoteVenue _venue(Map<String, Object?> r) {
    final courts = [...(r['etablissement_terrains'] as List? ?? const [])]
      ..sort((a, b) => ((a as Map)['position'] as int).compareTo((b as Map)['position'] as int));
    final lat = r['latitude'] as num?;
    final lng = r['longitude'] as num?;
    return RemoteVenue(
      venue: MuVenue(
        id: r['id']! as String,
        name: r['nom']! as String,
        sports: [for (final s in r['sports']! as List) MuSport.values.byName(s as String)],
        place: r['lieu']! as String,
        distanceKm: (r['distance_km'] as num?)?.toDouble(),
        rating: (r['note'] as num?)?.toDouble(),
        reviews: r['nb_avis'] as int? ?? 0,
        verified: r['verifie'] == true,
        pricePerPerson: r['prix_joueur']! as num,
        courtPrice: r['prix_creuse'] as num?,
        position: lat == null || lng == null ? null : MuLatLng(lat.toDouble(), lng.toDouble()),
      ),
      street: r['rue']! as String,
      postalAddress: r['adresse_postale']! as String,
      format: r['format']! as String,
      surface: r['surface']! as String,
      courts: [
        for (final c in courts)
          ((c as Map)['id'] as String, c['nom'] as String, c['interieur'] == true),
      ],
      opens: r['ouvre']! as int,
      closes: r['ferme']! as int,
      slotMinutes: r['duree_creneau']! as int,
      players: r['joueurs']! as int,
      offPeakPrice: r['prix_creuse']! as num,
      peakPrice: r['prix_pointe']! as num,
      peakFrom: r['pointe_de']! as int,
      peakTo: r['pointe_a']! as int,
      eveningFrom: r['soiree_des']! as int,
    );
  }

  @override
  Future<List<RemoteVenue>> venues() async {
    final rows = await _client
        .from('etablissements')
        .select('*, etablissement_terrains(id, nom, interieur, position)')
        .order('distance_km');
    return [for (final r in rows) _venue(r)];
  }

  @override
  Future<List<RemoteBlock>> blocks(String venueId, DateTime from, DateTime to) async {
    final rows = await _client
        .from('blocages')
        .select()
        .eq('etablissement_id', venueId)
        .lt('debut', _utc(to))
        .or('hebdo.eq.true,fin.gt.${_utc(from)}');
    return [
      for (final r in rows)
        RemoteBlock(
          id: r['id']! as String,
          court: r['terrain']! as String,
          start: _local(r['debut']),
          end: _local(r['fin']),
          reason: r['motif']! as String,
          note: r['note'] as String?,
          weekly: r['hebdo'] == true,
        ),
    ];
  }

  @override
  Future<bool> claim(String venueId) async =>
      await _client.rpc('revendiquer_etablissement', params: {'p_id': venueId}) == true;

  @override
  Future<void> saveBlock(String venueId, RemoteBlock b) async {
    await _client.from('blocages').upsert({
      'id': b.id,
      'etablissement_id': venueId,
      'terrain': b.court,
      'debut': _utc(b.start),
      'fin': _utc(b.end),
      'motif': b.reason,
      'note': b.note,
      'hebdo': b.weekly,
    });
  }

  @override
  Future<void> deleteBlock(String id) async {
    await _client.from('blocages').delete().eq('id', id);
  }

  @override
  Future<void> updatePrices(
    String venueId, {
    required num offPeak,
    required num peak,
    required int peakFrom,
    required int peakTo,
  }) async {
    await _client.from('etablissements').update({
      'prix_creuse': offPeak,
      'prix_pointe': peak,
      'pointe_de': peakFrom,
      'pointe_a': peakTo,
    }).eq('id', venueId);
  }

  @override
  Future<List<RemoteBooking>> bookingsAt(String venueName, DateTime from, DateTime to) async {
    final rows = await _client
        .from('reservations')
        .select('*, reservation_joueurs(position, nom, image_url)')
        .eq('etablissement', venueName)
        .neq('statut', MuBookingStatus.pendingPayment.name)
        .gte('debut', _utc(from))
        .lt('debut', _utc(to))
        .order('debut');
    return [for (final r in rows) SupabaseReservationRemote.readRemote(r)];
  }
}

/// The catalogue and the owner's side on Supabase when supabase.json was given, none otherwise.
final venueRemoteProvider = Provider<VenueRemote?>(
  (ref) => SupabaseConfig.configured ? SupabaseVenueRemote() : null,
);
