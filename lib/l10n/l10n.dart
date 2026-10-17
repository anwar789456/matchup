import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// The app's strings in the current language (CLAUDE.md rule 12). A global so labels of enums
/// and helpers without a BuildContext read them too; [MatchUpApp] keeps it in step with the
/// locale and rebuilds the tree when it changes.
AppLocalizations get l10n => _current;

AppLocalizations _current = lookupAppLocalizations(const Locale('fr'));

/// Switches [l10n] to [locale] (French when the language has no strings yet).
void setL10nLocale(Locale locale) {
  final supported = AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == locale.languageCode,
  );
  _current = lookupAppLocalizations(supported ? locale : const Locale('fr'));
}
