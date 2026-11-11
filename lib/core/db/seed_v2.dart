import 'package:sqflite/sqflite.dart';

import '../../features/explore/data/search_repository.dart';
import '../../features/explore/data/sqlite_catalog_repositories.dart';
import '../../features/games/data/sqlite_games_repository.dart';
import '../../features/notifications/data/sqlite_notification_repository.dart';
import '../../features/owner/data/sqlite_owner_repositories.dart';
import '../../features/payments/data/sqlite_payment_repository.dart';
import '../../features/profile/data/sqlite_me_repository.dart';
import '../../features/profile/data/sqlite_profile_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/subscription/data/sqlite_subscription_repository.dart';
import '../../features/venue/data/sqlite_venues_repository.dart';
import '../../features/wallet/data/sqlite_wallet_repository.dart';

/// What schema v2 starts with: the story's settings, money, player data, catalogues, owner space.
Future<void> seedV2(DatabaseExecutor db) async {
  await RecentSearches.seed(db);
  await AccountSettingsRows.write(db, const AccountSettings());
  await SqliteMeRepository.seed(db);
  await SqliteWalletRepository.seed(db);
  await SqlitePaymentRepository.seed(db);
  await SqliteSubscriptionRepository.seed(db);
  await SqliteNotificationRepository.seed(db);
  await SqliteGamesRepository.seed(db);
  await SqlitePlayerProfileRepository.seed(db);
  await SqliteVenuesRepository.seed(db);
  await SqliteTournamentsRepository.seed(db);
  await SqliteSearchRepository.seed(db);
  await SqliteTeammatesRepository.seed(db);
  await SqliteOwnerRepository.seed(db);
  await SqliteTariffsRepository.seed(db);
  await SqliteReviewsRepository.seed(db);
  await SqliteClientsRepository.seed(db);
}
