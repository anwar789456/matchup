import '../../../core/api/api_client.dart';
import 'auth_repository.dart';
import 'fake_auth_repository.dart';

/// [AuthRepository] on the team's backend (module utilisateur): accounts, sign-in, roles, the
/// confirmation email (AUTH-04) and the emailed reset code (AUTH-06 to 08) are real. SMS codes
/// and Google/Apple sign-in stay simulated by [FakeAuthRepository] (code `123456`).
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
  String? _resetCode;
  int _signInFailures = 0;
  DateTime? _lockedUntil;

  static const _users = 'utilisateur/utilisateurs';
  static const _account = 'utilisateur/compte';

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
  Future<void> resendVerificationEmail() async {
    final email = _email;
    if (email == null) return;
    await _api.post('$_account/verification/envoyer', {'email': email});
  }

  @override
  Future<void> sendPasswordResetCode(String email) async {
    _resetEmail = email.trim();
    _resetCode = null;
    await _api.post('$_account/mot-de-passe/oublie', {'email': _resetEmail});
  }

  /// Maps the backend's code errors to the screens' failures (AUTH-07).
  Never _codeFailure(ApiException e) {
    final data = e.data is Map<String, dynamic> ? e.data! as Map<String, dynamic> : const {};
    if (e.statusCode == 429) {
      final retry = DateTime.tryParse('${data['reessayerA']}') ??
          _now().add(FakeAuthRepository.codeBlockDuration);
      throw TooManyCodeAttempts(retry);
    }
    if (e.statusCode == 400) throw InvalidCode((data['essaisRestants'] as num?)?.toInt() ?? 0);
    throw e;
  }

  @override
  Future<void> verifyPasswordResetCode(String code) async {
    try {
      await _api.post('$_account/mot-de-passe/verifier', {'email': _resetEmail, 'code': code});
      _resetCode = code;
    } on ApiException catch (e) {
      _codeFailure(e);
    }
  }

  @override
  Future<void> resetPassword(String newPassword) async {
    try {
      await _api.post('$_account/mot-de-passe/reinitialiser', {
        'email': _resetEmail,
        'code': _resetCode,
        'motDePasse': newPassword,
      });
    } on ApiException catch (e) {
      if (e.statusCode == 409) throw const SamePassword();
      _codeFailure(e);
    }
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
