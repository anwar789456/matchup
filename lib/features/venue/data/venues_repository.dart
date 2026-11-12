import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity.dart';
import '../../../core/db/app_database.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../../core/supabase/supabase_config.dart';
import 'supabase_venues_repository.dart';
import 'venue_remote.dart';
import 'sqlite_venues_repository.dart';

/// Venues (« Terrains »): Explorer's list and map, the Home's « Terrains près de toi ».
abstract interface class VenuesRepository {
  /// Venues near the player's zone, closest first, with tonight's free slots.
  Future<List<MuVenue>> venues();
}

/// The story's four venues (design/screens/STORY-DATA.md).
class FakeVenuesRepository implements VenuesRepository {
  FakeVenuesRepository({this.latency = const Duration(milliseconds: 700), bool Function()? offline})
    : _offline = offline ?? (() => false);

  final Duration latency;
  final bool Function() _offline;

  @override
  Future<List<MuVenue>> venues() async {
    await Future<void>.delayed(latency);
    if (_offline()) throw const OfflineException();
    return Story.venues;
  }
}

/// Venues live in the phone's database. Tests override it with the fake.
/// The venues: Supabase as the source with the phone's database as its cache, or the phone's
/// database alone without Supabase. Tests override it with the fake.
final venuesRepositoryProvider = Provider<VenuesRepository>((ref) {
  final local = SqliteVenuesRepository(
    ref.watch(appDatabaseProvider),
    offline: () => ref.read(simulatedOfflineProvider),
  );
  final remote = ref.watch(venueRemoteProvider);
  return remote == null
      ? local
      : SupabaseVenuesRepository(local, remote, connect: SupabaseConfig.ensureSession);
});
