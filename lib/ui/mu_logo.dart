import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/theme.dart';

enum MuLogoVariant { wordmark, icon }

enum MuLogoTone { auto, light, dark, monoInk, monoWhite }

/// Logo (components/Logo.md): the MatchUp wordmark or app icon, from the exported SVGs.
/// `auto` follows the theme (light logo in Light, dark logo in Night match).
class MuLogo extends StatelessWidget {
  const MuLogo({
    super.key,
    this.variant = MuLogoVariant.wordmark,
    this.tone = MuLogoTone.auto,
    this.height = defaultHeight,
    this.semanticLabel = 'MatchUp',
  });

  /// Logo.md: default wordmark height.
  static const double defaultHeight = 28;

  final MuLogoVariant variant;
  final MuLogoTone tone;
  final double height;
  final String semanticLabel;

  static const _dir = 'assets/logo';

  String _asset(Brightness brightness) {
    if (variant == MuLogoVariant.icon) {
      return switch (tone) {
        MuLogoTone.monoInk || MuLogoTone.monoWhite => '$_dir/matchup-app-icon-monochrome.svg',
        _ => '$_dir/matchup-app-icon-rounded.svg',
      };
    }
    final resolved = tone == MuLogoTone.auto
        ? (brightness == Brightness.dark ? MuLogoTone.dark : MuLogoTone.light)
        : tone;
    return switch (resolved) {
      MuLogoTone.dark => '$_dir/matchup-logo-dark.svg',
      MuLogoTone.monoInk => '$_dir/matchup-logo-mono-ink.svg',
      MuLogoTone.monoWhite => '$_dir/matchup-logo-mono-white.svg',
      _ => '$_dir/matchup-logo-light.svg',
    };
  }

  @override
  Widget build(BuildContext context) {
    final asset = _asset(Theme.of(context).brightness);
    // The monochrome icon is drawn in one ink; paint it white for mono-white.
    final filter = variant == MuLogoVariant.icon && tone == MuLogoTone.monoWhite
        ? const ColorFilter.mode(MuPalette.white, BlendMode.srcIn)
        : null;
    return SvgPicture.asset(
      asset,
      height: height,
      colorFilter: filter,
      semanticsLabel: semanticLabel,
    );
  }
}
