import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../core/sms/sms_sender.dart';
import 'auth_repository.dart';
import 'fake_auth_repository.dart';

/// [AuthRepository] on the phone's database (`utilisateurs`, `codes`).
///
/// - Passwords are stored as SHA-256 of a random salt + the password, never in clear.
/// - The SMS code (AUTH-02/03) leaves through [SmsSender] (textbee.dev); the reset code
///   (AUTH-06/07) goes by SMS to the account's verified number. Without a textbee key, or without
///   a verified number for a reset, the code is `123456`.
/// - Codes are stored hashed: 3 wrong codes block for 10 minutes; one SMS per 30 s and 5 per
///   hour per account.
/// - There is no mail server: the confirmation email (AUTH-04) is not sent.
/// - Google/Apple sign-in stays simulated by [FakeAuthRepository].
class SqliteAuthRepository implements AuthRepository {
  SqliteAuthRepository(
    this._database, {
    required this.sms,
    required this.onSignedIn,
    this.userId,
    DateTime Function()? now,
    Random? random,
  })  : _now = now ?? DateTime.now,
        _random = random ?? Random.secure(),
        _simulated = FakeAuthRepository(latency: const Duration(milliseconds: 300), now: now);

  final AppDatabase _database;
  final SmsSender sms;

  /// Receives the account id after sign-up or sign-in.
  final Future<void> Function(int userId) onSignedIn;

  /// The account kept signed in on the device (after a restart).
  final int? Function()? userId;

  final DateTime Function() _now;
  final Random _random;
  final FakeAuthRepository _simulated;

  static const smsValidity = Duration(minutes: 10);
  static const resetValidity = Duration(minutes: 15);
  static const smsInterval = Duration(seconds: 30);
  static const smsPerHour = 5;
  static const simulatedCode = FakeAuthRepository.validCode;

  int? _userId;
  String? _email;
  String? _phone;
  String? _resetEmail;
  String? _resetCode;
  int _signInFailures = 0;
  DateTime? _lockedUntil;

  Future<Database> get _db => _database.db;

  static String _key(String email) => email.trim().toLowerCase();
  static String _sha256(String value) => sha256.convert(utf8.encode(value)).toString();
  static String hashPassword(String salt, String password) => _sha256('$salt:$password');

  String _salt() => base64Url.encode(List.generate(16, (_) => _random.nextInt(256)));
  String _sixDigits() => _random.nextInt(1000000).toString().padLeft(6, '0');
  String _iso(DateTime d) => d.toIso8601String();

  Future<void> _signedIn(int id, String email) async {
    _userId = id;
    _email = email;
    await onSignedIn(id);
  }

  int? get _currentId => _userId ?? userId?.call();

  /// The signed-in account's email, read back from the database after a restart.
  Future<String?> _currentEmail() async {
    if (_email != null) return _email;
    final id = _currentId;
    if (id == null) return null;
    final rows = await (await _db)
        .query('utilisateurs', columns: ['email'], where: 'id = ?', whereArgs: [id]);
    return _email = rows.firstOrNull?['email'] as String?;
  }

  Future<Map<String, Object?>?> _user(DatabaseExecutor db, String email) async =>
      (await db.query('utilisateurs', where: 'email = ?', whereArgs: [_key(email)])).firstOrNull;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    bool marketingOptIn = false,
  }) async {
    final db = await _db;
    final address = _key(email);
    if (await _user(db, address) != null) throw const EmailAlreadyUsed();
    final salt = _salt();
    final id = await db.insert('utilisateurs', {
      'email': address,
      'mot_de_passe': hashPassword(salt, password),
      'sel': salt,
      'cree_le': _iso(_now()),
    });
    await _signedIn(id, address);
  }

  @override
  Future<void> signInWithProvider(SocialProvider provider) =>
      _simulated.signInWithProvider(provider);

  @override
  DateTime? lockedUntil() {
    final until = _lockedUntil;
    if (until == null) return null;
    if (_now().isAfter(until)) {
      _lockedUntil = null;
      _signInFailures = 0;
      return null;
    }
    return until;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final locked = lockedUntil();
    if (locked != null) throw AccountLocked(locked);
    final user = await _user(await _db, email);
    if (user != null && user['mot_de_passe'] == hashPassword(user['sel']! as String, password)) {
      _signInFailures = 0;
      await _signedIn(user['id']! as int, user['email']! as String);
      return;
    }
    _signInFailures++;
    if (_signInFailures >= FakeAuthRepository.maxSignInAttempts) {
      _lockedUntil = _now().add(FakeAuthRepository.lockDuration);
      throw AccountLocked(_lockedUntil!);
    }
    throw InvalidCredentials(FakeAuthRepository.maxSignInAttempts - _signInFailures);
  }

  /// Saves a new code for [email] (the older ones are used up) and returns it in clear.
  Future<String> _newCode(
    DatabaseExecutor db,
    String email,
    String usage,
    Duration validity, {
    required bool live,
    String salt = '',
  }) async {
    final code = live ? _sixDigits() : simulatedCode;
    final now = _now();
    await db.update('codes', {'utilise': 1},
        where: 'email = ? AND usage = ? AND utilise = 0', whereArgs: [email, usage]);
    await db.insert('codes', {
      'email': email,
      'usage': usage,
      'hash': _sha256('$salt$code'),
      'expire_le': _iso(now.add(validity)),
      'cree_le': _iso(now),
    });
    return code;
  }

  /// Checks [code] against the latest unused code of [usage] without using it up. Wrong code →
  /// [InvalidCode]; the 3rd wrong one or a blocked code → [TooManyCodeAttempts].
  Future<int> _checkCode(String email, String usage, String code, {String salt = ''}) async {
    final db = await _db;
    final current = (await db.query(
      'codes',
      where: 'email = ? AND usage = ? AND utilise = 0',
      whereArgs: [email, usage],
      orderBy: 'id DESC',
      limit: 1,
    ))
        .firstOrNull;
    final now = _now();
    final blocked = DateTime.tryParse('${current?['bloque_jusqua']}');
    if (blocked != null && blocked.isAfter(now)) throw TooManyCodeAttempts(blocked);
    if (current == null || !DateTime.parse(current['expire_le']! as String).isAfter(now)) {
      throw const InvalidCode(0);
    }
    final id = current['id']! as int;
    if (current['hash'] == _sha256('$salt${code.trim()}')) return id;

    final tries = (current['essais']! as int) + 1;
    if (tries >= FakeAuthRepository.maxCodeAttempts) {
      final until = now.add(FakeAuthRepository.codeBlockDuration);
      await db.update('codes', {'essais': tries, 'bloque_jusqua': _iso(until)},
          where: 'id = ?', whereArgs: [id]);
      throw TooManyCodeAttempts(until);
    }
    await db.update('codes', {'essais': tries}, where: 'id = ?', whereArgs: [id]);
    throw InvalidCode(FakeAuthRepository.maxCodeAttempts - tries);
  }

  @override
  Future<void> sendPhoneCode(String digits) async {
    final email = await _currentEmail();
    if (email == null) return _simulated.sendPhoneCode(digits);
    _phone = digits;
    final db = await _db;
    final now = _now();
    final recent = await db.query(
      'codes',
      columns: ['cree_le'],
      where: "email = ? AND usage = 'telephone' AND cree_le > ?",
      whereArgs: [email, _iso(now.subtract(const Duration(hours: 1)))],
      orderBy: 'id DESC',
    );
    if (recent.isNotEmpty) {
      final last = DateTime.parse(recent.first['cree_le']! as String);
      if (now.difference(last) < smsInterval) throw CodeRequestTooSoon(last.add(smsInterval));
      if (recent.length >= smsPerHour) {
        final oldest = DateTime.parse(recent.last['cree_le']! as String);
        throw CodeRequestTooSoon(oldest.add(const Duration(hours: 1)));
      }
    }
    final code = await _newCode(db, email, 'telephone', smsValidity, live: sms.live, salt: '$digits:');
    await sms.send('+216$digits', 'MatchUp : ton code est $code. Il expire dans 10 minutes.');
  }

  @override
  Future<void> verifyPhoneCode(String code) async {
    final email = await _currentEmail();
    final phone = _phone;
    if (email == null || phone == null) return _simulated.verifyPhoneCode(code);
    final id = await _checkCode(email, 'telephone', code, salt: '$phone:');
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update('utilisateurs', {'telephone': phone, 'telephone_verifie': 1},
          where: 'email = ?', whereArgs: [email]);
      await txn.update('codes', {'utilise': 1}, where: 'id = ?', whereArgs: [id]);
    });
  }

  /// No mail server on the phone: the confirmation email is not sent.
  @override
  Future<void> resendVerificationEmail() async {}

  @override
  Future<void> sendPasswordResetCode(String email) async {
    final address = _key(email);
    _resetEmail = address;
    _resetCode = null;
    final db = await _db;
    final user = await _user(db, address);
    // Same answer for an unknown email, so nobody can test which emails have an account.
    if (user == null) return;
    final phone = user['telephone_verifie'] == 1 ? user['telephone'] as String? : null;
    final code = await _newCode(db, address, 'reinitialisation', resetValidity,
        live: sms.live && phone != null);
    if (phone != null) {
      await sms.send('+216$phone', 'MatchUp : ton code pour changer de mot de passe est $code.');
    }
  }

  @override
  Future<void> verifyPasswordResetCode(String code) async {
    await _checkCode(_resetEmail ?? '', 'reinitialisation', code);
    _resetCode = code;
  }

  @override
  Future<void> resetPassword(String newPassword) async {
    final email = _resetEmail ?? '';
    final id = await _checkCode(email, 'reinitialisation', _resetCode ?? '');
    final db = await _db;
    final user = await _user(db, email);
    if (user == null) throw const InvalidCode(0);
    if (user['mot_de_passe'] == hashPassword(user['sel']! as String, newPassword)) {
      throw const SamePassword();
    }
    final salt = _salt();
    await db.transaction((txn) async {
      await txn.update('utilisateurs', {'mot_de_passe': hashPassword(salt, newPassword), 'sel': salt},
          where: 'id = ?', whereArgs: [user['id']]);
      await txn.update('codes', {'utilise': 1}, where: 'id = ?', whereArgs: [id]);
    });
    _signInFailures = 0;
    _lockedUntil = null;
  }

  static String roleName(UserRole role) => switch (role) {
        UserRole.player => 'joueur',
        UserRole.owner => 'proprietaire',
        UserRole.coach => 'coach',
        UserRole.organizer => 'organisateur',
      };

  @override
  Future<void> saveRoles(Set<UserRole> roles) async {
    final id = _currentId;
    if (id == null || roles.isEmpty) return;
    // One role per account: the first onboarding to run.
    final first = UserRole.values.firstWhere(roles.contains);
    final db = await _db;
    await db.update('utilisateurs', {'role': roleName(first)}, where: 'id = ?', whereArgs: [id]);
  }
}
