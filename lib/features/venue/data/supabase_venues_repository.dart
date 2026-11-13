import 'package:flutter/foundation.dart';

import '../../../ui/ui.dart';
import 'sqlite_venues_repository.dart';
import 'venue_remote.dart';
import 'venues_repository.dart';

/// [VenuesRepository] with Supabase as the source of the catalogue and SQFlite as its cache:
/// online, the venues are fetched and the phone's copy updated; the screens always read the
/// copy, so the list shows offline too.
class SupabaseVenuesRepository implements VenuesRepository {
  SupabaseVenuesRepository(this._local, this._remote, {required this.connect});

  final SqliteVenuesRepository _local;
  final VenueRemote _remote;

  /// True once Supabase has a session.
  final Future<bool> Function() connect;

  @override
  Future<List<MuVenue>> venues() async {
    try {
      if (await connect()) {
        for (final v in await _remote.venues()) {
          await _local.keep(v.venue);
        }
      }
    } on Object catch (e) {
      debugPrint('Terrains : on garde la copie du téléphone ($e)');
    }
    return _local.venues();
  }
}
