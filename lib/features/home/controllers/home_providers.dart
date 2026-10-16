import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui.dart';
import '../../explore/data/tournaments_repository.dart';
import '../../games/data/games_repository.dart';
import '../../matches/data/bookings_repository.dart';
import '../../profile/data/me_repository.dart';
import '../../venue/data/venues_repository.dart';

/// The signed-in player (greeting, zone, notifications).
final meProvider = FutureProvider<Me>((ref) => ref.watch(meRepositoryProvider).me());

/// « Parties pour toi ».
final recommendedGamesProvider = FutureProvider<List<MuGame>>(
  (ref) => ref.watch(gamesRepositoryProvider).recommended(),
);

/// « Tes prochains matchs » and the « Mes matchs » tab badge.
final upcomingMatchesProvider = FutureProvider<UpcomingMatches>(
  (ref) => ref.watch(bookingsRepositoryProvider).upcoming(),
);

/// « Terrains près de toi » (the Home shows the two closest).
final nearbyVenuesProvider = FutureProvider<List<MuVenue>>(
  (ref) => ref.watch(venuesRepositoryProvider).venues(),
);

/// « Tournois près de chez toi ».
final nearbyTournamentsProvider = FutureProvider<List<MuTournament>>(
  (ref) => ref.watch(tournamentsRepositoryProvider).nearby(),
);

/// Venues the player hearted (kept on the device until the profile API exists).
class FavouriteVenues extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) => state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
}

final favouriteVenuesProvider = NotifierProvider<FavouriteVenues, Set<String>>(
  FavouriteVenues.new,
);

/// One key per tab of the player shell, so the guided tour can point at « Mes matchs ».
final playerTabKeysProvider = Provider<List<GlobalKey>>(
  (ref) => List.generate(5, (i) => GlobalKey(debugLabel: 'tab-$i')),
);
