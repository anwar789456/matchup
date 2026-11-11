import 'package:sqflite/sqflite.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import 'matches_models.dart';

/// Booking objects ⇄ rows of `reservations`, `reservation_joueurs` and `annulations`
/// (lib/core/db/app_database.dart). Dates are stored as ISO 8601 text, enums by name.
abstract final class BookingRows {
  static String? _date(DateTime? d) => d?.toIso8601String();
  static DateTime? _parse(Object? v) => v == null ? null : DateTime.parse(v as String);

  static Map<String, Object?> booking(MuBooking b, String reference) => {
        'reference': reference,
        'sport': b.sport.name,
        'etablissement': b.venue,
        'terrain': b.court,
        'lieu': b.place,
        'debut': _date(b.start),
        'fin': _date(b.end),
        'part': b.share,
        'statut': b.status.name,
        'payer_avant': _date(b.payBefore),
        'remboursement': b.refund,
        'cree_le': _date(DateTime.now()),
      };

  /// Writes [b] and its players under [reference].
  static Future<void> insert(DatabaseExecutor db, MuBooking b, String reference) async {
    await db.insert('reservations', booking(b, reference));
    for (final (i, p) in b.players.indexed) {
      await db.insert('reservation_joueurs', {
        'reference': reference,
        'position': i,
        'nom': p.name,
        'image_url': p.imageUrl,
      });
    }
  }

  static Future<void> insertCancellation(DatabaseExecutor db, CancelledBooking c) =>
      db.insert('annulations', {
        'reference': c.booking.id,
        'annule_par': c.cancelledBy.name,
        'par_moi': c.byMe ? 1 : 0,
        'raison': c.reason,
        'rembourse_le': _date(c.refundedAt),
        'remboursement': c.refund,
        'joueurs_rembourses': c.playersRefunded,
        'total_rembourse': c.totalRefund,
      });

  /// The bookings of [rows] with their players, in the rows' order.
  static Future<List<MuBooking>> read(DatabaseExecutor db, List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return const [];
    final refs = [for (final r in rows) r['reference'] as String];
    final players = await db.query(
      'reservation_joueurs',
      where: 'reference IN (${List.filled(refs.length, '?').join(', ')})',
      whereArgs: refs,
      orderBy: 'position',
    );
    final byRef = <String, List<MuPerson>>{};
    for (final p in players) {
      (byRef[p['reference'] as String] ??= [])
          .add(MuPerson(p['nom'] as String, imageUrl: p['image_url'] as String?));
    }
    return [
      for (final r in rows)
        MuBooking(
          id: r['reference'] as String,
          sport: MuSport.values.byName(r['sport'] as String),
          venue: r['etablissement'] as String,
          court: r['terrain'] as String?,
          place: r['lieu'] as String,
          start: _parse(r['debut'])!,
          end: _parse(r['fin'])!,
          share: r['part'] as num,
          status: MuBookingStatus.values.byName(r['statut'] as String),
          payBefore: _parse(r['payer_avant']),
          refund: r['remboursement'] as num?,
          players: byRef[r['reference']] ?? const [],
        ),
    ];
  }

  /// A row joined from `reservations` and `annulations`, back to a [CancelledBooking].
  static CancelledBooking cancellation(Map<String, Object?> row, MuBooking booking) =>
      CancelledBooking(
        booking: booking,
        cancelledBy: MuPerson(row['annule_par'] as String),
        byMe: row['par_moi'] == 1,
        reason: row['raison'] as String?,
        refundedAt: _parse(row['rembourse_le'])!,
        refund: row['remboursement'] as num,
        playersRefunded: row['joueurs_rembourses'] as int,
        totalRefund: row['total_rembourse'] as num?,
      );
}
