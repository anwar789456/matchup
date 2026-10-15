/// The roles one account can hold (AUTH-11), in the order their onboarding runs.
enum UserRole { player, owner, coach, organizer }

/// Why an auth call failed. Screens turn these into the French copy of the designs.
sealed class AuthFailure implements Exception {
  const AuthFailure();
}

/// AUTH-01b: « Un compte existe déjà avec cet email. »
class EmailAlreadyUsed extends AuthFailure {
  const EmailAlreadyUsed();
}

/// AUTH-05b: wrong email or password, with the attempts left before the temporary lock.
class InvalidCredentials extends AuthFailure {
  const InvalidCredentials(this.attemptsLeft);
  final int attemptsLeft;
}

/// AUTH-10: too many failed sign-ins.
class AccountLocked extends AuthFailure {
  const AccountLocked(this.until);
  final DateTime until;
}

/// AUTH-03b / AUTH-07: wrong code, with the attempts left.
class InvalidCode extends AuthFailure {
  const InvalidCode(this.attemptsLeft);
  final int attemptsLeft;
}

/// No attempts left on a code: wait until [retryAt].
class TooManyCodeAttempts extends AuthFailure {
  const TooManyCodeAttempts(this.retryAt);
  final DateTime retryAt;
}

/// AUTH-08: the new password must differ from the old one.
class SamePassword extends AuthFailure {
  const SamePassword();
}

/// The provider's sign-in sheet was closed or failed.
class ProviderSignInFailed extends AuthFailure {
  const ProviderSignInFailed();
}

enum SocialProvider { google, apple }

/// Accounts, sign-in, phone and email verification, password reset and roles.
/// The UI only talks to this interface; a real API implementation replaces the fake later.
abstract interface class AuthRepository {
  Future<void> signUp({required String email, required String password, bool marketingOptIn});

  Future<void> signInWithProvider(SocialProvider provider);

  /// Throws [InvalidCredentials] or [AccountLocked].
  Future<void> signIn({required String email, required String password});

  /// When the current lock ends, or null when sign-in is allowed.
  DateTime? lockedUntil();

  Future<void> sendPhoneCode(String digits);

  /// Throws [InvalidCode] or [TooManyCodeAttempts].
  Future<void> verifyPhoneCode(String code);

  Future<void> resendVerificationEmail();

  Future<void> sendPasswordResetCode(String email);

  /// Throws [InvalidCode] or [TooManyCodeAttempts].
  Future<void> verifyPasswordResetCode(String code);

  /// Throws [SamePassword]. Closes every other session.
  Future<void> resetPassword(String newPassword);

  Future<void> saveRoles(Set<UserRole> roles);
}
