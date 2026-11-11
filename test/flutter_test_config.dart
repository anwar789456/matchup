import 'dart:async';

import 'package:matchup/core/db/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Every test gets a fresh SQLite in memory: the providers that default to the phone's database
/// open this one instead. The no-isolate factory runs on plain futures, so widget tests (fake
/// async) can pump through queries.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  AppDatabase.defaultFactory = databaseFactoryFfiNoIsolate;
  AppDatabase.defaultPath = inMemoryDatabasePath;
  await testMain();
}
