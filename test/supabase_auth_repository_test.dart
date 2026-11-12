import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matchup/core/connectivity.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/core/sms/sms_sender.dart';
import 'package:matchup/features/auth/data/auth_repository.dart';
import 'package:matchup/features/auth/data/sqlite_auth_repository.dart';
import 'package:matchup/features/auth/data/supabase_auth_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _NoSms implements SmsSender {
  @override
  bool get live => false;

  @override
  Future<void> send(String to, String message) async {}
}

http.Response _json(int status, Object body) => http.Response.bytes(utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

http.Response _error(int status, String code) =>
    _json(status, {'code': status, 'error_code': code, 'msg': code});

/// Answers like Supabase Auth (GoTrue) with « Confirm email » on; records every call.
class _Auth {
  final calls = <(String, Map<String, Object?>)>[];
  final passwords = <String, String>{};
  final confirmed = <String>{};
  String resetCode = '123456';
  bool offline = false;

  Map<String, Object?> _user(String email) => {
        'id': 'user-$email',
        'aud': 'authenticated',
        'email': email,
        'created_at': '2026-11-12T10:00:00Z',
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'identities': [
          {'id': '1', 'user_id': 'user-$email', 'provider': 'email', 'identity_id': '1'}
        ],
        if (confirmed.contains(email)) 'email_confirmed_at': '2026-11-12T10:01:00Z',
      };

  Map<String, Object?> _session(String email) => {
        'access_token': 'token-$email',
        'token_type': 'bearer',
        'expires_in': 3600,
        'refresh_token': 'refresh',
        'user': _user(email),
      };

  String? _signedIn;

  Future<http.Response> handle(http.Request req) async {
    if (offline) throw http.ClientException('offline');
    final body = req.body.isEmpty ? <String, Object?>{} : jsonDecode(req.body) as Map<String, Object?>;
    final path = req.url.path.replaceFirst('/auth/v1', '');
    calls.add((path, body));
    final email = body['email'] as String?;
    switch (path) {
      case '/signup':
        if (passwords.containsKey(email)) {
          // Supabase never says which emails exist: a user with no identity.
          return _json(200, {..._user(email!), 'identities': <Object>[]});
        }
        passwords[email!] = body['password']! as String;
        return _json(200, _user(email));
      case '/token':
        if (passwords[email] != body['password']) return _error(400, 'invalid_credentials');
        if (!confirmed.contains(email)) return _error(400, 'email_not_confirmed');
        _signedIn = email;
        return _json(200, _session(email!));
      case '/recover':
      case '/resend':
        return _json(200, <String, Object?>{});
      case '/verify':
        if (body['token'] != resetCode) return _error(403, 'otp_expired');
        _signedIn = email;
        return _json(200, _session(email!));
      case '/user':
        if (passwords[_signedIn] == body['password']) return _error(422, 'same_password');
        passwords[_signedIn!] = body['password']! as String;
        return _json(200, _user(_signedIn!));
    }
    return _json(404, {'msg': 'not found'});
  }
}

void main() {
  late AppDatabase database;
  late _Auth server;
  late SupabaseAuthRepository repo;
  int? session;

  setUp(() {
    database = AppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    server = _Auth();
    session = null;
    final local = SqliteAuthRepository(
      database,
      sms: _NoSms(),
      onSignedIn: (id) async => session = id,
      userId: () => session,
    );
    final client = GoTrueClient(
      url: 'http://supabase.test/auth/v1',
      httpClient: MockClient(server.handle),
      flowType: AuthFlowType.implicit,
      autoRefreshToken: false,
    );
    repo = SupabaseAuthRepository(() async => client, local,
        redirectTo: 'http://localhost:5000/', checkEvery: Duration.zero);
  });

  tearDown(() => database.close());

  test('sign-up asks Supabase to send the link; AUTH-04 continues once it is opened', () async {
    await repo.signUp(email: ' Alaa.B@Email.TN ', password: 'Marsa2026');
    final (path, body) = server.calls.single;
    expect(path, '/signup');
    expect(body['email'], 'alaa.b@email.tn');
    expect(session, isNotNull, reason: 'the phone copy is signed in right away');

    expect(await repo.isEmailVerified(), isFalse);
    server.confirmed.add('alaa.b@email.tn');
    expect(await repo.isEmailVerified(), isTrue);

    await repo.resendVerificationEmail();
    expect(server.calls.last.$1, '/resend');
  });

  test('AUTH-04 asks Supabase at most every 12 s (its sign-in rate limit)', () async {
    final local = SqliteAuthRepository(database, sms: _NoSms(), onSignedIn: (_) async {}, userId: () => null);
    final client = GoTrueClient(
      url: 'http://supabase.test/auth/v1',
      httpClient: MockClient(server.handle),
      flowType: AuthFlowType.implicit,
      autoRefreshToken: false,
    );
    final slow = SupabaseAuthRepository(() async => client, local);
    await slow.signUp(email: 'alaa.b@email.tn', password: 'Marsa2026');
    await slow.isEmailVerified();
    await slow.isEmailVerified();
    await slow.isEmailVerified();
    expect(server.calls.where((c) => c.$1 == '/token'), hasLength(1));
  });

  test('an address that already has an account is refused', () async {
    server.passwords['alaa.b@email.tn'] = 'Marsa2026';
    await expectLater(repo.signUp(email: 'alaa.b@email.tn', password: 'Autre2026'),
        throwsA(isA<EmailAlreadyUsed>()));
  });

  test('sign-in: wrong passwords count down; an unconfirmed account still opens the app', () async {
    server.passwords['alaa.b@email.tn'] = 'Marsa2026';
    await expectLater(repo.signIn(email: 'alaa.b@email.tn', password: 'faux'),
        throwsA(isA<InvalidCredentials>().having((e) => e.attemptsLeft, 'attemptsLeft', 4)));

    await repo.signIn(email: 'alaa.b@email.tn', password: 'Marsa2026');
    expect(session, isNotNull);
    expect(await repo.isEmailVerified(), isFalse);
  });

  test('reset: code by email, wrong codes count down, then a new password', () async {
    server.passwords['alaa.b@email.tn'] = 'Marsa2026';
    server.confirmed.add('alaa.b@email.tn');
    await repo.sendPasswordResetCode('Alaa.B@email.tn');
    expect(server.calls.last.$1, '/recover');
    expect(server.calls.last.$2['email'], 'alaa.b@email.tn');

    await expectLater(repo.verifyPasswordResetCode('000000'),
        throwsA(isA<InvalidCode>().having((e) => e.attemptsLeft, 'attemptsLeft', 2)));
    await repo.verifyPasswordResetCode('123456');

    await expectLater(repo.resetPassword('Marsa2026'), throwsA(isA<SamePassword>()));
    await repo.resetPassword('Lac2026!');
    expect(server.passwords['alaa.b@email.tn'], 'Lac2026!');

    // The phone's copy takes the new password too (offline sign-in).
    server.offline = true;
    await repo.signIn(email: 'alaa.b@email.tn', password: 'Lac2026!');
    expect(session, isNotNull);
  });

  test('back from Google: the phone copy is made and signed in once', () async {
    User user({String provider = 'google', bool anonymous = false}) => User(
          id: 'g-1',
          appMetadata: {'provider': provider},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: '2026-11-12T10:00:00Z',
          email: 'Alaa.B@gmail.com',
          isAnonymous: anonymous,
        );

    expect(await repo.adoptOAuthUser(user(anonymous: true)), isNull);
    expect(await repo.adoptOAuthUser(user(provider: 'email')), isNull);
    expect(session, isNull);

    expect(await repo.adoptOAuthUser(user()), 'alaa.b@gmail.com');
    expect(session, isNotNull);
    // Coming back again (a reload) changes nothing.
    expect(await repo.adoptOAuthUser(user()), isNull);
  });

  test('offline: sign-up says so; sign-in uses the phone copy', () async {
    server.offline = true;
    await expectLater(repo.signUp(email: 'alaa.b@email.tn', password: 'Marsa2026'),
        throwsA(isA<OfflineException>()));
    await expectLater(repo.signIn(email: 'inconnu@email.tn', password: 'Marsa2026'),
        throwsA(isA<InvalidCredentials>()));
  });
}
