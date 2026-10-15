import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/dev/gallery_screen.dart';

/// Route paths, one per screen code (design/screens/SCREENS.md).
abstract final class Routes {
  /// Debug-only widget gallery.
  static const gallery = '/dev/gallery';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // Until the ONB screens exist (phase 2), the app opens on the debug gallery.
    initialLocation: Routes.gallery,
    routes: [
      if (kDebugMode)
        GoRoute(
          path: Routes.gallery,
          builder: (context, state) => const GalleryScreen(),
        ),
    ],
  );
});
