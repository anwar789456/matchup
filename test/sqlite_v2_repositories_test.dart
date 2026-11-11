import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/core/db/preferences.dart';
import 'package:matchup/core/db/schema.dart';
import 'package:matchup/core/db/seed.dart';
import 'package:matchup/features/admin/data/admin_repository.dart';
import 'package:matchup/features/admin/data/sqlite_admin_repository.dart';
import 'package:matchup/features/common/data/draft_store.dart';
import 'package:matchup/features/explore/data/sqlite_catalog_repositories.dart';
import 'package:matchup/features/games/data/games_repository.dart';
import 'package:matchup/features/games/data/sqlite_games_repository.dart';
import 'package:matchup/features/notifications/data/notification_models.dart';
import 'package:matchup/features/notifications/data/sqlite_notification_repository.dart';
import 'package:matchup/features/owner/data/owner_drafts.dart';
import 'package:matchup/features/owner/data/owner_repository.dart';
import 'package:matchup/features/owner/data/sqlite_owner_repositories.dart';
import 'package:matchup/features/owner/data/tariffs_repository.dart';
import 'package:matchup/features/payments/data/payment_repository.dart';
import 'package:matchup/features/payments/data/sqlite_payment_repository.dart';
import 'package:matchup/features/profile/data/sqlite_me_repository.dart';
import 'package:matchup/features/profile/data/sqlite_profile_repository.dart';
import 'package:matchup/features/settings/data/settings_repository.dart';
import 'package:matchup/features/subscription/data/sqlite_subscription_repository.dart';
import 'package:matchup/features/subscription/data/subscription_repository.dart';
import 'package:matchup/features/venue/data/sqlite_venues_repository.dart';
import 'package:matchup/features/wallet/data/sqlite_wallet_repository.dart';
import 'package:matchup/features/wallet/data/wallet_repository.dart';
import 'package:matchup/theme/theme.dart';
import 'package:matchup/ui/ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;

  setUp(() => database = AppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath));
  tearDown(() => database.close());

  Future<Directory> tempDir() => Directory.systemTemp.createTemp('matchup_db');
  String fileIn(Directory dir) => '${dir.path}${Platform.pathSeparator}${AppDatabase.fileName}';

  group('schema', () {
    test('a v1 file is upgraded to v2 and keeps what the player did', () async {
      final dir = await tempDir();
      final path = fileIn(dir);
      try {
        // A phone still on v1, where the player declined Mariem's invitation.
        final v1 = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, _) async {
              for (final s in schemaVersions[1]!) {
                await db.execute(s);
              }
              await seedVersion(db, 1);
              await db.update('invitations', {'statut': 'refusee'});
            },
          ),
        );
        await v1.close();

        final file = AppDatabase(factory: databaseFactoryFfi, path: path);
        final db = await file.db;
        expect(await db.getVersion(), AppDatabase.version);
        expect((await db.query('invitations')).single['statut'], 'refusee'); // kept
        expect((await db.query('porte_monnaie')).single['solde'], 30); // v2 seeded
        expect(await SqliteVenuesRepository(file).venues(), hasLength(4));
        await file.close();
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('foreign keys are on: a refund needs its transaction', () async {
      final db = await database.db;
      expect(
        () => db.insert('demandes_remboursement', {
          'id': 'rf-x',
          'transaction_id': 'nowhere',
          'motif': 'other',
          'note': '',
          'cible': 'balance',
          'envoyee_le': '2026-10-16',
          'etape': 'sent',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('preferences and drafts', () {
    test('preferences store, replace and remove a value', () async {
      final prefs = Preferences(database);
      expect(await prefs.get('reglages.theme'), isNull);
      await prefs.set('reglages.theme', 'dark');
      await prefs.set('reglages.theme', 'light');
      expect(await prefs.get('reglages.theme'), 'light');
      await prefs.set('reglages.theme', null);
      expect(await prefs.get('reglages.theme'), isNull);
    });

    test('drafts are JSON rows of brouillons', () async {
      final drafts = SqliteDraftStore(database);
      await drafts.save('owner_onboarding.v1', {'venueName': 'Arena Five', 'reached': 3});
      expect(await drafts.load('owner_onboarding.v1'), {'venueName': 'Arena Five', 'reached': 3});
      await drafts.clear('owner_onboarding.v1');
      expect(await drafts.load('owner_onboarding.v1'), isNull);
    });

    test('account settings round-trip with their device sessions', () async {
      final db = await database.db;
      final read = AccountSettingsRows.read(
        (await db.query('reglages_compte')).single,
        await db.query('sessions_appareils', orderBy: 'position'),
      );
      expect(read.email, 'yassine.b@email.tn');
      expect(read.sessions, hasLength(2));
      await AccountSettingsRows.write(db, read.copyWith(twoFactor: false, sessions: [read.sessions.first]));
      final again = AccountSettingsRows.read(
        (await db.query('reglages_compte')).single,
        await db.query('sessions_appareils'),
      );
      expect(again.twoFactor, isFalse);
      expect(again.sessions.single.id, 'iphone');
    });
  });

  group('argent', () {
    test('the balance is debited and credited, never below zero', () async {
      final me = SqliteMeRepository(database);
      expect((await me.me()).balance, 30);
      expect((await me.me()).unreadNotifications, 3);
      await me.debit(15);
      await me.credit(5);
      expect((await me.me()).balance, 20);
      expect(() => me.debit(50), throwsStateError);
    });

    test('wallet history newest first, a refund request joins its transaction', () async {
      final wallet = SqliteWalletRepository(database);
      final history = await wallet.history();
      expect(history.first.id, 'tx-share-oct21');
      expect(history, hasLength(7));
      expect((await wallet.refunds()).single.transaction.label, 'Part · Hoop Zone');

      final r = await wallet.requestRefund(
        transaction: history.first,
        reason: RefundReason.gameCancelled,
        note: 'Partie annulée',
        target: RefundTarget.balance,
      );
      expect(r.id, 'rf-2');
      expect((await wallet.refunds()).first.transaction.id, 'tx-share-oct21');
    });

    test('payments are numbered after the last receipt; cards and promo codes', () async {
      final pay = SqlitePaymentRepository(database, latency: Duration.zero);
      expect((await pay.cards()).map((c) => c.last4), ['4242', '5454']);
      final first = await pay.charge(amount: 15, reason: 'Part', method: PayWith.card);
      final second = await pay.charge(amount: 9, reason: 'Part', method: PayWith.balance);
      expect(first.receipt!.number, 'MU-R-2026-01482');
      expect(first.receipt!.card!.last4, '4242');
      expect(second.receipt!.number, 'MU-R-2026-01483');
      expect((await (await database.db).query('paiements')), hasLength(2));

      await pay.addCard(brand: CardBrand.mastercard, last4: '1907', expMonth: 3, expYear: 2029);
      await pay.addCard(brand: CardBrand.visa, last4: '0000', expMonth: 3, expYear: 2029, save: false);
      expect((await pay.cards()).last.last4, '1907');

      expect((await pay.applyPromo(' bienvenue10 ')).percent, 10);
      expect((await pay.applyPromo('MARSA2025')).error, contains('expiré'));
      expect((await pay.applyPromo('NOPE')).valid, isFalse);
    });

    test('3-D Secure keeps the attempt until the bank answers', () async {
      final pay = SqlitePaymentRepository(
        database,
        latency: Duration.zero,
        outcome: () => PaymentOutcome.threeDSecure,
      );
      final r = await pay.charge(amount: 15, reason: 'Part', method: PayWith.card);
      expect(r.status, PaymentStatus.needsAuthentication);
      final ok = await pay.confirmAuthentication(approved: true);
      expect(ok.receipt!.amount, 15);
    });

    test('Premium: trial, cancel with a reason, reactivate; the receipts and their lines', () async {
      final sub = SqliteSubscriptionRepository(database);
      expect((await sub.current()).status, PremiumStatus.free);
      await sub.startTrial(period: MuBillingPeriod.year, cardLabel: 'Visa •••• 4242');
      final cancelled = await sub.cancel(reason: CancelReason.price, note: 'Trop cher pour moi');
      expect(cancelled.cancelReason, CancelReason.price);
      expect((await sub.current()).yearlyPlan, isTrue);
      expect((await sub.reactivate()).status, PremiumStatus.trial);

      final receipts = await sub.receipts();
      expect(receipts.map((r) => r.number), ['MU-R-2026-01482', 'MU-R-2026-01437', 'MU-R-2026-01391']);
      expect(receipts.first.lines.first.details, hasLength(3));
    });
  });

  group('joueur', () {
    test('notifications: read, delete and push survive a new repository', () async {
      final repo = SqliteNotificationRepository(database);
      final first = await repo.watch().first;
      expect(first.first.id, 'n-place');
      expect(first.where((n) => n.unread), hasLength(3));
      expect(first.firstWhere((n) => n.id == 'n-cup').icon, isNotNull);
      expect(first.firstWhere((n) => n.id == 'n-invite').actions, hasLength(2));

      await repo.markRead('n-place');
      await repo.delete('n-reminder');
      await repo.push(AppNotificationSample.live);

      final again = await SqliteNotificationRepository(database).watch().first;
      expect(again.first.id, 'live-g1-9');
      expect(again.any((n) => n.id == 'n-reminder'), isFalse);
      expect(again.firstWhere((n) => n.id == 'n-place').unread, isFalse);
    });

    test('games: join takes a place, the waitlist, freed places, publishing', () async {
      final games = SqliteGamesRepository(database);
      final g4 = (await games.openGames()).firstWhere((g) => !g.isFull);
      final left = g4.spotsLeft;
      await games.join(g4.id!, team: 1, slot: 4);
      final joined = await games.details(g4.id!);
      expect(joined.membership, GameMembership.joined);
      expect(joined.game.spotsLeft, left - 1);
      expect((joined.joinedTeam, joined.joinedSlot), (1, 4));
      expect((await games.joined()).single.id, g4.id);
      await games.leave(g4.id!);
      expect(await games.joined(), isEmpty);

      final recommended = await games.recommended();
      expect(recommended, hasLength(2));
      await games.joinWaitlist(recommended.first.id!);
      expect((await games.details(recommended.first.id!)).waitlistPosition, 3);
      await games.freeSpot(recommended.first.id!);
      final freed = (await games.openGames()).firstWhere((g) => g.id == recommended.first.id);
      expect(freed.spotsLeft, recommended.first.spotsLeft + 1);

      final before = (await games.openGames()).length;
      await games.publish(MuGame(
        id: 'g-mine',
        sport: MuSport.padel,
        venue: 'Smash Padel Club',
        place: 'Lac 2',
        start: DateTime(2026, 10, 24, 19),
        spotsTotal: 4,
        spotsLeft: 2,
        pricePerPlayer: 20,
        players: const [MuPerson('Yassine B.'), MuPerson('Mariem K.')],
      ));
      final all = await games.openGames();
      expect(all, hasLength(before + 1));
      expect(all.last.players.map((p) => p.name), ['Yassine B.', 'Mariem K.']);
    });

    test('profile: edits, follows and level disputes are saved', () async {
      final repo = SqlitePlayerProfileRepository(database);
      final me = await repo.me();
      expect(me.handle, 'yassine.b');
      await repo.save(me.copyWith(bio: 'Padel le soir.', zones: ['Lac 2'], showLevel: false));
      final saved = await SqlitePlayerProfileRepository(database).me();
      expect(saved.bio, 'Padel le soir.');
      expect(saved.zones, ['Lac 2']);
      expect(saved.showLevel, isFalse);
      expect(saved.positions[MuSport.padel], 'côté gauche');

      await repo.follow('Skander T.', follow: true);
      expect((await repo.player('Skander T.')).followed, isTrue);
      await repo.follow('Skander T.', follow: false);
      expect((await repo.player('Skander T.')).followed, isFalse);

      await repo.adjustLevel(MuSport.padel, 3.7);
      await repo.contestLevel(MuSport.padel);
      final row = (await (await database.db).query('niveaux_ajustes')).single;
      expect((row['niveau'], row['conteste']), (3.7, 1));
    });
  });

  group('catalogues', () {
    test('venues with their sports, amenities, slots and position', () async {
      final venues = await SqliteVenuesRepository(database).venues();
      expect(venues.map((v) => v.id), ['arena-five', 'smash-padel', 'padel-house-menzah', 'hoop-zone']);
      final arena = venues.first;
      expect(arena.amenities, hasLength(6));
      expect(arena.slots, ['19h00', '21h00', '22h00']);
      expect(arena.position!.lat, 36.8805);
      expect(venues[1].courtPriceUnit, '/1h30');
    });

    test('tournaments, districts, players and teammates', () async {
      expect((await SqliteTournamentsRepository(database).nearby()).single.name, 'Padel Masters Lac 2');
      final zones = await SqliteSearchRepository(database).zones();
      expect(zones.first.venueIds, isNull); // all around La Marsa
      expect(zones[1].venueIds, ['arena-five']);
      expect(await SqliteSearchRepository(database).players(), hasLength(6));
      final mates = await SqliteTeammatesRepository(database).suggested('arena-five');
      expect(mates.first.name, 'Skander T.');
      expect(mates.where((m) => m.regular), hasLength(5));
    });
  });

  group('propriétaire', () {
    test('bookings of a day with presences; no-show and cancel are saved', () async {
      final owner = SqliteOwnerRepository(database);
      final today = await owner.bookingsOn(DateTime(2026, 10, 16));
      expect(today.first.ref, 'MU-48150');
      final live = today.firstWhere((b) => b.ref == 'MU-48160');
      expect(live.arrived, hasLength(9));
      expect(live.expected, ['Sarra B.']);

      final b = await owner.markNoShow('MU-48213', ['Ines M.', 'Lina F.']);
      expect(b.noShows, ['Ines M.', 'Lina F.']);
      expect(b.expected, ['Rami S.', 'Salma G.']);
      await owner.cancel('MU-48204');
      expect((await owner.bookingsOn(DateTime(2026, 10, 16))).any((x) => x.ref == 'MU-48204'), isFalse);
      expect((await owner.booking('MU-48204'))!.status, OwnerBookingStatus.cancelled);
      expect((await owner.checkIn(' mu-48213 ', DateTime(2026, 10, 21, 20, 50))).status,
          CheckInStatus.valid);
    });

    test('blocks: weekly ones repeat, ids follow, unblock deletes', () async {
      final owner = SqliteOwnerRepository(database);
      final block = await owner.block(
        courts: [1, 2],
        start: DateTime(2026, 10, 22, 8),
        end: DateTime(2026, 10, 22, 12),
        reason: BlockReason.maintenance,
        weekly: true,
      );
      expect(block.id, 'b3');
      expect(await owner.blocksOn(DateTime(2026, 10, 29)), hasLength(2)); // next Thursday
      await owner.unblock('b3');
      expect(await owner.blocksOn(DateTime(2026, 10, 29)), hasLength(1));
      await owner.updateCourt((await owner.courts()).last.copyWith(maintenance: true));
      expect((await owner.courts()).last.maintenance, isTrue);
    });

    test('tariffs and promos, reviews and replies, clients', () async {
      final tariffs = SqliteTariffsRepository(database);
      final t = await tariffs.load();
      expect((t.minPrice, t.maxPrice), (120, 150));
      expect(t.priceOf(3).indoor, isTrue);
      final saved = await tariffs.save(t.copyWith(prices: [
        for (final p in t.prices) p.copyWith(peak: 160),
      ]));
      expect(saved.maxPrice, 160);
      final promo = await tariffs.publishPromo(OwnerPromo(
        draft: PromoDraft.thursdayAfternoon,
        firstDay: DateTime(2026, 10, 22),
        weekly: true,
      ));
      expect(promo.promos.single.draft.priceAfter, 96);

      final reviews = SqliteReviewsRepository(database, clock: () => DateTime(2026, 10, 16, 18));
      final summary = await reviews.reviews();
      expect((summary.average, summary.total, summary.unanswered), (4.7, 128, 1));
      await reviews.reply('r-omar', 'Merci Omar !');
      expect((await reviews.reviews()).unanswered, 0);

      final clients = await SqliteClientsRepository(database).clients();
      expect(clients.total, 286);
      expect(clients.top.first.refs, ['MU-48150', 'MU-48208', 'MU-48211']);
    });
  });

  test('admin: the journal is replayed after reopening the file', () async {
    final dir = await tempDir();
    final path = fileIn(dir);
    try {
      var file = AppDatabase(factory: databaseFactoryFfi, path: path);
      var admin = SqliteAdminRepository(file);
      final users = await admin.users();
      final target = users.firstWhere((u) => u.status == AdminUserStatus.active);
      await admin.suspend(target.id, until: DateTime(2026, 10, 23));
      final item = (await admin.moderation()).first;
      await admin.decide(item.id, ModerationDecision.warn);
      final payout = (await admin.payouts()).firstWhere((p) => !p.validated);
      await admin.validatePayouts({payout.id});
      await file.close();

      file = AppDatabase(factory: databaseFactoryFfi, path: path);
      admin = SqliteAdminRepository(file);
      expect((await admin.users()).firstWhere((u) => u.id == target.id).status,
          AdminUserStatus.suspended);
      expect((await admin.moderation()).any((m) => m.id == item.id), isFalse);
      expect((await admin.payouts()).firstWhere((p) => p.id == payout.id).validated, isTrue);
      expect(await (await file.db).query('admin_journal'), hasLength(3));
      await file.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });
}

/// A notification pushed while the app runs (NOT-07).
abstract final class AppNotificationSample {
  static final live = AppNotification(
    id: 'live-g1-9',
    type: NotificationType.playerJoinedLive,
    title: 'Rami S. a rejoint la partie',
    body: 'Arena Five · 9/10',
    at: DateTime(2026, 10, 16, 18, 5),
    sport: MuSport.football,
    avatar: 'Rami S.',
    target: NotificationTarget.game,
    targetId: 'g1',
    unread: true,
  );
}
