import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';

enum MuAiLabelVariant { surface, media, inline }

enum MuAiLabelSize { s, m }

/// AiLabel (components/AiLabel.md): the « IA » mark on every AI output. Read as « Généré par
/// l'IA ». [onAiSurface] turns the pill `surface` inside an already `ai-soft` block.
class MuAiLabel extends StatelessWidget {
  const MuAiLabel({
    super.key,
    this.variant = MuAiLabelVariant.surface,
    this.size = MuAiLabelSize.m,
    this.text,
    this.srLabel = 'Généré par l’IA',
    this.onAiSurface = false,
  });

  /// Visible text: « IA » for pills, provenance (« Généré par l’IA ») for inline.
  final String? text;
  final MuAiLabelVariant variant;
  final MuAiLabelSize size;
  final String srLabel;
  final bool onAiSurface;

  // AiLabel.md: pill height 20 / 24, padding 5–6 / 7–8, gap 3 / 4, sparkle 12 / 14;
  // inline sparkle 16 (S 14), gap 6; media ink-900 at 80 % + 8 px blur + white ring at 16 %.
  static const double _heightS = 20;
  static const double _heightM = 24;
  static const double _padStartS = 5;
  static const double _padEndS = 6;
  static const double _padStartM = 7;
  static const double _padEndM = 8;
  static const double _gapS = 3;
  static const double _sparkleS = 12;
  static const double _sparkleM = 14;
  static const double _inlineGap = 6;
  static const double _mediaAlpha = 0.8;
  static const double _mediaRingAlpha = 0.16;
  static const double _blur = 8;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final small = size == MuAiLabelSize.s;

    if (variant == MuAiLabelVariant.inline) {
      final style = small ? MuType.caption : MuType.labelS;
      return Semantics(
        label: srLabel,
        excludeSemantics: true,
        child: Tooltip(
          message: srLabel,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                  size: small ? _sparkleM : MuSize.iconXs, color: c.aiText),
              const SizedBox(width: _inlineGap),
              Text(text ?? 'Généré par l’IA', style: style.copyWith(color: c.aiText)),
            ],
          ),
        ),
      );
    }

    final media = variant == MuAiLabelVariant.media;
    final fg = media ? MuPalette.white : c.aiText;
    final sparkleSize = small ? _sparkleS : _sparkleM;
    Widget sparkle = Icon(
      PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
      size: sparkleSize,
      color: media ? MuPalette.white : fg,
    );
    if (media) {
      sparkle = ShaderMask(
        shaderCallback: MuGradients.ai.createShader,
        blendMode: BlendMode.srcIn,
        child: sparkle,
      );
    }

    Widget pill = Container(
      height: small ? _heightS : _heightM,
      padding: EdgeInsetsDirectional.only(
        start: small ? _padStartS : _padStartM,
        end: small ? _padEndS : _padEndM,
      ),
      decoration: ShapeDecoration(
        color: media
            ? MuPalette.ink900.withValues(alpha: _mediaAlpha)
            : (onAiSurface ? c.surface : c.aiSoft),
        shape: StadiumBorder(
          side: media
              ? BorderSide(color: MuPalette.white.withValues(alpha: _mediaRingAlpha))
              : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          sparkle,
          SizedBox(width: small ? _gapS : MuSpace.s1),
          Text((text ?? 'IA').toUpperCase(), style: MuType.overline.copyWith(color: fg)),
        ],
      ),
    );
    if (media) {
      pill = ClipRRect(
        borderRadius: MuRadius.fullAll,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
          child: pill,
        ),
      );
    }
    return Semantics(
      label: srLabel,
      excludeSemantics: true,
      child: Tooltip(message: srLabel, child: pill),
    );
  }
}
