import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_icon_button.dart';

enum MuDialogTone { neutral, destructive, warning, success, info }

enum MuDialogPlacement { center, bottom }

/// Dialog (components/Dialog.md): a confirmation for destructive or costly actions — tone icon,
/// the question as title, what and when, the consequence with its amount, then the safe action
/// first and the destructive one last. On mobile it sits at the bottom, in the thumb zone.
class MuDialog extends StatelessWidget {
  const MuDialog({
    super.key,
    required this.title,
    required this.actions,
    this.description,
    this.consequence,
    this.consequenceIcon,
    this.tone = MuDialogTone.neutral,
    this.icon,
    this.content,
    this.dismissible = true,
    this.busy = false,
    this.placement = MuDialogPlacement.bottom,
    this.onClose,
  });

  final String title;
  final String? description;

  /// Money or access, with the amount (« 45 DT seront remboursés sur ton solde MatchUp. »).
  final String? consequence;
  final IconData? consequenceIcon;
  final MuDialogTone tone;
  final IconData? icon;

  /// Extra content between the consequence and the actions.
  final Widget? content;
  final List<Widget> actions;
  final bool dismissible;
  final bool busy;
  final MuDialogPlacement placement;
  final VoidCallback? onClose;

  // Dialog.md: tone circle 48 with a 24 icon; S width 400; bottom card space-2 from the edges.
  static const double _circle = 48;
  static const double _scaleFrom = 0.96;
  static const double _rise = 24;

  /// Shows the dialog over `scrim`: scale 0,96 → 1 with a fade (bottom placement rises 24 px)
  /// over `duration-slow`, back over `duration-base`. Returns what the dialog pops with.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<Widget> actions,
    String? description,
    String? consequence,
    IconData? consequenceIcon,
    MuDialogTone tone = MuDialogTone.neutral,
    IconData? icon,
    Widget? content,
    bool dismissible = true,
    bool busy = false,
    MuDialogPlacement placement = MuDialogPlacement.bottom,
  }) {
    final c = context.mu;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return showGeneralDialog<T>(
      context: context,
      useRootNavigator: true,
      barrierColor: c.scrim,
      barrierDismissible: dismissible && !busy,
      barrierLabel: title,
      transitionDuration: reduce ? Duration.zero : MuMotion.slow,
      pageBuilder: (context, _, _) => PopScope(
        canPop: !busy,
        child: MuDialog(
          title: title,
          description: description,
          consequence: consequence,
          consequenceIcon: consequenceIcon,
          tone: tone,
          icon: icon,
          content: content,
          actions: actions,
          dismissible: dismissible,
          busy: busy,
          placement: placement,
        ),
      ),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: MuMotion.enter,
          reverseCurve: MuMotion.exit,
        );
        final fade = FadeTransition(opacity: curved, child: child);
        if (placement == MuDialogPlacement.bottom) {
          return AnimatedBuilder(
            animation: curved,
            child: fade,
            builder: (context, child) =>
                Transform.translate(offset: Offset(0, _rise * (1 - curved.value)), child: child),
          );
        }
        return ScaleTransition(
          scale: Tween(begin: _scaleFrom, end: 1.0).animate(curved),
          child: fade,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final e = MuElevation.of(context);
    final (Color ground, Color ink, IconData defaultIcon, Color? edge) = switch (tone) {
      MuDialogTone.neutral => (c.bg, c.text, PhosphorIcons.question(), c.border),
      MuDialogTone.destructive => (c.errorSoft, c.errorText, PhosphorIcons.warning(), null),
      MuDialogTone.warning => (c.warningSoft, c.warningText, PhosphorIcons.warningCircle(), null),
      MuDialogTone.success => (c.successSoft, c.successText, PhosphorIcons.checkCircle(), null),
      MuDialogTone.info => (c.infoSoft, c.infoText, PhosphorIcons.info(), null),
    };
    final bottom = placement == MuDialogPlacement.bottom;
    final pad = bottom ? MuSpace.s5 : MuSpace.s6;

    final panel = Material(
      color: c.surfaceElevated,
      borderRadius: MuRadius.lgAll,
      elevation: MuElevation.materialLevel3,
      shadowColor: e.shadowColor,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(MuSpace.s6, MuSpace.s6, MuSpace.s6, pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: _circle,
                  height: _circle,
                  decoration: BoxDecoration(
                    color: ground,
                    shape: BoxShape.circle,
                    border: edge == null ? null : Border.all(color: edge),
                  ),
                  child: Icon(icon ?? defaultIcon, size: MuSize.iconM, color: ink),
                ),
                const SizedBox(height: MuSpace.s4),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: dismissible && !busy ? MuSpace.s8 : 0),
                  child: Semantics(
                    header: true,
                    child: Text(title, style: MuType.h3.copyWith(color: c.text)),
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: MuSpace.s2),
                  Text(description!, style: MuType.bodyL.copyWith(color: c.textSecondary)),
                ],
                if (consequence != null) ...[
                  const SizedBox(height: MuSpace.s4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MuSpace.s4,
                      vertical: MuSpace.s3,
                    ),
                    decoration: BoxDecoration(
                      color: c.bg,
                      borderRadius: MuRadius.mdAll,
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          consequenceIcon ?? PhosphorIcons.info(),
                          size: MuSize.iconS,
                          color: c.textSecondary,
                        ),
                        const SizedBox(width: MuSpace.s3),
                        Expanded(
                          child: Text(consequence!, style: MuType.body.copyWith(color: c.text)),
                        ),
                      ],
                    ),
                  ),
                ],
                if (content != null) ...[const SizedBox(height: MuSpace.s5), content!],
                const SizedBox(height: MuSpace.s5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, a) in actions.indexed) ...[
                      if (i > 0) const SizedBox(height: MuSpace.s3),
                      a,
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (dismissible && !busy)
            PositionedDirectional(
              top: MuSpace.s3,
              end: MuSpace.s3,
              child: MuIconButton(
                icon: PhosphorIcons.x(),
                label: 'Fermer',
                onPressed: onClose ?? () => Navigator.of(context).maybePop(),
              ),
            ),
        ],
      ),
    );

    final sized = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: MuSize.modalS),
      child: panel,
    );
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(bottom ? MuSpace.s2 : MuSpace.s4),
          child: Align(alignment: bottom ? Alignment.bottomCenter : Alignment.center, child: sized),
        ),
      ),
    );
  }
}
