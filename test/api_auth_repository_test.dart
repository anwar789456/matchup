import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matchup/core/api/api_client.dart';
import 'package:matchup/core/connectivity.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/core/sms/sms_sender.dart';
import 'package:matchup/features/auth/data/api_auth_repository.dart';
import 'package:matchup/features/auth/data/auth_repository.dart';
import 'package:matchup/features/auth/data/sqlite_auth_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _NoSms implements SmsSender {
  @override
  bool get live => false;

  @override
  Future<void> send(String to, String message) async {}
}

/// A JSON answer in UTF-8, like NestJS sends.
http.Response _json(int status, Object body) => http.Response.bytes(utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

/// Answers like the backend's `utilisateur` module; records every call.
class _Server {
  final calls = <(String, Map<String, Object?>)>[];
  final accounts = <String, String>{};
  http.Response? next;

  Future<http.Response> handle(http.Request req) async {
    final body = jsonDecode(req.body) as Map<String, Object?>;
    final path = req.url.path.replaceFirst('/api/utilisateur', '');
    calls.add((path, body));
    final forced = next;
    if (forced != null) {
      next = null;
      return forced;
    }
    final email = body['email'] as String?;
    switch (path) {
      case '/utilisateurs':
        if (accounts.containsKey(email)) {
          return _json(409, {'statusCode': 409, 'message': 'Un compte existe déjà avec cet email.'});
        }
        accounts[email!] = body['motDePasse']! as String;
        return _json(201, {'id': accounts.length, 'email': email});
      case '/utilisateurs/login':
        return accounts[email] == body['motDePasse']
            ? _json(200, {'id': 1, 'email': email})
            : _json(401, {'statusCode': 401, 'message': 'Email ou mot de passe incorrect.'});
      default:
        return _json(200, {'ok': true});
    }
  }
}

void main() {
  late AppDatabase database;
  late _Server server;
  late ApiAuthRepository repo;
  int? session;

  setUp(() {
    database = AppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    server = _Server();
    session = null;
    final local = SqliteAuthRepository(
      database,
      sms: _NoSms(),
      onSignedIn: (id) async => session = id,
      userId: () => session,
    );
    final api = ApiClient('http://localhost:3001/api/utilisateur', client: MockClient(server.handle));
    repo = ApiAuthRepository(api, local);
  });

  tearDown(() => database.close());

  void expectCall((String, Map<String, Object?>) call, String path, Map<String, Object?> body) {
    expect(call.$1, path);
    expect(call.$2, body);
  }

  Future<List<Map<String, Object?>>> localUsers() async =>
      (await database.db).query('utilisateurs', where: "email LIKE '%@email.tn'");

  test('sign-up creates the account on the server, then its copy on the phone', () async {
    await repo.signUp(email: ' Yassine.B@email.tn ', password: 'Marsa2026');
    expectCall(server.calls.single, '/utilisateurs', {'email': 'yassine.b@email.tn', 'motDePasse': 'Marsa2026'});
    expect(session, isNotNull);
    expect((await localUsers()).single['email'], 'yassine.b@email.tn');

    expect(() => repo.signUp(email: 'yassine.b@email.tn', password: 'Autre2026'),
        throwsA(isA<EmailAlreadyUsed>()));
  });

  test('sign-in on the server; an account made elsewhere is copied to the phone', () async {
    server.accounts['skander.t@email.tn'] = 'Marsa2026';
    await repo.signIn(email: 'skander.t@email.tn', password: 'Marsa2026');
    expect(session, isNotNull);
    expect((await localUsers()).single['email'], 'skander.t@email.tn');
  });

  test('wrong passwords count down, then lock the account', () async {
    server.accounts['skander.t@email.tn'] = 'Marsa2026';
    await expectLater(repo.signIn(email: 'skander.t@email.tn', password: 'faux'),
        throwsA(isA<InvalidCredentials>().having((e) => e.attemptsLeft, 'attemptsLeft', 4)));
    for (var i = 0; i < 3; i++) {
      await expectLater(repo.signIn(email: 'skander.t@email.tn', password: 'faux'),
          throwsA(isA<InvalidCredentials>()));
    }
    await expectLater(repo.signIn(email: 'skander.t@email.tn', password: 'faux'),
        throwsA(isA<AccountLocked>()));
    expect(repo.lockedUntil(), isNotNull);
  });

  test('the reset code goes by email; wrong codes and the block come from the server', () async {
    await repo.sendPasswordResetCode('Skander.T@email.tn');
    expectCall(server.calls.last, '/compte/mot-de-passe/oublie', {'email': 'skander.t@email.tn'});

    server.next = _json(400, {'message': 'Code incorrect.', 'essaisRestants': 2});
    await expectLater(repo.verifyPasswordResetCode('000000'),
        throwsA(isA<InvalidCode>().having((e) => e.attemptsLeft, 'attemptsLeft', 2)));

    server.next = _json(429, {'message': 'Trop d’essais.', 'reessayerA': '2026-10-16T17:10:00.000Z'});
    await expectLater(repo.verifyPasswordResetCode('000000'), throwsA(isA<TooManyCodeAttempts>()));
  });

  test('a new password is saved on the server and on the phone', () async {
    await repo.signUp(email: 'skander.t@email.tn', password: 'Marsa2026');
    await repo.sendPasswordResetCode('skander.t@email.tn');
    await repo.verifyPasswordResetCode('482913');

    server.next = _json(409, {'message': 'Il doit être différent de l’ancien.'});
    await expectLater(repo.resetPassword('Marsa2026'), throwsA(isA<SamePassword>()));

    await repo.resetPassword('Carthage2026');
    expectCall(server.calls.last, '/compte/mot-de-passe/reinitialiser', {
      'email': 'skander.t@email.tn',
      'code': '482913',
      'motDePasse': 'Carthage2026',
    });
    // The phone's copy now has the new password.
    await repo.local.signIn(email: 'skander.t@email.tn', password: 'Carthage2026');
  });

  test('resend the confirmation email to the signed-in account', () async {
    await repo.signUp(email: 'yassine.b@email.tn', password: 'Marsa2026');
    await repo.resendVerificationEmail();
    expectCall(server.calls.last, '/compte/verification/envoyer', {'email': 'yassine.b@email.tn'});
  });

  test('no connection and server errors become OfflineException and ServerException', () async {
    final offline = ApiAuthRepository(
      ApiClient('http://localhost:3001', client: MockClient((_) => throw http.ClientException('down'))),
      repo.local,
    );
    await expectLater(offline.sendPasswordResetCode('a@email.tn'), throwsA(isA<OfflineException>()));

    server.next = http.Response('Bad gateway', 502);
    await expectLater(repo.sendPasswordResetCode('a@email.tn'), throwsA(isA<ServerException>()));
  });
}
