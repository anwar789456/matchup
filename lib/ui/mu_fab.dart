import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'src/interaction.dart';

/// Fab (components/Fab.md): the AI assistant button — a 56 px circle in the AI gradient with a
/// filled sparkle, or [extended] with « Demande à MatchUp ». Put it in
/// `Scaffold.floatingActionButton` (`endFloat`) above the TabBar; not from 840 px up.
class MuFab extends StatelessWidget {
  const MuFab({
    super.key,
    required this.onPressed,
    this.label = 'Assistant MatchUp',
    this.extended = false,
    this.extendedLabel = 'Demande à MatchUp',
  });

  final VoidCallback onPressed;

  /// Accessible name of the circle.
  final String label;
  final bool extended;
  final String extendedLabel;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
      size: MuSize.iconM,
      color: MuPalette.white,
    );
    final content = extended
        ? Padding(
            padding: const EdgeInsetsDirectional.only(start: MuSpace.s5, end: MuSpace.s6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(width: MuSpace.s2),
                Text(extendedLabel, style: MuType.label.copyWith(color: MuPalette.white)),
              ],
            ),
          )
        : SizedBox.square(dimension: MuSize.controlXl, child: Center(child: icon));

    return Semantics(
      button: true,
      label: extended ? extendedLabel : label,
      excludeSemantics: true,
      child: MuFocusRing(
        borderRadius: MuRadius.fullAll,
        child: MuPressScale(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              shadows: MuElevation.of(context).level2,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Ink(
                height: MuSize.controlXl,
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  gradient: extended ? MuGradients.aiStrong : MuGradients.ai,
                ),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: onPressed,
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
