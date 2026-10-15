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
import 'features/coach_onboarding/controllers/coach_controller.dart';
import 'features/coach_onboarding/screens/certification_screen.dart';
import 'features/coach_onboarding/screens/coach_dashboard_screen.dart';
import 'features/coach_onboarding/screens/coach_profile_screen.dart';
import 'features/common/widgets/pro_gate.dart';
import 'features/home/screens/home_screen.dart';
import 'features/onboarding/screens/splash_screen.dart';
import 'features/organizer_onboarding/controllers/organizer_controller.dart';
import 'features/organizer_onboarding/screens/organisation_screen.dart';
import 'features/organizer_onboarding/screens/organizer_dashboard_screen.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'features/owner_onboarding/controllers/owner_controller.dart';
import 'features/owner_onboarding/screens/address_screen.dart';
import 'features/owner_onboarding/screens/company_screen.dart';
import 'features/owner_onboarding/screens/courts_screen.dart';
import 'features/owner_onboarding/screens/hours_screen.dart';
import 'features/owner_onboarding/screens/owner_dashboard_screen.dart';
import 'features/owner_onboarding/screens/payout_screen.dart';
import 'features/owner_onboarding/screens/photos_screen.dart';
import 'features/owner_onboarding/screens/plan_screen.dart';
import 'features/owner_onboarding/screens/prices_screen.dart';
import 'features/player_onboarding/screens/availability_screen.dart';
import 'features/player_onboarding/screens/level_result_screen.dart';
import 'features/player_onboarding/screens/location_denied_screen.dart';
import 'features/player_onboarding/screens/location_screen.dart';
import 'features/player_onboarding/screens/notifications_screen.dart';
import 'features/player_onboarding/screens/position_screen.dart';
import 'features/player_onboarding/screens/profile_screen.dart';
import 'features/player_onboarding/screens/questionnaire_screen.dart';
import 'features/player_onboarding/screens/sports_screen.dart';
import 'features/player_onboarding/screens/zones_screen.dart';
import 'theme/theme.dart';

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

  // Player onboarding (phase 3).
  static const playerSports = '/ply/sports'; // PLY-01
  static String playerQuestions(MuSport sport) => '/ply/level/${sport.name}/questions'; // PLY-02
  static String playerLevel(MuSport sport) => '/ply/level/${sport.name}'; // PLY-03
  static const playerPosition = '/ply/position'; // PLY-04
  static const playerAvailability = '/ply/availability'; // PLY-05
  static const playerLocation = '/ply/location'; // PLY-06
  static const playerZones = '/ply/zones'; // PLY-07
  static const playerLocationDenied = '/ply/location-denied'; // PLY-08
  static const playerNotifications = '/ply/notifications'; // PLY-09
  static const playerProfile = '/ply/profile'; // PLY-10
  static const home = '/home'; // PLY-11

  // Pro onboardings (phase 4).
  static const ownerCompany = '/own/company'; // OWN-01
  static const ownerAddress = '/own/address'; // OWN-02
  static const ownerCourts = '/own/courts'; // OWN-03
  static const ownerHours = '/own/hours'; // OWN-04
  static const ownerPrices = '/own/prices'; // OWN-05
  static const ownerPhotos = '/own/photos'; // OWN-06
  static const ownerPayout = '/own/payout'; // OWN-07
  static const ownerPlan = '/own/plan'; // OWN-08
  static const ownerDashboard = '/own/dashboard'; // OWN-09
  static const coachProfile = '/coa/profile'; // COA-01
  static const coachCertification = '/coa/certification'; // COA-02
  static const coachDashboard = '/coa/dashboard'; // COA-03
  static const organizerOrganisation = '/org/organisation'; // ORG-01
  static const organizerDashboard = '/org/dashboard'; // ORG-02

  /// The owner wizard, in order.
  static const owner = [
    ownerCompany,
    ownerAddress,
    ownerCourts,
    ownerHours,
    ownerPrices,
    ownerPhotos,
    ownerPayout,
    ownerPlan,
  ];

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

MuSport _sport(GoRouterState state) =>
    MuSport.values.where((s) => s.name == state.pathParameters['sport']).firstOrNull ??
    MuSport.football;

GoRoute _route(String path, Widget Function(GoRouterState state) build) =>
    GoRoute(path: path, builder: (context, state) => build(state));

/// A pro screen, once its draft has loaded.
GoRoute _owner(String path, Widget screen) =>
    _route(path, (_) => ProGate(provider: ownerProvider, child: screen));
GoRoute _coach(String path, Widget screen) =>
    _route(path, (_) => ProGate(provider: coachProvider, child: screen));
GoRoute _organizer(String path, Widget screen) =>
    _route(path, (_) => ProGate(provider: organizerProvider, child: screen));

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
      _route(Routes.playerSports, (_) => const SportsScreen()),
      _route('/ply/level/:sport/questions', (s) => QuestionnaireScreen(sport: _sport(s))),
      _route('/ply/level/:sport', (s) => LevelResultScreen(sport: _sport(s))),
      _route(Routes.playerPosition, (_) => const PositionScreen()),
      _route(Routes.playerAvailability, (_) => const AvailabilityScreen()),
      _route(Routes.playerLocation, (_) => const LocationScreen()),
      _route(Routes.playerZones, (_) => const ZonesScreen()),
      _route(Routes.playerLocationDenied, (_) => const LocationDeniedScreen()),
      _route(Routes.playerNotifications, (_) => const NotificationsScreen()),
      _route(Routes.playerProfile, (_) => const ProfileScreen()),
      _route(Routes.home, (_) => const HomeScreen()),
      _owner(Routes.ownerCompany, const CompanyScreen()),
      _owner(Routes.ownerAddress, const AddressScreen()),
      _owner(Routes.ownerCourts, const CourtsScreen()),
      _owner(Routes.ownerHours, const HoursScreen()),
      _owner(Routes.ownerPrices, const PricesScreen()),
      _owner(Routes.ownerPhotos, const PhotosScreen()),
      _owner(Routes.ownerPayout, const PayoutScreen()),
      _owner(Routes.ownerPlan, const PlanScreen()),
      _owner(Routes.ownerDashboard, const OwnerDashboardScreen()),
      _coach(Routes.coachProfile, const CoachProfileScreen()),
      _coach(Routes.coachCertification, const CertificationScreen()),
      _coach(Routes.coachDashboard, const CoachDashboardScreen()),
      _organizer(Routes.organizerOrganisation, const OrganisationScreen()),
      _organizer(Routes.organizerDashboard, const OrganizerDashboardScreen()),
      if (kDebugMode) _route(Routes.gallery, (_) => const GalleryScreen()),
    ],
  );
});
