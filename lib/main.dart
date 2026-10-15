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
  runApp(const ProviderScope(child: MatchUpApp()));
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
