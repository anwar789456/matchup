import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/session.dart';
import '../data/api_auth_repository.dart';
import '../data/auth_repository.dart';

/// The auth backend: the team's API (module utilisateur). Tests override it with the fake.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiAuthRepository(
    ref.read(apiClientProvider),
    onSignedIn: (id) => ref.read(sessionProvider.notifier).signIn(id),
  ),
);

/// What the sign-up and reset flows carry from one screen to the next.
@immutable
class AuthFlowState {
  const AuthFlowState({this.email, this.phoneDigits, this.resetEmail});

  /// Email of the account being created or signed in (AUTH-04 shows it).
  final String? email;

  /// The 8 digits the SMS code was sent to (AUTH-03 shows them masked).
  final String? phoneDigits;

  /// Email the reset code was sent to (AUTH-07).
  final String? resetEmail;

  AuthFlowState copyWith({String? email, String? phoneDigits, String? resetEmail}) => AuthFlowState(
        email: email ?? this.email,
        phoneDigits: phoneDigits ?? this.phoneDigits,
        resetEmail: resetEmail ?? this.resetEmail,
      );
}

class AuthFlowController extends Notifier<AuthFlowState> {
  @override
  AuthFlowState build() => const AuthFlowState();

  void setEmail(String email) => state = state.copyWith(email: email.trim());

  void setPhone(String digits) => state = state.copyWith(phoneDigits: digits);

  void setResetEmail(String email) => state = state.copyWith(resetEmail: email.trim());
}

final authFlowProvider =
    NotifierProvider<AuthFlowController, AuthFlowState>(AuthFlowController.new);
