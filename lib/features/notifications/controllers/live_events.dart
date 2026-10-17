import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../games/data/games_repository.dart';
import '../data/notification_models.dart';
import '../data/notification_repository.dart';
import '../../../l10n/l10n.dart';

/// Someone joined the game on screen (NOT-07).
@immutable
class GameLiveEvent {
  const GameLiveEvent({required this.gameId, required this.title, required this.description});

  final String gameId;

  /// « Rami S. a rejoint la partie · 9/10 ».
  final String title;

  /// « Attaquant chez les Bleus · plus qu’1 place ».
  final String description;
}

/// The real-time feed of the open lobby. A backend will push these; until then the debug menu
/// does (« Simuler : Rami S. rejoint G1 »).
class LiveEvents {
  LiveEvents(this._ref);

  final Ref _ref;
  final _events = StreamController<GameLiveEvent>.broadcast();

  Stream<GameLiveEvent> get stream => _events.stream;

  // 5-a-side positions, keeper first (Lineup.md).
  static final _positions = [l10n.gardien, l10n.defenseur, l10n.milieu, l10n.milieu, l10n.attaquant];

  /// [name] takes the next place of [gameId]: the lineup refreshes, the toast shows on GAM-01 and
  /// the centre gets the notification.
  Future<void> playerJoined(String gameId, {String name = 'Rami S.'}) async {
    final games = _ref.read(gamesRepositoryProvider);
    final before = await games.details(gameId);
    await games.playerJoined(gameId);
    final after = await games.details(gameId);
    _ref.invalidate(gameDetailsProvider(gameId));
    // Where the new player stands: the first place filled since.
    var where = '';
    for (var t = 0; t < after.teams.length && where.isEmpty; t++) {
      for (var s = 0; s < after.teams[t].players.length; s++) {
        if (before.teams[t].players[s] == null && after.teams[t].players[s] != null) {
          where = l10n.chezLes(_positions[s % _positions.length], after.teams[t].name);
          break;
        }
      }
    }
    final g = after.game;
    final filled = g.spotsTotal - g.spotsLeft;
    final left = g.spotsLeft == 0
        ? 'complet'
        : g.spotsLeft == 1
        ? l10n.plusQuPlace
        : l10n.encorePlaces2(g.spotsLeft);
    final event = GameLiveEvent(
      gameId: gameId,
      title: l10n.aRejointLaPartie(name, filled, g.spotsTotal),
      description: [if (where.isNotEmpty) where, left].join(' · '),
    );
    _events.add(event);
    await _ref
        .read(notificationRepositoryProvider)
        .push(
          AppNotification(
            id: 'live-$gameId-$filled',
            type: NotificationType.playerJoinedLive,
            title: event.title,
            body: '${g.venue} · ${event.description}',
            at: _ref.read(clockProvider)(),
            sport: g.sport,
            avatar: name,
            target: NotificationTarget.game,
            targetId: gameId,
            unread: true,
          ),
        );
  }
}

final liveEventsProvider = Provider<LiveEvents>(LiveEvents.new);

final gameLiveEventsProvider = StreamProvider<GameLiveEvent>(
  (ref) => ref.watch(liveEventsProvider).stream,
);
