import '../../../core/api/api_client.dart';
import 'auth_repository.dart';
import 'sqlite_auth_repository.dart';

/// [AuthRepository] on the backend's `utilisateur` module, used when the app is built with
/// `API_URL`. The server owns the email and password and sends the emails: the confirmation link
/// (AUTH-04) and the reset code (AUTH-06 → 08). The phone keeps its copy of the account in
/// [local], which the rest of the app reads, plus the SMS code (AUTH-02/03), the sign-in lock
/// (AUTH-05b, AUTH-10) and the roles.
///
/// No connection throws `OfflineException`; a server error throws `ServerException`.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, this.local);

  final ApiClient _api;
  final SqliteAuthRepository local;

  String? _resetEmail;
  String? _resetCode;

  static String _key(String email) => email.trim().toLowerCase();

  @override
  Future<void> signUp({
    required String email,
    required String password,
    bool marketingOptIn = false,
  }) async {
    final address = _key(email);
    try {
      // The server sends the confirmation email itself.
      await _api.post('/utilisateurs', {'email': address, 'motDePasse': password});
    } on ApiError catch (e) {
      if (e.status == 409) throw const EmailAlreadyUsed();
      rethrow;
    }
    await local.adoptAccount(address, password);
  }

  @override
  Future<void> signInWithProvider(SocialProvider provider) => local.signInWithProvider(provider);

  @override
  DateTime? lockedUntil() => local.lockedUntil();

  @override
  Future<void> signIn({required String email, required String password}) async {
    final locked = local.lockedUntil();
    if (locked != null) throw AccountLocked(locked);
    final address = _key(email);
    try {
      await _api.post('/utilisateurs/login', {'email': address, 'motDePasse': password});
    } on ApiError catch (e) {
      // 401: wrong email or password; 400: not even an email.
      if (e.status == 401 || e.status == 400) local.failSignIn();
      rethrow;
    }
    await local.adoptAccount(address, password);
  }

  @override
  Future<void> sendPhoneCode(String digits) => local.sendPhoneCode(digits);

  @override
  Future<void> verifyPhoneCode(String code) => local.verifyPhoneCode(code);

  @override
  Future<void> resendVerificationEmail() async {
    final email = await local.currentEmail();
    if (email == null) return;
    await _api.post('/compte/verification/envoyer', {'email': email});
  }

  @override
  Future<void> sendPasswordResetCode(String email) async {
    _resetEmail = _key(email);
    _resetCode = null;
    // Same answer for an unknown email: the server never says which emails have an account.
    await _api.post('/compte/mot-de-passe/oublie', {'email': _resetEmail});
  }

  @override
  Future<void> verifyPasswordResetCode(String code) async {
    await _codeCall('/compte/mot-de-passe/verifier', {'email': _resetEmail ?? '', 'code': code.trim()});
    _resetCode = code.trim();
  }

  @override
  Future<void> resetPassword(String newPassword) async {
    final email = _resetEmail ?? '';
    try {
      await _codeCall('/compte/mot-de-passe/reinitialiser', {
        'email': email,
        'code': _resetCode ?? '',
        'motDePasse': newPassword,
      });
    } on ApiError catch (e) {
      if (e.status == 409) throw const SamePassword();
      rethrow;
    }
    // The phone's copy signs in with the new password too.
    await local.storePassword(email, newPassword);
  }

  /// A call that checks a reset code: 400 → [InvalidCode] with the attempts left, 429 →
  /// [TooManyCodeAttempts] until `reessayerA`.
  Future<void> _codeCall(String path, Map<String, Object?> body) async {
    try {
      await _api.post(path, body);
    } on ApiError catch (e) {
      switch (e.status) {
        case 400:
          final left = e.body['essaisRestants'];
          throw InvalidCode(left is int ? left : 0);
        case 429:
          final until = DateTime.tryParse('${e.body['reessayerA']}')?.toLocal();
          throw TooManyCodeAttempts(until ?? DateTime.now().add(const Duration(minutes: 10)));
      }
      rethrow;
    }
  }

  @override
  Future<void> saveRoles(Set<UserRole> roles) => local.saveRoles(roles);
}
