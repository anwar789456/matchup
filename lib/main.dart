import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';

void main() {
  // The fonts ship in assets/google_fonts (theme README « Fonts »): no download at first launch.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(_fontLicenses);
  WidgetsFlutterBinding.ensureInitialized();
  loadArabicGlyphFallback();
  runApp(const ProviderScope(child: MatchUpApp()));
}

/// Widgets style text with MuType (Plus Jakarta Sans, Barlow Condensed), which have no Arabic
/// glyphs; google_fonts makes each style fall back to its plain family name. Registering IBM Plex
/// Sans Arabic under those names gives Arabic words the designed face (RTL-01…03) while Latin
/// letters and digits keep theirs.
Future<void> loadArabicGlyphFallback() async {
  for (final family in ['PlusJakartaSans', 'BarlowCondensed']) {
    final loader = FontLoader(family);
    for (final file in ['Regular', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/google_fonts/IBMPlexSansArabic-$file.ttf'));
    }
    await loader.load();
  }
}

Stream<LicenseEntry> _fontLicenses() async* {
  for (final (package, file) in [
    ('Plus Jakarta Sans', 'OFL-PlusJakartaSans.txt'),
    ('Barlow Condensed', 'OFL-BarlowCondensed.txt'),
    ('IBM Plex Sans Arabic', 'OFL-IBMPlexSansArabic.txt'),
  ]) {
    final text = await rootBundle.loadString('assets/google_fonts/$file');
    yield LicenseEntryWithLineBreaks([package], text);
  }
}
