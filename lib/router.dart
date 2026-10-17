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
import 'features/booking/screens/booking_done_screen.dart';
import 'features/booking/screens/booking_invites_screen.dart';
import 'features/booking/screens/booking_public_screen.dart';
import 'features/booking/screens/booking_summary_screen.dart';
import 'features/booking/screens/booking_type_screen.dart';
import 'features/games/screens/game_screen.dart';
import 'features/games/screens/joined_screen.dart';
import 'features/games/screens/waitlist_screen.dart';
import 'features/matches/screens/booking_detail_screen.dart';
import 'features/matches/screens/matches_screen.dart';
import 'features/matches/screens/score_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/public_profile_screen.dart';
import 'features/settings/screens/account_screen.dart';
import 'features/settings/screens/connected_accounts_screen.dart';
import 'features/settings/screens/delete_account_screen.dart';
import 'features/settings/screens/language_theme_screen.dart';
import 'features/settings/screens/privacy_screen.dart';
import 'features/settings/screens/security_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/common/widgets/coming_soon.dart';
import 'features/common/widgets/pro_gate.dart';
import 'features/explore/controllers/explore_controller.dart';
import 'features/explore/screens/explore_screen.dart';
import 'features/explore/screens/search_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/home/widgets/player_shell.dart';
import 'features/onboarding/screens/splash_screen.dart';
import 'features/organizer_onboarding/controllers/organizer_controller.dart';
import 'features/payments/screens/checkout_screen.dart';
import 'features/payments/data/receipt.dart';
import 'features/payments/screens/payment_result_screens.dart';
import 'features/payments/screens/receipt_screen.dart';
import 'features/subscription/screens/cancel_screens.dart';
import 'features/subscription/screens/change_plan_screen.dart';
import 'features/subscription/screens/offers_screen.dart';
import 'features/subscription/screens/premium_checkout_screen.dart';
import 'features/subscription/screens/premium_welcome_screen.dart';
import 'features/subscription/screens/subscription_screen.dart';
import 'features/payments/screens/split_tracker_screen.dart';
import 'features/wallet/screens/refund_screens.dart';
import 'features/wallet/screens/topup_screen.dart';
import 'features/wallet/screens/wallet_screen.dart';
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
import 'features/venue/screens/slot_screen.dart';
import 'features/venue/screens/venue_screen.dart';
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
  static const home = '/home'; // PLY-11 (the tour, once), then HOM-01 / HOM-02

  // Player core (Milestone 3): the five tabs, then the pages they open.
  static const explore = '/explore'; // EXP-01, EXP-02, EXP-06, EXP-07
  static const exploreVenues = '/explore?tab=terrains'; // EXP-03
  static const exploreSearch = '/explore/search'; // EXP-05
  static const matches = '/matches'; // MAT-01 (phase 7)
  static const training = '/training'; // Milestone 6
  static const community = '/community'; // Milestone 6
  static String game(String id) => '/game/$id'; // GAM-01 / GAM-02
  static String gameWaitlist(String id) => '/game/$id/waitlist'; // GAM-03
  static String gameJoined(String id) => '/game/$id/joined'; // GAM-05
  static String matchScore(String id) => '/match/$id/score'; // MAT-09
  static String venue(String id) => '/venue/$id'; // VEN-01
  static String venueSlots(String id) => '/venue/$id/slots'; // VEN-02
  static const bookingType = '/booking/new/type'; // BKG-01
  static const bookingPublic = '/booking/new/public'; // BKG-02
  static const bookingInvites = '/booking/new/invites'; // BKG-03
  static const bookingInvitesAfter = '/booking/new/invites?after=1'; // BKG-03 from BKG-05
  static const bookingSummary = '/booking/new/summary'; // BKG-04
  static const bookingDone = '/booking/new/done'; // BKG-05
  static String booking(String id) => '/booking/$id'; // MAT-05
  static String player(String name) => '/player/${Uri.encodeComponent(name)}'; // PRF-02
  static const profile = '/profile'; // PRF-01
  static const profileEdit = '/profile/edit'; // PRF-04
  static const settings = '/settings'; // SET-01
  static const settingsAccount = '/settings/account'; // SET-02
  static const settingsSecurity = '/settings/security'; // SET-03
  static const settingsLanguage = '/settings/language'; // SET-04
  static const settingsPrivacy = '/settings/privacy'; // SET-05
  static const settingsAccounts = '/settings/accounts'; // SET-06
  static const settingsDelete = '/settings/delete'; // SET-07
  static const roleChoice = roles; // PRF-06 « Ajouter un rôle » → AUTH-11
  static const wallet = '/wallet'; // WAL-01 (phase 9)
  static const walletTopUp = '/wallet/topup'; // WAL-02 / WAL-03
  static const walletRefund = '/wallet/refund'; // WAL-04
  static String walletRefundStatus(String id) => '/wallet/refund/$id'; // WAL-05
  static const checkout = '/pay'; // PAY-01 to PAY-08
  static const paymentSuccess = '/pay/success'; // PAY-09
  static const paymentFailed = '/pay/failed'; // PAY-10
  static String bookingPayments(String id) => '/booking/$id/payments'; // PAY-11 / PAY-12
  static const subscriptionOffers = '/premium'; // SUB-01
  static const premiumCheckout = '/premium/checkout'; // SUB-02
  static const premiumWelcome = '/premium/welcome'; // SUB-03
  static const subscription = '/premium/subscription'; // SUB-04
  static const subscriptionChange = '/premium/change'; // SUB-05
  static const subscriptionCancel = '/premium/cancel'; // SUB-06
  static const subscriptionRetention = '/premium/cancel/offer'; // SUB-07
  static const subscriptionCancelled = '/premium/cancelled'; // SUB-08
  static const receipt = '/receipt'; // SUB-09 (extra: ReceiptEntry)

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

/// A full-screen page over the tabs (no tab bar).
GoRoute _root(String path, Widget Function(GoRouterState state) build) => GoRoute(
  path: path,
  parentNavigatorKey: _rootKey,
  builder: (context, state) => build(state),
);

/// A page of a later phase, for now « Bientôt disponible » (CLAUDE.md rule 8).
// ignore: unused_element
GoRoute _later(String path, String title, String fallback) => GoRoute(
  path: path,
  parentNavigatorKey: _rootKey,
  builder: (context, state) => ComingSoonScreen(title: title, fallback: fallback),
);

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

ExploreTab? _exploreTab(GoRouterState state) => switch (state.uri.queryParameters['tab']) {
  'parties' => ExploreTab.games,
  'terrains' => ExploreTab.venues,
  'tournois' => ExploreTab.tournaments,
  _ => null,
};

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => PlayerShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [_route(Routes.home, (_) => const HomeScreen())]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.explore,
                builder: (context, state) => ExploreScreen(tab: _exploreTab(state)),
                routes: [
                  GoRoute(
                    path: 'search',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) => const SearchScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [_route(Routes.matches, (_) => const MatchesScreen())],
          ),
          StatefulShellBranch(
            routes: [_route(Routes.training, (_) => const ComingSoonTab(title: 'Entraînement'))],
          ),
          StatefulShellBranch(
            routes: [_route(Routes.community, (_) => const ComingSoonTab(title: 'Communauté'))],
          ),
        ],
      ),
      GoRoute(
        path: '/game/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => GameScreen(gameId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'waitlist',
            parentNavigatorKey: _rootKey,
            builder: (context, state) => WaitlistScreen(gameId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'joined',
            parentNavigatorKey: _rootKey,
            builder: (context, state) => JoinedScreen(gameId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/venue/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => VenueScreen(venueId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'slots',
            parentNavigatorKey: _rootKey,
            builder: (context, state) => SlotScreen(venueId: state.pathParameters['id']!),
          ),
        ],
      ),
      _root(Routes.bookingType, (_) => const BookingTypeScreen()),
      _root(Routes.bookingPublic, (_) => const BookingPublicScreen()),
      _root(
        Routes.bookingInvites,
        (s) => BookingInvitesScreen(afterBooking: s.uri.queryParameters['after'] == '1'),
      ),
      _root(Routes.bookingSummary, (_) => const BookingSummaryScreen()),
      _root(Routes.bookingDone, (_) => const BookingDoneScreen()),
      GoRoute(
        path: '/booking/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'payments',
            parentNavigatorKey: _rootKey,
            builder: (context, state) => SplitTrackerScreen(bookingId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/match/:id/score',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => ScoreScreen(matchId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/player/:name',
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            PublicProfileScreen(name: Uri.decodeComponent(state.pathParameters['name']!)),
      ),
      _root(Routes.profile, (_) => const MyProfileScreen()),
      _root(Routes.profileEdit, (_) => const EditProfileScreen()),
      _root(Routes.settings, (_) => const SettingsScreen()),
      _root(Routes.settingsAccount, (_) => const AccountScreen()),
      _root(Routes.settingsSecurity, (_) => const SecurityScreen()),
      _root(Routes.settingsLanguage, (_) => const LanguageThemeScreen()),
      _root(Routes.settingsPrivacy, (_) => const PrivacyScreen()),
      _root(Routes.settingsAccounts, (_) => const ConnectedAccountsScreen()),
      _root(Routes.settingsDelete, (_) => const DeleteAccountScreen()),
      _root(Routes.wallet, (_) => const WalletScreen()),
      _root(Routes.walletTopUp, (_) => const TopUpScreen()),
      _root(Routes.walletRefund, (_) => const RefundRequestScreen()),
      GoRoute(
        path: '/wallet/refund/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => RefundStatusScreen(requestId: state.pathParameters['id']!),
      ),
      _root(Routes.checkout, (_) => const CheckoutScreen()),
      _root(Routes.paymentSuccess, (_) => const PaymentSuccessScreen()),
      _root(Routes.paymentFailed, (s) {
        final (card, reason) = s.extra as (String, String?)? ?? ('ta carte', null);
        return PaymentFailedScreen(cardLabel: card, reason: reason);
      }),
      _root(Routes.subscriptionOffers, (_) => const OffersScreen()),
      _root(Routes.premiumCheckout, (_) => const PremiumCheckoutScreen()),
      _root(Routes.premiumWelcome, (_) => const PremiumWelcomeScreen()),
      _root(Routes.subscription, (_) => const SubscriptionScreen()),
      _root(Routes.subscriptionChange, (_) => const ChangePlanScreen()),
      _root(Routes.subscriptionCancel, (_) => const CancelReasonScreen()),
      _root(Routes.subscriptionRetention, (_) => const RetentionOfferScreen()),
      _root(Routes.subscriptionCancelled, (_) => const CancelledScreen()),
      _root(Routes.receipt, (s) => ReceiptScreen(entry: s.extra! as ReceiptEntry)),
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
