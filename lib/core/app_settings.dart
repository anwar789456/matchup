import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide display settings: theme (« Clair » / « Night match » / « Système ») and language,
/// saved on the device (SET-04).
@immutable
class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system, this.locale = const Locale('fr')});

  final ThemeMode themeMode;
  final Locale locale;

  bool get isArabic => locale.languageCode == 'ar';

  AppSettings copyWith({ThemeMode? themeMode, Locale? locale}) =>
      AppSettings(themeMode: themeMode ?? this.themeMode, locale: locale ?? this.locale);
}

class AppSettingsController extends Notifier<AppSettings> {
  static const _themeKey = 'settings.theme';
  static const _localeKey = 'settings.locale';

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString(_themeKey);
      final locale = prefs.getString(_localeKey);
      state = AppSettings(
        themeMode: ThemeMode.values.firstWhere(
          (m) => m.name == theme,
          orElse: () => ThemeMode.system,
        ),
        locale: locale == null ? const Locale('fr') : Locale(locale),
      );
    } catch (_) {
      // No preferences (tests, first run): keep the defaults.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _save(_themeKey, mode.name);
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _save(_localeKey, locale.languageCode);
  }

  Future<void> _save(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsController, AppSettings>(
  AppSettingsController.new,
);

/// French is the default; Arabic (RTL) and English come later.
const List<Locale> supportedLocales = [Locale('fr'), Locale('ar'), Locale('en')];
