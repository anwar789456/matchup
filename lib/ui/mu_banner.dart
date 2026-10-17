import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_button.dart';
import 'mu_icon_button.dart';
import '../l10n/l10n.dart';

enum MuBannerVariant { inset, strip }

/// The tone of a banner: the status tones plus neutral.
enum MuBannerTone { info, success, warning, error, neutral }

/// An action under or beside a banner's text.
@immutable
class MuAction {
  const MuAction(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;
}

/// Banner (components/Banner.md): a persistent message in the page flow — icon, title, detail,
/// one action. Dismissible only when nothing is blocked. (The test-mode ribbon comes with the
/// Payments milestone.)
class MuBanner extends StatelessWidget {
  MuBanner({
    super.key,
    required this.title,
    this.tone = MuBannerTone.info,
    this.variant = MuBannerVariant.inset,
    this.detail,
    this.icon,
    this.action,
    this.onDismiss,
    String? dismissLabel,
    this.footer,
  }) : dismissLabel = dismissLabel ?? l10n.masquer;

  final String title;
  final String? detail;
  final MuBannerTone tone;
  final MuBannerVariant variant;
  final IconData? icon;
  final MuAction? action;
  final VoidCallback? onDismiss;
  final String dismissLabel;

  /// Extra content under the detail, e.g. an inline link (« Réinitialiser mon mot de passe »).
  final Widget? footer;

  // Banner.md: the strip's bottom rule is the tone ink at 22 %.
  static const double _ruleAlpha = 0.22;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final strip = variant == MuBannerVariant.strip;
    final (Color ground, Color ink, IconData defaultIcon) = switch (tone) {
      MuBannerTone.info => (c.infoSoft, c.infoText, PhosphorIcons.info(_weight(strip))),
      MuBannerTone.success =>
        (c.successSoft, c.successText, PhosphorIcons.checkCircle(_weight(strip))),
      MuBannerTone.warning => (c.warningSoft, c.warningText, PhosphorIcons.warning(_weight(strip))),
      MuBannerTone.error =>
        (c.errorSoft, c.errorText, PhosphorIcons.warningCircle(_weight(strip))),
      MuBannerTone.neutral => (c.surfaceMuted, c.textSecondary, PhosphorIcons.info(_weight(strip))),
    };

    final iconWidget = Icon(icon ?? defaultIcon, size: MuSize.iconS, color: ink);
    final titleText = Text(title, style: MuType.label.copyWith(color: c.text));
    final detailText = detail == null
        ? null
        : Text(detail!, style: MuType.body.copyWith(color: c.textSecondary));
    final actionButton = action == null
        ? null
        : MuButton.secondary(
            label: action!.label,
            onPressed: action!.onPressed,
            size: MuButtonSize.s,
          );
    final dismiss = onDismiss == null
        ? null
        : MuIconButton(
            icon: PhosphorIcons.x(),
            label: dismissLabel,
            size: MuIconButtonSize.s,
            onPressed: onDismiss,
          );

    final body = LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= MuLayout.bpMedium;
      final Widget texts;
      if (strip && wide && detailText != null) {
        texts = Text.rich(
          TextSpan(children: [
            TextSpan(text: title, style: MuType.label.copyWith(color: c.text)),
            TextSpan(text: ' · $detail', style: MuType.body.copyWith(color: c.textSecondary)),
          ]),
        );
      } else {
        texts = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            titleText,
            ?detailText,
            if (footer != null) ...[const SizedBox(height: MuSpace.s1), footer!],
          ],
        );
      }
      if (wide) {
        return Row(
          children: [
            iconWidget,
            const SizedBox(width: MuSpace.s3),
            Expanded(child: texts),
            if (actionButton != null) ...[const SizedBox(width: MuSpace.s3), actionButton],
            if (dismiss != null) ...[const SizedBox(width: MuSpace.s1), dismiss],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconWidget,
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                texts,
                if (actionButton != null) ...[
                  const SizedBox(height: MuSpace.s3),
                  actionButton,
                ],
              ],
            ),
          ),
          ?dismiss,
        ],
      );
    });

    final Widget container;
    if (strip) {
      container = LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= MuLayout.bpMedium;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: wide ? MuSpace.s8 : MuSpace.s4,
            vertical: MuSpace.s2,
          ),
          decoration: BoxDecoration(
            color: ground,
            border: Border(bottom: BorderSide(color: ink.withValues(alpha: _ruleAlpha))),
          ),
          child: body,
        );
      });
    } else {
      container = LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= MuLayout.bpMedium;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? MuSpace.s5 : MuSpace.s4,
            vertical: MuSpace.s3,
          ),
          decoration: BoxDecoration(
            color: ground,
            borderRadius: MuRadius.mdAll,
            border: tone == MuBannerTone.neutral ? Border.all(color: c.border) : null,
          ),
          child: body,
        );
      });
    }

    return Semantics(
      container: true,
      liveRegion: true,
      child: container,
    );
  }

  // Inset banners use the fill icon; strips use the regular weight.
  static PhosphorIconsStyle _weight(bool strip) =>
      strip ? PhosphorIconsStyle.regular : PhosphorIconsStyle.fill;
}
