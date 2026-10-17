import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// The Night match theme for the content of an emphasis card that stays dark in both modes
/// (balance, subscription, stats — CLAUDE.md rule 13): buttons, bars and text take their Night
/// colours, not just the token extension.
class MuNightTheme extends StatelessWidget {
  const MuNightTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) return child;
    final arabic = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    return Theme(data: MuTheme.dark(arabic: arabic), child: child);
  }
}
