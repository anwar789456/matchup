import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matchup/core/api/api_client.dart';
import 'package:matchup/features/auth/data/api_auth_repository.dart';
import 'package:matchup/features/auth/data/auth_repository.dart';
import 'package:matchup/features/owner_onboarding/data/api_owner_repository.dart';
import 'package:matchup/features/owner_onboarding/data/owner_repository.dart';
import 'package:matchup/features/player_onboarding/data/api_profile_repository.dart';

/// A tiny in-memory stand-in for the utilisateur and reservation modules.
class _FakeBackend {
  final users = <Map<String, dynamic>>[];
  final passwords = <int, String>{};
  final terrains = <Map<String, dynamic>>[];
  final requests = <String>[];

  late final client = MockClient((req) async {
    requests.add('${req.method} ${req.url.path}');
    final body = req.body.isEmpty ? null : jsonDecode(req.body) as Map<String, dynamic>;
    http.Response json(Object o, [int status = 200]) => http.Response(jsonEncode(o), status,
        headers: {'content-type': 'application/json; charset=utf-8'});
    final path = req.url.path.replaceFirst('/api/', '');

    if (path == 'utilisateur/utilisateurs' && req.method == 'POST') {
      if (users.any((u) => u['email'] == body!['email'])) {
        return json({'message': 'Un compte existe déjà avec cet email.'}, 409);
      }
      final user = {'id': users.length + 1, 'email': body!['email'], 'role': 'joueur'};
      users.add(user);
      passwords[user['id'] as int] = body['motDePasse'] as String;
      return json(user, 201);
    }
    if (path == 'utilisateur/utilisateurs/login') {
      final user = users.where((u) => u['email'] == body!['email']).firstOrNull;
      if (user == null || passwords[user['id']] != body!['motDePasse']) {
        return json({'message': 'Email ou mot de passe incorrect.'}, 401);
      }
      return json(user);
    }
    if (path == 'utilisateur/utilisateurs' && req.method == 'GET') {
      final q = req.url.queryParameters;
      return json(users
          .where((u) => q.entries.every((e) => u[e.key] == e.value))
          .toList());
    }
    final patchUser = RegExp(r'^utilisateur/utilisateurs/(\d+)$').firstMatch(path);
    if (patchUser != null && req.method == 'PATCH') {
      final id = int.parse(patchUser.group(1)!);
      final user = users.firstWhere((u) => u['id'] == id);
      if (body!.containsKey('motDePasse')) passwords[id] = body['motDePasse'] as String;
      user.addAll({...body}..remove('motDePasse'));
      return json(user);
    }
    if (path == 'reservation/terrains' && req.method == 'POST') {
      terrains.add({'id': terrains.length + 1, ...body!});
      return json(terrains.last, 201);
    }
    return json({'message': 'not found'}, 404);
  });

  ApiClient get api => ApiClient(client: client, baseUrl: 'http://test/api');
}

void main() {
  late _FakeBackend backend;
  int? session;
  late ApiAuthRepository auth;

  setUp(() {
    backend = _FakeBackend();
    session = null;
    auth = ApiAuthRepository(backend.api, onSignedIn: (id) async => session = id);
  });

  test('sign-up creates the account and signs in; a second sign-up is refused', () async {
    await auth.signUp(email: 'yassine.b@email.tn', password: 'Marsa2026');
    expect(session, 1);
    expect(backend.users.single['email'], 'yassine.b@email.tn');
    expect(
      () => auth.signUp(email: 'yassine.b@email.tn', password: 'Marsa2026'),
      throwsA(isA<EmailAlreadyUsed>()),
    );
  });

  test('wrong passwords count down, then lock (AUTH-05b, AUTH-10)', () async {
    await auth.signUp(email: 'yassine.b@email.tn', password: 'Marsa2026');
    for (var left = 4; left >= 1; left--) {
      await expectLater(
        auth.signIn(email: 'yassine.b@email.tn', password: 'nope'),
        throwsA(isA<InvalidCredentials>().having((e) => e.attemptsLeft, 'left', left)),
      );
    }
    await expectLater(
      auth.signIn(email: 'yassine.b@email.tn', password: 'nope'),
      throwsA(isA<AccountLocked>()),
    );
  });

  test('roles, phone and password reset reach the account', () async {
    await auth.signUp(email: 'yassine.b@email.tn', password: 'Marsa2026');
    await auth.sendPhoneCode('20123456');
    await auth.saveRoles({UserRole.coach, UserRole.owner});
    expect(backend.users.single['telephone'], '20123456');
    expect(backend.users.single['role'], 'proprietaire');

    await auth.sendPasswordResetCode('yassine.b@email.tn');
    await expectLater(auth.resetPassword('Marsa2026'), throwsA(isA<SamePassword>()));
    await auth.resetPassword('Lac2-2026');
    await auth.signIn(email: 'yassine.b@email.tn', password: 'Lac2-2026');
    expect(session, 1);
  });

  test('pseudo availability and profile save', () async {
    await auth.signUp(email: 'yassine.b@email.tn', password: 'Marsa2026');
    final profile = ApiProfileRepository(backend.api, userId: () => session);
    expect(await profile.isPseudoAvailable('yassine.b'), isTrue);
    await profile.saveProfile(pseudo: 'yassine.b', fullName: 'Yassine Belhadj');
    expect(backend.users.single['prenom'], 'Yassine');
    expect(backend.users.single['nom'], 'Belhadj');
    expect(await profile.isPseudoAvailable('yassine.b'), isTrue); // it's mine

    final other = ApiProfileRepository(backend.api, userId: () => 99);
    expect(await other.isPseudoAvailable('yassine.b'), isFalse);
  });

  test('starting the owner trial publishes every court', () async {
    final draft = await const FakeOwnerRepository().start();
    await ApiOwnerRepository(backend.api, userId: () => 7).startTrial(draft);
    expect(backend.terrains.map((t) => t['nom']), ['Terrain 1', 'Terrain 2', 'Terrain 3']);
    expect(backend.terrains.first['prixHeure'], 120);
    expect(backend.terrains.last['interieur'], isTrue);
    expect(backend.terrains.every((t) => t['proprietaireId'] == 7), isTrue);
  });

  test('API errors carry the NestJS message', () async {
    await expectLater(
      backend.api.get('nowhere'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)),
    );
  });
}
