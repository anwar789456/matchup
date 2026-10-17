import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui.dart';
import '../../booking/data/payment_repository.dart';
import '../../explore/controllers/explore_controller.dart';
import '../../home/controllers/home_providers.dart';
import '../../profile/data/me_repository.dart';
import '../data/games_repository.dart';

/// What a player does with an open game: join (after paying the share), leave, the waitlist. Each
/// action refreshes the game page, « Mes matchs », the Home and Explorer.
class GameActions {
  const GameActions(this._ref);

  final Ref _ref;

  GamesRepository get _games => _ref.read(gamesRepositoryProvider);

  void _refresh(String id) {
    _ref
      ..invalidate(gameDetailsProvider(id))
      ..invalidate(upcomingMatchesProvider)
      ..invalidate(recommendedGamesProvider)
      ..invalidate(exploreGamesProvider);
  }

  /// Pays the share (CLAUDE.md rule 10: the fake payment until PAY-01), then takes the place.
  Future<void> join(MuGame game, {required int team, required int slot}) async {
    await _ref
        .read(paymentRepositoryProvider)
        .pay(game.pricePerPlayer, reason: 'Partie ${game.id} · ${game.title}');
    await _games.join(game.id!, team: team, slot: slot);
    _refresh(game.id!);
  }

  /// Gives the place back, the share refunded to the balance.
  Future<void> leave(MuGame game) async {
    await _games.leave(game.id!);
    await _ref.read(meRepositoryProvider).credit(game.pricePerPlayer);
    _ref.invalidate(meProvider);
    _refresh(game.id!);
  }

  /// « Annuler » on the snackbar: the place is taken back, nothing to pay again.
  Future<void> rejoin(MuGame game, {required int team, required int slot}) async {
    await _games.join(game.id!, team: team, slot: slot);
    await _ref.read(meRepositoryProvider).debit(game.pricePerPlayer);
    _ref.invalidate(meProvider);
    _refresh(game.id!);
  }

  Future<void> joinWaitlist(String id) async {
    await _games.joinWaitlist(id);
    _refresh(id);
  }

  Future<void> leaveWaitlist(String id) async {
    await _games.leaveWaitlist(id);
    _refresh(id);
  }

  /// A player left: one place opens (the debug « Simuler une place libérée »).
  Future<void> freeSpot(String id) async {
    await _games.freeSpot(id);
    _refresh(id);
  }
}

final gameActionsProvider = Provider<GameActions>(GameActions.new);

/// The first free position of a lineup: (team, slot), or null when full.
(int, int)? firstFreeSlot(List<MuLineupTeam> teams) {
  for (final (t, team) in teams.indexed) {
    for (final (s, p) in team.players.indexed) {
      if (p == null) return (t, s);
    }
  }
  return null;
}
