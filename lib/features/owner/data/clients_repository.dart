import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/search.dart';
import '../../common/data/story_data.dart';

/// A player who booked at the venue (OWN-18).
@immutable
class OwnerClient {
  const OwnerClient({
    required this.name,
    required this.phone,
    required this.visits,
    required this.spent,
    required this.reliability,
    required this.lastVisit,
    required this.firstVisit,
    required this.favourite,
    this.noShows = 0,
    this.nextVisit,
    this.regular = false,
    this.newcomer = false,
    this.refs = const [],
  });

  final String name;

  /// Local digits (« 22 345 678 »).
  final String phone;
  final int visits;

  /// What they paid at the venue (« 345 DT »).
  final num spent;
  final int noShows;

  /// The MatchUp reliability score (« Fiable 98 % »).
  final int reliability;
  final DateTime lastVisit;

  /// Their next booking, shown instead of the last visit (« prochaine · mer. 21 oct. »).
  final DateTime? nextVisit;
  final DateTime firstVisit;

  /// « Terrain 1 · jeu. 17h ».
  final String favourite;
  final bool regular;
  final bool newcomer;

  /// Their booking references, for the search (« MU-48213 »).
  final List<String> refs;

  bool matches(String query) {
    final q = foldAccents(query.trim());
    if (q.isEmpty) return true;
    final digits = query.replaceAll(RegExp(r'\D'), '');
    return foldAccents(name).contains(q) ||
        (digits.length >= 2 && phone.replaceAll(' ', '').contains(digits)) ||
        refs.any((r) => foldAccents(r).contains(q));
  }
}

/// The whole clientele, of which the list shows the most frequent (OWN-18 « 286 clients »).
@immutable
class ClientsSummary {
  const ClientsSummary({
    required this.total,
    required this.regulars,
    required this.newcomers,
    required this.withNoShow,
    required this.since,
    required this.top,
  });

  final int total;
  final int regulars;
  final int newcomers;
  final int withNoShow;

  /// The venue joined MatchUp then (« depuis le 19 sept. »).
  final DateTime since;

  /// The most frequent clients, by visits.
  final List<OwnerClient> top;
}

abstract interface class ClientsRepository {
  Future<ClientsSummary> clients();
}

/// Arena Five's clients (STORY-DATA « Venue owner »).
class FakeClientsRepository implements ClientsRepository {
  FakeClientsRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;

  static DateTime _sept(int day) => DateTime(2026, 9, day);

  @override
  Future<ClientsSummary> clients() async {
    await Future<void>.delayed(latency);
    return ClientsSummary(
      total: 286,
      regulars: 64,
      newcomers: 48,
      withNoShow: 9,
      since: _sept(19),
      top: [
        OwnerClient(
          name: 'Hamza R.',
          phone: '22 345 678',
          visits: 23,
          spent: 345,
          reliability: 98,
          lastVisit: Story.at(16, 17),
          firstVisit: _sept(19),
          favourite: 'Terrain 1 · jeu. 17h',
          regular: true,
          refs: const ['MU-48150', 'MU-48208', 'MU-48211'],
        ),
        OwnerClient(
          name: 'Yassine B.',
          phone: '98 765 432',
          visits: 14,
          spent: 210,
          reliability: 96,
          lastVisit: Story.at(11, 20),
          nextVisit: Story.at(21, 21),
          firstVisit: _sept(20),
          favourite: 'Terrain 1 · mer. 21h',
          regular: true,
          refs: const ['MU-48213'],
        ),
        OwnerClient(
          name: 'Omar D.',
          phone: '55 123 456',
          visits: 11,
          spent: 165,
          noShows: 2,
          reliability: 82,
          lastVisit: Story.at(16, 18),
          firstVisit: _sept(19),
          favourite: 'Terrain 2 · ven. 18h',
          regular: true,
          refs: const ['MU-48161', 'MU-48164', 'MU-48212'],
        ),
        OwnerClient(
          name: 'Nour A.',
          phone: '24 680 135',
          visits: 9,
          spent: 135,
          reliability: 97,
          lastVisit: Story.at(11, 20),
          firstVisit: _sept(20),
          favourite: 'Terrain 2 · dim. 20h',
          regular: true,
          refs: const ['MU-48192', 'MU-48122', 'MU-48215'],
        ),
        OwnerClient(
          name: 'Aziz H.',
          phone: '29 111 222',
          visits: 8,
          spent: 120,
          noShows: 1,
          reliability: 91,
          lastVisit: Story.at(3, 19),
          firstVisit: _sept(27),
          favourite: 'Terrain 2 · dim. 20h',
          regular: true,
          refs: const ['MU-48160', 'MU-48207', 'MU-48210'],
        ),
        OwnerClient(
          name: 'Ines M.',
          phone: '50 222 333',
          visits: 6,
          spent: 90,
          reliability: 95,
          lastVisit: Story.at(11, 19),
          firstVisit: _sept(26),
          favourite: 'Terrain 1 · sam. 19h',
          refs: const ['MU-48196', 'MU-48209', 'MU-48214'],
        ),
        OwnerClient(
          name: 'Salma G.',
          phone: '21 444 555',
          visits: 5,
          spent: 60,
          reliability: 94,
          lastVisit: Story.at(13, 19),
          firstVisit: DateTime(2026, 10, 3),
          favourite: 'Terrain 1 · sam. 19h',
          refs: const ['MU-48190', 'MU-48132', 'MU-48216'],
        ),
        OwnerClient(
          name: 'Lina F.',
          phone: '27 666 777',
          visits: 1,
          spent: 12,
          reliability: 92,
          lastVisit: Story.at(13, 20),
          firstVisit: Story.at(13, 20),
          favourite: 'Terrain 1 · mar. 20h',
          newcomer: true,
          refs: const ['MU-48201', 'MU-48217'],
        ),
      ],
    );
  }
}

final clientsRepositoryProvider = Provider<ClientsRepository>((ref) => FakeClientsRepository());

final ownerClientsProvider = FutureProvider<ClientsSummary>(
  (ref) => ref.watch(clientsRepositoryProvider).clients(),
);
