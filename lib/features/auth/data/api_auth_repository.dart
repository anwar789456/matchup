import '../../../core/api/api_client.dart';
import 'auth_repository.dart';
import 'fake_auth_repository.dart';

/// [AuthRepository] on the team's backend (module utilisateur): accounts, sign-in, password
/// change and roles are real. SMS / email codes and Google/Apple sign-in stay simulated by
/// [FakeAuthRepository] (code `123456`) until the backend sends them.
///
/// The temporary lock after 5 wrong passwords (AUTH-10) is counted on the device.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, {required this.onSignedIn, DateTime Function()? now})
      : _now = now ?? DateTime.now,
        _codes = FakeAuthRepository(latency: const Duration(milliseconds: 300), now: now);

  final ApiClient _api;
  final DateTime Function() _now;
  final FakeAuthRepository _codes;

  /// Receives the account id after sign-up or sign-in.
  final Future<void> Function(int userId) onSignedIn;

  int? _userId;
  String? _email;
  String? _resetEmail;
  int _signInFailures = 0;
  DateTime? _lockedUntil;

  static const _users = 'utilisateur/utilisateurs';

  static String roleName(UserRole role) => switch (role) {
        UserRole.player => 'joueur',
        UserRole.owner => 'proprietaire',
        UserRole.coach => 'coach',
        UserRole.organizer => 'organisateur',
      };

  Future<void> _signedIn(Map<String, dynamic> user) async {
    _userId = user['id'] as int;
    _email = user['email'] as String?;
    await onSignedIn(_userId!);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    bool marketingOptIn = false,
  }) async {
    try {
      final user = await _api.post(_users, {'email': email.trim(), 'motDePasse': password});
      await _signedIn(user as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 409) throw const EmailAlreadyUsed();
      rethrow;
    }
  }

  @override
  Future<void> signInWithProvider(SocialProvider provider) =>
      _codes.signInWithProvider(provider);

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
    try {
      final user =
          await _api.post('$_users/login', {'email': email.trim(), 'motDePasse': password});
      _signInFailures = 0;
      await _signedIn(user as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode != 401 && e.statusCode != 400) rethrow;
      _signInFailures++;
      if (_signInFailures >= FakeAuthRepository.maxSignInAttempts) {
        _lockedUntil = _now().add(FakeAuthRepository.lockDuration);
        throw AccountLocked(_lockedUntil!);
      }
      throw InvalidCredentials(FakeAuthRepository.maxSignInAttempts - _signInFailures);
    }
  }

  @override
  Future<void> sendPhoneCode(String digits) async {
    await _codes.sendPhoneCode(digits);
    final id = _userId;
    if (id != null) await _api.patch('$_users/$id', {'telephone': digits});
  }

  @override
  Future<void> verifyPhoneCode(String code) => _codes.verifyPhoneCode(code);

  @override
  Future<void> resendVerificationEmail() => _codes.resendVerificationEmail();

  @override
  Future<void> sendPasswordResetCode(String email) {
    _resetEmail = email.trim();
    return _codes.sendPasswordResetCode(email);
  }

  @override
  Future<void> verifyPasswordResetCode(String code) => _codes.verifyPasswordResetCode(code);

  @override
  Future<void> resetPassword(String newPassword) async {
    final email = _resetEmail ?? _email;
    if (email == null) return;
    final found = await _api.get(_users, query: {'email': email}) as List<dynamic>;
    if (found.isEmpty) return;
    final id = (found.first as Map<String, dynamic>)['id'] as int;
    try {
      await _api.post('$_users/login', {'email': email, 'motDePasse': newPassword});
      throw const SamePassword();
    } on ApiException {
      // The new password differs from the current one.
    }
    await _api.patch('$_users/$id', {'motDePasse': newPassword});
    _signInFailures = 0;
    _lockedUntil = null;
  }

  @override
  Future<void> saveRoles(Set<UserRole> roles) async {
    final id = _userId;
    if (id == null || roles.isEmpty) return;
    // The backend keeps one role per account: the first onboarding to run.
    final first = UserRole.values.firstWhere(roles.contains);
    await _api.patch('$_users/$id', {'role': roleName(first)});
  }
}
