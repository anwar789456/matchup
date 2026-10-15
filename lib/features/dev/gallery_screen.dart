import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Debug-only widget gallery: every Mu* widget in light and dark.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Joue. Réserve. Progresse.', style: MuType.h2),
      ),
    );
  }
}
