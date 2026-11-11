import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/core/sms/sms_sender.dart';
import 'package:matchup/features/auth/data/auth_repository.dart';
import 'package:matchup/features/auth/data/sqlite_auth_repository.dart';
import 'package:matchup/features/matches/data/sqlite_bookings_repository.dart';
import 'package:matchup/features/owner_onboarding/data/owner_repository.dart';
import 'package:matchup/features/owner_onboarding/data/sqlite_owner_repository.dart';
import 'package:matchup/features/player_onboarding/data/sqlite_profile_repository.dart';
import 'package:matchup/theme/theme.dart';
import 'package:matchup/ui/ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Records the SMS instead of sending them.
class _Sms implements SmsSender {
  _Sms({this.live = true});

  @override
  final bool live;
  final sent = <(String, String)>[];

  String get lastCode => RegExp(r'\d{6}').firstMatch(sent.last.$2)!.group(0)!;

  @override
  Future<void> send(String to, String message) async => sent.add((to, message));
}

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late _Sms sms;
  late DateTime now;
  int? session;

  SqliteAuthRepository auth() => SqliteAuthRepository(
        database,
        sms: sms,
        onSignedIn: (id) async => session = id,
        userId: () => session,
        now: () => now,
        random: Random(7),
      );

  setUp(() {
    database = AppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    sms = _Sms();
    now = DateTime(2026, 10, 16, 18);
    session = null;
  });

  tearDown(() => database.close());

  group('utilisateurs', () {
    test('sign-up stores a salted hash, never the password; a second sign-up is refused', () async {
      await auth().signUp(email: ' Yassine.B@email.tn ', password: 'Marsa2026');
      expect(session, 1);
      final row = (await (await database.db).query('utilisateurs')).single;
      expect(row['email'], 'yassine.b@email.tn');
      expect(row['mot_de_passe'], isNot(contains('Marsa2026')));
      expect(row['mot_de_passe'], SqliteAuthRepository.hashPassword(row['sel']! as String, 'Marsa2026'));
      expect(
        () => auth().signUp(email: 'yassine.b@email.tn', password: 'x'),
        throwsA(isA<EmailAlreadyUsed>()),
      );
    });

    test('sign-in checks the password, counts down, then locks', () async {
      await auth().signUp(email: 'yassine.b@email.tn', password: 'Marsa2026');
      session = null;
      final repo = auth();
      await repo.signIn(email: 'YASSINE.B@email.tn', password: 'Marsa2026');
      expect(session, 1);
      for (var left = 4; left >= 1; left--) {
        await expectLater(
          repo.signIn(email: 'yassine.b@email.tn', password: 'nope'),
          throwsA(isA<InvalidCredentials>().having((e) => e.attemptsLeft, 'left', left)),
        );
      }
      await expectLater(
        repo.signIn(email: 'yassine.b@email.tn', password: 'nope'),
        throwsA(isA<AccountLocked>()),
      );
    });

    test('the SMS code saves the number once right; resends are rate-limited', () async {
      final repo = auth();
      await repo.signUp(email: 'yassine.b@email.tn', password: 'Marsa2026');
      await repo.sendPhoneCode('98123456');
      expect(sms.sent.single.$1, '+21698123456');

      await expectLater(
        repo.verifyPhoneCode('000000'),
        throwsA(isA<InvalidCode>().having((e) => e.attemptsLeft, 'left', 2)),
      );
      await expectLater(repo.sendPhoneCode('98123456'), throwsA(isA<CodeRequestTooSoon>()));

      await repo.verifyPhoneCode(sms.lastCode);
      final user = (await (await database.db).query('utilisateurs')).single;
      expect(user['telephone'], '98123456');
      expect(user['telephone_verifie'], 1);

      now = now.add(const Duration(seconds: 31));
      await repo.sendPhoneCode('98123456');
      expect(sms.sent, hasLength(2));
    });

    test('three wrong SMS codes block the code for 10 minutes', () async {
      final repo = auth();
      await repo.signUp(email: 'yassine.b@email.tn', password: 'Marsa2026');
      await repo.sendPhoneCode('98123456');
      await expectLater(repo.verifyPhoneCode('000001'), throwsA(isA<InvalidCode>()));
      await expectLater(repo.verifyPhoneCode('000002'), throwsA(isA<InvalidCode>()));
      await expectLater(
        repo.verifyPhoneCode('000003'),
        throwsA(isA<TooManyCodeAttempts>()
            .having((e) => e.retryAt, 'retryAt', now.add(const Duration(minutes: 10)))),
      );
      await expectLater(repo.verifyPhoneCode(sms.lastCode), throwsA(isA<TooManyCodeAttempts>()));
    });

    test('without a textbee key the code is 123456 and nothing is sent', () async {
      sms = _Sms(live: false);
      final repo = auth();
      await repo.signUp(email: 'yassine.b@email.tn', password: 'Marsa2026');
      await repo.sendPhoneCode('98123456');
      await repo.verifyPhoneCode('123456');
    });

    test('password reset by SMS to the verified number (AUTH-06 to 08)', () async {
      final repo = auth();
      await repo.signUp(email: 'yassine.b@email.tn', password: 'Marsa2026');
      await repo.sendPhoneCode('98123456');
      await repo.verifyPhoneCode(sms.lastCode);

      await repo.sendPasswordResetCode('yassine.b@email.tn');
      expect(sms.sent.last.$1, '+21698123456');
      await repo.verifyPasswordResetCode(sms.lastCode);
      await expectLater(repo.resetPassword('Marsa2026'), throwsA(isA<SamePassword>()));
      await repo.resetPassword('Lac2-2026');

      session = null;
      await auth().signIn(email: 'yassine.b@email.tn', password: 'Lac2-2026');
      expect(session, 1);
    });

    test('the role and the phone survive a restart of the repository', () async {
      await auth().signUp(email: 'yassine.b@email.tn', password: 'Marsa2026');
      final restarted = auth(); // new repository, same signed-in session
      await restarted.saveRoles({UserRole.coach, UserRole.owner});
      await restarted.sendPhoneCode('98123456');
      await restarted.verifyPhoneCode(sms.lastCode);
      final user = (await (await database.db).query('utilisateurs')).single;
      expect(user['role'], 'proprietaire');
      expect(user['telephone_verifie'], 1);
    });

    test('pseudo availability and profile save', () async {
      await auth().signUp(email: 'yassine.b@email.tn', password: 'Marsa2026');
      final profile = SqliteProfileRepository(database, userId: () => session);
      expect(await profile.isPseudoAvailable('yassine.b'), isTrue);
      await profile.saveProfile(pseudo: 'Yassine.B', fullName: 'Yassine Belhadj');
      final user = (await (await database.db).query('utilisateurs')).single;
      expect(user['pseudo'], 'yassine.b');
      expect(user['prenom'], 'Yassine');
      expect(user['nom'], 'Belhadj');
      expect(await profile.isPseudoAvailable('yassine.b'), isTrue); // it's mine

      final other = SqliteProfileRepository(database, userId: () => 99);
      expect(await other.isPseudoAvailable('yassine.b'), isFalse);
    });
  });

  test('starting the owner trial saves every court', () async {
    await auth().signUp(email: 'arena.five@email.tn', password: 'Marsa2026');
    final draft = await const FakeOwnerRepository().start();
    await SqliteOwnerRepository(database, userId: () => session).startTrial(draft);
    final courts = await (await database.db).query('terrains', orderBy: 'id');
    expect(courts.map((t) => t['nom']), ['Terrain 1', 'Terrain 2', 'Terrain 3']);
    expect(courts.first['prix_heure'], 120);
    expect(courts.last['interieur'], 1);
    expect(courts.every((t) => t['proprietaire_id'] == session), isTrue);
  });

  group('réservations', () {
    late SqliteBookingsRepository bookings;
    setUp(() => bookings = SqliteBookingsRepository(database));

    test('a new database starts with the story', () async {
      final upcoming = await bookings.upcoming();
      expect(upcoming.bookings.single.id, 'MU-48213');
      expect(upcoming.bookings.single.players, hasLength(6));
      expect(upcoming.invitations.single.id, 'inv-mariem');
      expect((await bookings.cancelled()).single.booking.id, 'g-cancelled-oct10');
      expect(await bookings.nextReference(), 'MU-48214');
    });

    test('add, read back, cancel with refunds', () async {
      final saved = await bookings.add(MuBooking(
        sport: MuSport.padel,
        venue: 'Smash Padel Club',
        court: 'Court 3',
        place: 'Lac 2',
        start: DateTime(2026, 10, 23, 19),
        end: DateTime(2026, 10, 23, 20, 30),
        share: 22.5,
        players: const [MuPerson('Yassine B.'), MuPerson('Mariem K.')],
      ));
      expect(saved.id, 'MU-48214');
      expect(saved.share, 22.5);
      expect(saved.players.map((p) => p.name), ['Yassine B.', 'Mariem K.']);
      expect((await bookings.details('MU-48214')).booking.court, 'Court 3');
      expect(await bookings.nextReference(), 'MU-48215');

      final c = await bookings.cancel('MU-48214');
      expect(c.totalRefund, 45);
      expect((await bookings.upcoming()).bookings.map((b) => b.id), ['MU-48213']);
      final cancelled = await bookings.cancelled();
      expect(cancelled.first.booking.id, 'MU-48214');
      expect(cancelled.first.booking.status, MuBookingStatus.cancelled);
      expect(cancelled.first.byMe, isTrue);
    });

    test('invitation answers, ratings and scores are saved', () async {
      await bookings.respond('inv-mariem', accept: true);
      final upcoming = await bookings.upcoming();
      expect(upcoming.invitations, isEmpty);
      expect(upcoming.games.single.id, 'inv-mariem');

      await bookings.rate('pm-padel-oct9', const []);
      await bookings.submitScore('pm-padel-oct9', const [(6, 2), (7, 5)]);
      final padel = (await bookings.past()).firstWhere((m) => m.id == 'pm-padel-oct9');
      expect(padel.rated, isTrue);
      expect(padel.sets, const [(6, 2), (7, 5)]);
      expect(padel.scoreConfirmed, isFalse);
    });

    test('bookings survive closing and reopening the database file', () async {
      final dir = await Directory.systemTemp.createTemp('matchup_db');
      final path = '${dir.path}${Platform.pathSeparator}${AppDatabase.fileName}';
      try {
        var file = AppDatabase(factory: databaseFactoryFfi, path: path);
        await SqliteBookingsRepository(file).cancel('MU-48213');
        await file.close();

        file = AppDatabase(factory: databaseFactoryFfi, path: path);
        final reopened = SqliteBookingsRepository(file);
        expect((await reopened.upcoming()).bookings, isEmpty);
        expect((await reopened.cancelled()).first.booking.id, 'MU-48213');
        await file.close();
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
