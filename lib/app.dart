import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_settings.dart';
import 'router.dart';
import 'theme/theme.dart';

class MatchUpApp extends ConsumerWidget {
  const MatchUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'MatchUp',
      debugShowCheckedModeBanner: false,
      theme: MuTheme.light(arabic: settings.isArabic),
      darkTheme: MuTheme.dark(arabic: settings.isArabic),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    );
  }
}
