import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'src/interaction.dart';
import '../l10n/l10n.dart';

enum MuSocialProvider { google, apple }

/// SocialButton (components/SocialButton.md): « Continuer avec Google / Apple », 48 high, full
/// width, in each provider's own published colours.
///
/// [mark] holds the provider's official logo from its branding kit. Until it is added, a dashed
/// placeholder square is drawn, as in the design — never a redrawn logo.
class MuSocialButton extends StatelessWidget {
  const MuSocialButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.label,
    this.mark,
  });

  final MuSocialProvider provider;
  final VoidCallback? onPressed;
  final String? label;
  final Widget? mark;

  // SocialButton.md: the providers' published button colours — the one place where literal
  // colours replace tokens. They don't follow MatchUp's brand.
  static const _googleLightFill = Color(0xFFFFFFFF);
  static const _googleLightBorder = Color(0xFF747775);
  static const _googleLightText = Color(0xFF1F1F1F);
  static const _googleLightHover = Color(0xFFF8F9FA);
  static const _googleDarkFill = Color(0xFF131314);
  static const _googleDarkBorder = Color(0xFF8E918F);
  static const _googleDarkText = Color(0xFFE3E3E3);
  static const _appleLightFill = Color(0xFF000000);
  static const _appleLightText = Color(0xFFFFFFFF);
  static const _appleDarkFill = Color(0xFFFFFFFF);
  static const _appleDarkText = Color(0xFF000000);

  // SocialButton.md: 20 × 20 mark slot.
  static const double _markSize = 20;

  String get _label =>
      label ??
      switch (provider) {
        MuSocialProvider.google => l10n.continuerAvecGoogle,
        MuSocialProvider.apple => l10n.continuerAvecApple,
      };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (Color fill, Color text, Color? border, Color? hover) = switch ((provider, dark)) {
      (MuSocialProvider.google, false) =>
        (_googleLightFill, _googleLightText, _googleLightBorder, _googleLightHover),
      (MuSocialProvider.google, true) => (_googleDarkFill, _googleDarkText, _googleDarkBorder, null),
      (MuSocialProvider.apple, false) => (_appleLightFill, _appleLightText, null, null),
      (MuSocialProvider.apple, true) => (_appleDarkFill, _appleDarkText, null, null),
    };

    final button = TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        fixedSize: const WidgetStatePropertyAll(Size.fromHeight(MuSize.controlL)),
        minimumSize: const WidgetStatePropertyAll(Size(double.infinity, MuSize.controlL)),
        padding: const WidgetStatePropertyAll(
          EdgeInsetsDirectional.symmetric(horizontal: MuSpace.s4),
        ),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: MuRadius.mdAll,
          side: border == null ? BorderSide.none : BorderSide(color: border),
        )),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered) && hover != null ? hover : fill,
        ),
        foregroundColor: WidgetStatePropertyAll(text),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: WidgetStatePropertyAll(MuType.label),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: _markSize,
              child: mark ?? CustomPaint(painter: _DashedSquarePainter(text)),
            ),
          ),
          const SizedBox(width: MuSpace.s3),
          Flexible(child: Text(_label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );

    return MuFocusRing(
      borderRadius: MuRadius.mdAll,
      child: MuPressScale(enabled: onPressed != null, child: button),
    );
  }
}

/// The preview's placeholder for the provider mark: a dashed square.
class _DashedSquarePainter extends CustomPainter {
  _DashedSquarePainter(this.color);

  final Color color;

  static const double _dash = 3;
  static const double _alpha = 0.6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: _alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = (Offset.zero & size).deflate(0.5);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(MuRadius.xs / 2)));
    for (final ui.PathMetric m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += _dash * 2) {
        canvas.drawPath(m.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedSquarePainter old) => old.color != color;
}
