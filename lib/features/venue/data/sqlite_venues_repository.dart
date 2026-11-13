import 'package:sqflite/sqflite.dart';

import '../../../core/connectivity.dart';
import '../../../core/db/app_database.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import 'venues_repository.dart';

/// [VenuesRepository] on the phone's database: `etablissements`, with their sports
/// (`etablissement_sports`), amenities (`etablissement_equipements`) and tonight's free slots
/// (`etablissement_creneaux`), closest first.
class SqliteVenuesRepository implements VenuesRepository {
  SqliteVenuesRepository(this._database, {bool Function()? offline})
      : _offline = offline ?? (() => false);

  final AppDatabase _database;
  final bool Function() _offline;

  static Future<void> insert(DatabaseExecutor db, MuVenue v, int position) async {
    await db.insert('etablissements', {
      'id': v.id,
      'nom': v.name,
      'lieu': v.place,
      'distance_km': v.distanceKm,
      'note': v.rating,
      'nb_avis': v.reviews,
      'verifie': v.verified ? 1 : 0,
      'prix_joueur': v.pricePerPerson,
      'prix_terrain': v.courtPrice,
      'unite_prix': v.courtPriceUnit,
      'statut': v.status.name,
      'ouvre_a': v.opensAt,
      'jour_creneaux': v.slotsDay,
      'latitude': v.position?.lat,
      'longitude': v.position?.lng,
      'position': position,
    });
    for (final (i, s) in v.sports.indexed) {
      await db.insert('etablissement_sports', {'etablissement_id': v.id, 'position': i, 'sport': s.name});
    }
    for (final (i, a) in v.amenities.indexed) {
      await db.insert('etablissement_equipements',
          {'etablissement_id': v.id, 'position': i, 'equipement': a.name});
    }
    for (final (i, h) in v.slots.indexed) {
      await db.insert('etablissement_creneaux', {'etablissement_id': v.id, 'position': i, 'heure': h});
    }
  }

  /// Stores [v] as Supabase has it (the cache of [SupabaseVenuesRepository]): updates a known
  /// venue's details, keeping its amenities and slots; adds a new one.
  Future<void> keep(MuVenue v) async {
    final db = await _database.db;
    await db.transaction((txn) async {
      final updated = await txn.update(
        'etablissements',
        {
          'nom': v.name,
          'lieu': v.place,
          'distance_km': v.distanceKm,
          'note': v.rating,
          'nb_avis': v.reviews,
          'verifie': v.verified ? 1 : 0,
          'prix_joueur': v.pricePerPerson,
          'prix_terrain': v.courtPrice,
          'latitude': v.position?.lat,
          'longitude': v.position?.lng,
        },
        where: 'id = ?',
        whereArgs: [v.id],
      );
      if (updated == 0) {
        final last = Sqflite.firstIntValue(await txn.rawQuery('SELECT MAX(position) FROM etablissements'));
        await insert(txn, v, (last ?? -1) + 1);
      }
    });
  }

  static Future<void> seed(DatabaseExecutor db) async {
    for (final (i, v) in Story.venues.indexed) {
      await insert(db, v, i);
    }
  }

  @override
  Future<List<MuVenue>> venues() async {
    if (_offline()) throw const OfflineException();
    final db = await _database.db;
    Future<Map<String, List<String>>> listOf(String table, String column) async {
      final out = <String, List<String>>{};
      for (final r in await db.query(table, orderBy: 'etablissement_id, position')) {
        (out[r['etablissement_id']! as String] ??= []).add(r[column]! as String);
      }
      return out;
    }

    final sports = await listOf('etablissement_sports', 'sport');
    final amenities = await listOf('etablissement_equipements', 'equipement');
    final slots = await listOf('etablissement_creneaux', 'heure');
    return [
      for (final r in await db.query('etablissements', orderBy: 'position'))
        MuVenue(
          id: r['id']! as String,
          name: r['nom']! as String,
          sports: [for (final s in sports[r['id']] ?? const <String>[]) MuSport.values.byName(s)],
          place: r['lieu']! as String,
          distanceKm: (r['distance_km'] as num?)?.toDouble(),
          rating: (r['note'] as num?)?.toDouble(),
          reviews: r['nb_avis']! as int,
          verified: r['verifie'] == 1,
          amenities: [
            for (final a in amenities[r['id']] ?? const <String>[]) MuAmenity.values.byName(a),
          ],
          slots: slots[r['id']] ?? const [],
          slotsDay: r['jour_creneaux'] as String?,
          pricePerPerson: r['prix_joueur']! as num,
          courtPrice: r['prix_terrain'] as num?,
          courtPriceUnit: r['unite_prix']! as String,
          status: MuVenueStatus.values.byName(r['statut']! as String),
          opensAt: r['ouvre_a'] as String?,
          position: r['latitude'] == null
              ? null
              : MuLatLng((r['latitude']! as num).toDouble(), (r['longitude']! as num).toDouble()),
        ),
    ];
  }
}
