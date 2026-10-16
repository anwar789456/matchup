import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';

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

final venuesRepositoryProvider = Provider<VenuesRepository>(
  (ref) => FakeVenuesRepository(offline: () => ref.read(simulatedOfflineProvider)),
);
