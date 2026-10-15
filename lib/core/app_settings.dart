import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide display settings: theme (« Light » / « Night match ») and language.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('fr'),
  });

  final ThemeMode themeMode;
  final Locale locale;

  bool get isArabic => locale.languageCode == 'ar';

  AppSettings copyWith({ThemeMode? themeMode, Locale? locale}) => AppSettings(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
      );
}

class AppSettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);

  void setLocale(Locale locale) => state = state.copyWith(locale: locale);
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(AppSettingsController.new);

/// French is the default; Arabic (RTL) and English come later.
const List<Locale> supportedLocales = [Locale('fr'), Locale('ar'), Locale('en')];
