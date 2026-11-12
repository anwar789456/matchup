import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';

/// Where a share collected after the booking stands (PAY-11).
enum ShareState { paid, pending, advanced }

/// One player's share of a booking, collected after it was made: someone who joined the public
/// game, a friend who still owes, or a share the organiser paid for (« Payer le reste »).
@immutable
class SplitShare {
  const SplitShare({
    required this.person,
    required this.amount,
    required this.state,
    this.joinedPublic = false,
    this.remindedAt,
    this.paidAt,
    this.receiptNumber,
  });

  final MuPerson person;
  final num amount;
  final ShareState state;

  /// Joined through Explorer (« A rejoint la partie publique »).
  final bool joinedPublic;
  final DateTime? remindedAt;
  final DateTime? paidAt;

  /// The organiser's receipt when the share was advanced.
  final String? receiptNumber;

  bool get reminded => remindedAt != null;
}

/// The shares of PAY-11. The organiser and the friends who paid with the booking are not here:
/// they come with the booking itself.
abstract interface class SplitRepository {
  Future<List<SplitShare>> shares(String bookingId);

  /// « Relancer »: a reminder to each of [names] who still owes.
  Future<void> remind(String bookingId, Iterable<String> names);

  /// « Payer le reste »: the organiser pays every pending share with [receiptNumber].
  Future<void> advance(String bookingId, {required String receiptNumber});
}

/// In memory, for widget tests.
class FakeSplitRepository implements SplitRepository {
  FakeSplitRepository() {
    _shares[Story.myBooking.id!] = [...storyShares];
  }

  final _shares = <String, List<SplitShare>>{};

  /// STORY-DATA PAY-11: Ines joined the public game and paid; Lina and Rami still owe 15 DT.
  static final storyShares = <SplitShare>[
    SplitShare(
      person: Story.ines,
      amount: Story.myBooking.share,
      state: ShareState.paid,
      joinedPublic: true,
      paidAt: Story.at(15, 20, 12),
    ),
    SplitShare(person: Story.lina, amount: Story.myBooking.share, state: ShareState.pending),
    SplitShare(person: Story.rami, amount: Story.myBooking.share, state: ShareState.pending),
  ];

  @override
  Future<List<SplitShare>> shares(String bookingId) async => [...?_shares[bookingId]];

  @override
  Future<void> remind(String bookingId, Iterable<String> names) async {
    final now = DateTime.now();
    _shares[bookingId] = [
      for (final s in _shares[bookingId] ?? const <SplitShare>[])
        names.contains(s.person.name) && s.state == ShareState.pending
            ? SplitShare(
                person: s.person,
                amount: s.amount,
                state: s.state,
                joinedPublic: s.joinedPublic,
                remindedAt: now,
              )
            : s,
    ];
  }

  @override
  Future<void> advance(String bookingId, {required String receiptNumber}) async {
    final now = DateTime.now();
    _shares[bookingId] = [
      for (final s in _shares[bookingId] ?? const <SplitShare>[])
        s.state == ShareState.pending
            ? SplitShare(
                person: s.person,
                amount: s.amount,
                state: ShareState.advanced,
                remindedAt: s.remindedAt,
                paidAt: now,
                receiptNumber: receiptNumber,
              )
            : s,
    ];
  }
}

/// [SplitRepository] on the phone's database: `parts_paiement`, one row per share.
class SqliteSplitRepository implements SplitRepository {
  SqliteSplitRepository(this._database);

  final AppDatabase _database;

  Future<Database> get _db => _database.db;

  static const _states = {
    ShareState.paid: 'payee',
    ShareState.pending: 'en_attente',
    ShareState.advanced: 'avancee',
  };

  static Future<void> seed(DatabaseExecutor db) async {
    for (final (i, s) in FakeSplitRepository.storyShares.indexed) {
      await db.insert('parts_paiement', {
        'reservation_id': Story.myBooking.id,
        'joueur': s.person.name,
        'montant': s.amount,
        'statut': _states[s.state],
        'partie_publique': s.joinedPublic ? 1 : 0,
        'payee_le': s.paidAt?.toIso8601String(),
        'position': i,
      });
    }
  }

  static SplitShare _share(Map<String, Object?> r) => SplitShare(
        person: MuPerson(r['joueur']! as String),
        amount: r['montant']! as num,
        state: _states.entries.firstWhere((e) => e.value == r['statut']).key,
        joinedPublic: r['partie_publique'] == 1,
        remindedAt: DateTime.tryParse('${r['relancee_le']}'),
        paidAt: DateTime.tryParse('${r['payee_le']}'),
        receiptNumber: r['numero'] as String?,
      );

  @override
  Future<List<SplitShare>> shares(String bookingId) async => [
        for (final r in await (await _db).query(
          'parts_paiement',
          where: 'reservation_id = ?',
          whereArgs: [bookingId],
          orderBy: 'position',
        ))
          _share(r),
      ];

  @override
  Future<void> remind(String bookingId, Iterable<String> names) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      for (final name in names) {
        await txn.update(
          'parts_paiement',
          {'relancee_le': now},
          where: 'reservation_id = ? AND joueur = ? AND statut = ?',
          whereArgs: [bookingId, name, _states[ShareState.pending]],
        );
      }
    });
  }

  @override
  Future<void> advance(String bookingId, {required String receiptNumber}) async {
    await (await _db).update(
      'parts_paiement',
      {
        'statut': _states[ShareState.advanced],
        'payee_le': DateTime.now().toIso8601String(),
        'numero': receiptNumber,
      },
      where: 'reservation_id = ? AND statut = ?',
      whereArgs: [bookingId, _states[ShareState.pending]],
    );
  }
}

/// The shares live in the phone's database. Tests override it with the fake.
final splitRepositoryProvider = Provider<SplitRepository>(
  (ref) => SqliteSplitRepository(ref.watch(appDatabaseProvider)),
);

final splitSharesProvider = FutureProvider.family<List<SplitShare>, String>(
  (ref, bookingId) => ref.watch(splitRepositoryProvider).shares(bookingId),
);
