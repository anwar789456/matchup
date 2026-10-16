import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';

/// Tournaments open for registration near the player.
abstract interface class TournamentsRepository {
  Future<List<MuTournament>> nearby();
}

/// The story's Padel Masters Lac 2.
class FakeTournamentsRepository implements TournamentsRepository {
  FakeTournamentsRepository({
    this.latency = const Duration(milliseconds: 700),
    bool Function()? offline,
  }) : _offline = offline ?? (() => false);

  final Duration latency;
  final bool Function() _offline;

  @override
  Future<List<MuTournament>> nearby() async {
    await Future<void>.delayed(latency);
    if (_offline()) throw const OfflineException();
    return [Story.padelMasters];
  }
}

final tournamentsRepositoryProvider = Provider<TournamentsRepository>(
  (ref) => FakeTournamentsRepository(offline: () => ref.read(simulatedOfflineProvider)),
);
