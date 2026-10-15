import 'auth_repository.dart';

/// In-memory [AuthRepository] with the rules of the designs:
///
/// - `yassine.b@email.tn` / `Marsa2026` already exists (sign-up shows « Un compte existe déjà »).
/// - Any SMS or email code `123456` is right; 3 wrong codes block the code for 10 minutes.
/// - 5 wrong sign-ins lock the account for 15 minutes (AUTH-10).
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.latency = const Duration(milliseconds: 600), DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final Duration latency;
  final DateTime Function() _now;

  static const validCode = '123456';
  static const maxSignInAttempts = 5;
  static const maxCodeAttempts = 3;
  static const lockDuration = Duration(minutes: 15);
  static const codeBlockDuration = Duration(minutes: 10);

  final Map<String, String> _accounts = {'yassine.b@email.tn': 'Marsa2026'};
  int _signInFailures = 0;
  DateTime? _lockedUntil;
  int _codeFailures = 0;
  DateTime? _codeBlockedUntil;
  String? _resetEmail;
  Set<UserRole> roles = {};

  Future<void> _wait() => Future<void>.delayed(latency);

  String _key(String email) => email.trim().toLowerCase();

  @override
  Future<void> signUp({
    required String email,
    required String password,
    bool marketingOptIn = false,
  }) async {
    await _wait();
    if (_accounts.containsKey(_key(email))) throw const EmailAlreadyUsed();
    _accounts[_key(email)] = password;
  }

  @override
  Future<void> signInWithProvider(SocialProvider provider) => _wait();

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
    await _wait();
    final locked = lockedUntil();
    if (locked != null) throw AccountLocked(locked);
    if (_accounts[_key(email)] == password) {
      _signInFailures = 0;
      return;
    }
    _signInFailures++;
    if (_signInFailures >= maxSignInAttempts) {
      _lockedUntil = _now().add(lockDuration);
      throw AccountLocked(_lockedUntil!);
    }
    throw InvalidCredentials(maxSignInAttempts - _signInFailures);
  }

  void _resetCodeAttempts() {
    _codeFailures = 0;
    _codeBlockedUntil = null;
  }

  Future<void> _checkCode(String code) async {
    await _wait();
    final blocked = _codeBlockedUntil;
    if (blocked != null && _now().isBefore(blocked)) throw TooManyCodeAttempts(blocked);
    if (code == validCode) {
      _resetCodeAttempts();
      return;
    }
    _codeFailures++;
    if (_codeFailures >= maxCodeAttempts) {
      _codeBlockedUntil = _now().add(codeBlockDuration);
      throw TooManyCodeAttempts(_codeBlockedUntil!);
    }
    throw InvalidCode(maxCodeAttempts - _codeFailures);
  }

  @override
  Future<void> sendPhoneCode(String digits) async {
    await _wait();
    _resetCodeAttempts();
  }

  @override
  Future<void> verifyPhoneCode(String code) => _checkCode(code);

  @override
  Future<void> resendVerificationEmail() => _wait();

  @override
  Future<void> sendPasswordResetCode(String email) async {
    await _wait();
    _resetEmail = _key(email);
    _resetCodeAttempts();
  }

  @override
  Future<void> verifyPasswordResetCode(String code) => _checkCode(code);

  @override
  Future<void> resetPassword(String newPassword) async {
    await _wait();
    final email = _resetEmail;
    if (email != null && _accounts[email] == newPassword) throw const SamePassword();
    if (email != null) _accounts[email] = newPassword;
    _signInFailures = 0;
    _lockedUntil = null;
  }

  @override
  Future<void> saveRoles(Set<UserRole> roles) async {
    await _wait();
    this.roles = {...roles};
  }
}
