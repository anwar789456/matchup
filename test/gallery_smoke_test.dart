import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/features/dev/gallery_screen.dart';
import 'package:matchup/theme/theme.dart';

/// Renders the whole widget gallery in both themes, both directions and both layouts (phone with
/// the theme toggle, desktop with Light and Night match side by side): no exception, no overflow.
/// (On desktop both themes are always shown, so the « dark » runs only differ on phones.)
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final dark in [false, true]) {
    for (final rtl in [false, true]) {
      for (final size in [const Size(390, 844), const Size(1280, 900)]) {
        testWidgets(
            'gallery ${dark ? 'dark' : 'light'} ${rtl ? 'rtl' : 'ltr'} ${size.width.toInt()}',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(ProviderScope(
            child: MaterialApp(
              theme: MuTheme.light(),
              home: const GalleryScreen(),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 300));

          // The gallery sets its own direction and (on phones) theme from its app-bar toggles.
          if (rtl) await tester.tap(find.text('RTL'));
          if (dark && size.width < 840) await tester.tap(find.text('Light'));
          await tester.pump(const Duration(milliseconds: 300));
          if (rtl) {
            final body = find.byType(ListView).first;
            expect(Directionality.of(tester.element(body)), TextDirection.rtl);
          }

          // Scroll to the end so every section is built and laid out.
          final list = find.byType(Scrollable).first;
          for (var i = 0; i < 30; i++) {
            await tester.drag(list, const Offset(0, -600), warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 50));
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
