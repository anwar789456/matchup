import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/connectivity.dart';
import 'auth_repository.dart';
import 'fake_auth_repository.dart';
import 'sqlite_auth_repository.dart';

/// [AuthRepository] on Supabase Auth, used when the app runs with `supabase.json`. Supabase owns
/// the email and password and sends the emails (templates in `supabase/emails/`):
/// - AUTH-04: the confirmation link of a new account;
/// - AUTH-06 → 08: the 6-digit reset code, checked with `verifyOTP(type: recovery)`.
///
/// The phone keeps its copy of the account in [local], which the rest of the app reads, plus the
/// SMS code (AUTH-02/03), the sign-in lock (AUTH-05b, AUTH-10) and the roles. Once the email is
/// confirmed, the device's Supabase session is this account, so the synced rows follow it.
///
/// No connection throws [OfflineException]; Supabase failing throws [ServerException].
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(
    this._auth,
    this.local, {
    this.ready,
    String? redirectTo,
    this.checkEvery = const Duration(seconds: 12),
  }) : _redirectTo = redirectTo ?? (kIsWeb ? '${Uri.base.origin}/' : null);

  final Future<GoTrueClient> Function() _auth;
  final SqliteAuthRepository local;

  /// The shortest time between two real checks of [isEmailVerified].
  final Duration checkEvery;

  /// Waits for Supabase (and its device session) before a call; false: offline.
  final Future<bool> Function()? ready;

  /// Where the confirmation link sends the browser back (the running web app); the project's
  /// Site URL when null.
  final String? _redirectTo;

  /// The sign-up (or unconfirmed sign-in) waiting for its link: AUTH-04 retries the sign-in
  /// with it until Supabase says the email is confirmed.
  ({String email, String password})? _pending;

  String? _resetEmail;
  int _resetFailures = 0;
  DateTime? _resetBlockedUntil;

  static String _key(String email) => email.trim().toLowerCase();

  /// Runs [call] on the Supabase client: no connection → [OfflineException], Supabase down →
  /// [ServerException]. Other [AuthException]s reach the caller.
  Future<T> _call<T>(Future<T> Function(GoTrueClient auth) call) async {
    if (ready != null && !await ready!()) throw const OfflineException();
    try {
      return await call(await _auth());
    } on AuthRetryableFetchException {
      throw const OfflineException();
    } on http.ClientException {
      throw const OfflineException();
    } on AuthException catch (e) {
      final status = int.tryParse(e.statusCode ?? '');
      if (status != null && status >= 500) {
        throw ServerException(status: status, reference: 'Supabase ${e.code ?? status}');
      }
      rethrow;
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    bool marketingOptIn = false,
  }) async {
    final address = _key(email);
    final AuthResponse res;
    try {
      res = await _call((auth) => auth.signUp(
            email: address,
            password: password,
            emailRedirectTo: _redirectTo,
            data: {'marketing': marketingOptIn},
          ));
    } on AuthException catch (e) {
      if (e.code == 'user_already_exists' || e.code == 'email_exists') throw const EmailAlreadyUsed();
      rethrow;
    }
    // With « Confirm email » on, Supabase answers an existing address with a user that has no
    // identity (it never says which emails have an account): treat it as taken.
    if (res.user != null && (res.user!.identities?.isEmpty ?? false)) {
      throw const EmailAlreadyUsed();
    }
    _pending = res.session == null ? (email: address, password: password) : null;
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
      await _call((auth) => auth.signInWithPassword(email: address, password: password));
      _pending = null;
    } on OfflineException {
      // Offline: the phone's copy of the account still opens the app.
      await local.signIn(email: address, password: password);
      return;
    } on AuthException catch (e) {
      if (e.code == 'email_not_confirmed') {
        // Right password, link not opened yet: the app opens, the reminder stays (STA-06).
        _pending = (email: address, password: password);
      } else if (e.code == 'invalid_credentials' || e.statusCode == '400') {
        local.failSignIn();
      } else {
        rethrow;
      }
    }
    await local.adoptAccount(address, password);
  }

  @override
  Future<void> sendPhoneCode(String digits) => local.sendPhoneCode(digits);

  @override
  Future<void> verifyPhoneCode(String code) => local.verifyPhoneCode(code);

  @override
  Future<void> resendVerificationEmail() async {
    final email = _pending?.email ?? await local.currentEmail();
    if (email == null) return;
    try {
      await _call((auth) => auth.resend(type: OtpType.signup, email: email, emailRedirectTo: _redirectTo));
    } on AuthException catch (e) {
      if (e.code == 'over_email_send_rate_limit') {
        throw CodeRequestTooSoon(DateTime.now().add(const Duration(minutes: 1)));
      }
      rethrow;
    }
  }

  /// True once the link was opened: the pending sign-in then goes through and the device's
  /// session becomes this account. Asked every few seconds by AUTH-04.
  @override
  Future<bool> isEmailVerified() async {
    final pending = _pending;
    if (pending == null) {
      final user = (await _auth()).currentUser;
      return user != null && !user.isAnonymous && user.emailConfirmedAt != null;
    }
    // Supabase allows about 30 sign-ins per 5 minutes per IP: ask at most every 12 s.
    final now = DateTime.now();
    final last = _lastCheck;
    if (last != null && now.difference(last) < checkEvery) return false;
    _lastCheck = now;
    try {
      await _call((auth) => auth.signInWithPassword(email: pending.email, password: pending.password));
    } on AuthException catch (e) {
      if (e.code == 'email_not_confirmed') return false;
      rethrow;
    }
    _pending = null;
    return true;
  }

  DateTime? _lastCheck;

  @override
  Future<void> sendPasswordResetCode(String email) async {
    _resetEmail = _key(email);
    try {
      // Same answer for an unknown email: Supabase never says which emails have an account.
      await _call((auth) => auth.resetPasswordForEmail(_resetEmail!));
    } on AuthException catch (e) {
      if (e.code == 'over_email_send_rate_limit') {
        throw CodeRequestTooSoon(DateTime.now().add(const Duration(minutes: 1)));
      }
      rethrow;
    }
  }

  @override
  Future<void> verifyPasswordResetCode(String code) async {
    final blocked = _resetBlockedUntil;
    if (blocked != null && blocked.isAfter(DateTime.now())) throw TooManyCodeAttempts(blocked);
    try {
      // A right code signs the device in as this account, so updateUser can set the password.
      await _call((auth) => auth.verifyOTP(
            email: _resetEmail ?? '',
            token: code.trim(),
            type: OtpType.recovery,
          ));
      _resetFailures = 0;
    } on AuthException catch (e) {
      if (e.code != 'otp_expired' && e.statusCode != '403' && e.statusCode != '400') rethrow;
      _resetFailures++;
      final left = FakeAuthRepository.maxCodeAttempts - _resetFailures;
      if (left <= 0) {
        _resetFailures = 0;
        _resetBlockedUntil = DateTime.now().add(FakeAuthRepository.codeBlockDuration);
        throw TooManyCodeAttempts(_resetBlockedUntil!);
      }
      throw InvalidCode(left);
    }
  }

  @override
  Future<void> resetPassword(String newPassword) async {
    try {
      await _call((auth) => auth.updateUser(UserAttributes(password: newPassword)));
    } on AuthException catch (e) {
      if (e.code == 'same_password') throw const SamePassword();
      rethrow;
    }
    // The phone's copy signs in with the new password too.
    final email = _resetEmail;
    if (email != null) await local.storePassword(email, newPassword, create: true);
  }

  @override
  Future<void> saveRoles(Set<UserRole> roles) => local.saveRoles(roles);
}
