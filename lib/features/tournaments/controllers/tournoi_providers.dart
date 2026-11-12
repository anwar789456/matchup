import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_service.dart';
import '../data/tournoi_repository.dart';
import '../logic/bracket_logic.dart';

// Every list watches the sync, so rows written on another phone (a team registering, a score)
// show up within one sync (30 s). Screens invalidate them after their own writes.

/// ORG-04: the tournaments I organise, soonest first.
final mesTournoisProvider = FutureProvider<List<Tournoi>>((ref) {
  ref.watch(syncRevisionProvider);
  return ref.watch(tournoiRepositoryProvider).tournois(mine: true);
});

final tournoiProvider = FutureProvider.family<Tournoi?, String>((ref, id) {
  ref.watch(syncRevisionProvider);
  return ref.watch(tournoiRepositoryProvider).tournoi(id);
});

final equipesProvider = FutureProvider.family<List<Equipe>, String>((ref, id) {
  ref.watch(syncRevisionProvider);
  return ref.watch(tournoiRepositoryProvider).equipes(id);
});

final matchsProvider = FutureProvider.family<List<MatchPlan>, String>((ref, id) {
  ref.watch(syncRevisionProvider);
  return ref.watch(tournoiRepositoryProvider).matchs(id);
});

/// Re-reads one tournament's screens after a write.
void refreshTournoi(WidgetRef ref, String id) {
  ref
    ..invalidate(mesTournoisProvider)
    ..invalidate(tournoiProvider(id))
    ..invalidate(equipesProvider(id))
    ..invalidate(matchsProvider(id));
}
