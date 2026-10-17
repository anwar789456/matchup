import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../../l10n/l10n.dart';

/// A link inside a sentence (« Modifier », « Se connecter », « Créer un compte »).
InlineSpan inlineLink(String label, VoidCallback onTap, TextStyle style) => WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: MuButton.link(label: label, onPressed: onTap, inline: true, linkStyle: style),
    );

/// « ou avec ton email » between the social buttons and the form.
class OrDivider extends StatelessWidget {
  OrDivider({super.key, String? label}) : label = label ?? l10n.ouAvecTonEmail;

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final rule = Expanded(child: Container(height: 1, color: c.border));
    return Row(
      children: [
        rule,
        const SizedBox(width: MuSpace.s3),
        Text(label, style: MuType.caption.copyWith(color: c.textSecondary)),
        const SizedBox(width: MuSpace.s3),
        rule,
      ],
    );
  }
}

/// Google and Apple buttons, stacked `space-3` apart.
class SocialButtons extends StatelessWidget {
  const SocialButtons({super.key, required this.onGoogle, required this.onApple});

  final VoidCallback? onGoogle;
  final VoidCallback? onApple;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuSocialButton(provider: MuSocialProvider.google, onPressed: onGoogle),
        const SizedBox(height: MuSpace.s3),
        MuSocialButton(provider: MuSocialProvider.apple, onPressed: onApple),
      ],
    );
  }
}

/// The 96 px status tile above a confirmation title: a tone-soft square with a 48 px icon and an
/// optional 36 px badge on the top-end corner (ringed with `surface`).
class StatusHeroTile extends StatelessWidget {
  const StatusHeroTile({
    super.key,
    required this.icon,
    required this.ground,
    required this.ink,
    this.badgeIcon,
    this.badgeFill,
    this.badgeInk,
  });

  final IconData icon;
  final Color ground;
  final Color ink;
  final IconData? badgeIcon;
  final Color? badgeFill;
  final Color? badgeInk;

  // AUTH-04 / 09 / 10: tile 96, icon 48; badge 36 with a 4 px surface ring, top −8 / end −12.
  static const double _tile = 96;
  static const double _icon = 48;
  static const double _badge = 36;
  static const double _ring = 4;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return ExcludeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _tile,
            height: _tile,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: ground, borderRadius: MuRadius.lgAll),
            child: Icon(icon, size: _icon, color: ink),
          ),
          if (badgeIcon != null)
            PositionedDirectional(
              top: -MuSpace.s2 - _ring,
              end: -MuSpace.s3 - _ring,
              child: Container(
                width: _badge + _ring * 2,
                height: _badge + _ring * 2,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeFill,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface, width: _ring),
                ),
                child: Icon(badgeIcon, size: MuSize.iconS, color: badgeInk),
              ),
            ),
        ],
      ),
    );
  }
}

/// An icon + rich sentence row (AUTH-02 reasons, AUTH-11 note).
class IconLine extends StatelessWidget {
  const IconLine({
    super.key,
    required this.icon,
    required this.text,
    this.iconSize = MuSize.iconS,
    this.gap = MuSpace.s3,
    this.style,
  });

  final IconData icon;
  final InlineSpan text;
  final double iconSize;
  final double gap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: iconSize, color: c.textSecondary),
        SizedBox(width: gap),
        Expanded(
          child: Text.rich(text, style: style ?? MuType.body.copyWith(color: c.textSecondary)),
        ),
      ],
    );
  }
}
