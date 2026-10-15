import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/screens/account_locked_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/new_password_screen.dart';
import 'features/auth/screens/password_changed_screen.dart';
import 'features/auth/screens/phone_screen.dart';
import 'features/auth/screens/reset_code_screen.dart';
import 'features/auth/screens/role_choice_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/sms_code_screen.dart';
import 'features/auth/screens/verify_email_screen.dart';
import 'features/dev/gallery_screen.dart';
import 'features/dev/pending_screen.dart';
import 'features/onboarding/screens/splash_screen.dart';
import 'features/onboarding/screens/welcome_screen.dart';

/// Route paths, one per screen code (design/screens/SCREENS.md). Error variants (AUTH-01b,
/// 03b, 05b) are states of their screen, not routes.
abstract final class Routes {
  static const splash = '/onb/splash'; // ONB-01
  static const welcome1 = '/onb/welcome-1'; // ONB-02
  static const welcome2 = '/onb/welcome-2'; // ONB-03
  static const welcome3 = '/onb/welcome-3'; // ONB-04
  static const signup = '/auth/signup'; // AUTH-01
  static const phone = '/auth/phone'; // AUTH-02
  static const smsCode = '/auth/sms-code'; // AUTH-03
  static const verifyEmail = '/auth/verify-email'; // AUTH-04
  static const login = '/auth/login'; // AUTH-05
  static const forgotPassword = '/auth/forgot-password'; // AUTH-06
  static const resetCode = '/auth/reset-code'; // AUTH-07
  static const newPassword = '/auth/new-password'; // AUTH-08
  static const passwordChanged = '/auth/password-changed'; // AUTH-09
  static const accountLocked = '/auth/account-locked'; // AUTH-10
  static const roles = '/auth/roles'; // AUTH-11

  // Role onboardings (phases 3 and 4).
  static const playerSports = '/ply/sports'; // PLY-01
  static const ownerCompany = '/own/company'; // OWN-01
  static const coachProfile = '/coa/profile'; // COA-01
  static const organizerOrganisation = '/org/organisation'; // ORG-01

  /// Debug-only widget gallery.
  static const gallery = '/dev/gallery';

  static const welcome = [welcome1, welcome2, welcome3];
}

/// Back arrow: pop when there is a previous screen, else go to the designed back target.
void goBack(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

GoRoute _route(String path, Widget Function(GoRouterState state) build) =>
    GoRoute(path: path, builder: (context, state) => build(state));

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      _route(Routes.splash, (_) => const SplashScreen()),
      for (final (i, path) in Routes.welcome.indexed)
        GoRoute(
          path: path,
          // One screen for the three slides, so swiping and the buttons share one PageView.
          pageBuilder: (context, state) => NoTransitionPage(
            key: const ValueKey('welcome'),
            child: WelcomeScreen(initialPage: i),
          ),
        ),
      _route(Routes.signup, (_) => const SignupScreen()),
      _route(Routes.phone, (_) => const PhoneScreen()),
      _route(Routes.smsCode, (_) => const SmsCodeScreen()),
      _route(Routes.verifyEmail, (_) => const VerifyEmailScreen()),
      _route(Routes.login, (_) => const LoginScreen()),
      _route(Routes.forgotPassword, (_) => const ForgotPasswordScreen()),
      _route(Routes.resetCode, (_) => const ResetCodeScreen()),
      _route(Routes.newPassword, (_) => const NewPasswordScreen()),
      _route(Routes.passwordChanged, (_) => const PasswordChangedScreen()),
      _route(Routes.accountLocked, (_) => const AccountLockedScreen()),
      _route(Routes.roles, (_) => const RoleChoiceScreen()),
      for (final (path, code) in [
        (Routes.playerSports, 'PLY-01 · Sports'),
        (Routes.ownerCompany, 'OWN-01 · Entreprise'),
        (Routes.coachProfile, 'COA-01 · Profil coach'),
        (Routes.organizerOrganisation, 'ORG-01 · Organisation'),
      ])
        _route(path, (_) => PendingScreen(code: code)),
      if (kDebugMode) _route(Routes.gallery, (_) => const GalleryScreen()),
    ],
  );
});
