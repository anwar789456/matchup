import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'mu_banner.dart' show MuAction;
import 'mu_toast.dart';

/// Snackbar (components/Snackbar.md): one short message and one action on the toast surface —
/// « Partie quittée · Annuler », « Impossible de rejoindre la partie. · Réessayer ». No title,
/// no close button; it shares [MuToaster]'s region and queue with the toasts.
class MuSnackbar extends StatelessWidget {
  const MuSnackbar({
    super.key,
    required this.message,
    this.action,
    this.icon,
    this.tone = MuToastTone.neutral,
    this.busy = false,
    this.progress,
  });

  final String message;
  final MuAction? action;
  final IconData? icon;
  final MuToastTone tone;

  /// « Hors ligne. Reconnexion… »: a 32 % segment slides along the line instead of a timer.
  final bool busy;

  /// Remaining time (1 → 0) drawn as the 2 px line; null when persistent.
  final Animation<double>? progress;

  /// Shows a snackbar; pressing the action runs it and closes the snackbar.
  static void show(
    BuildContext context, {
    required String message,
    MuAction? action,
    IconData? icon,
    MuToastTone tone = MuToastTone.neutral,
    bool busy = false,
    bool persistent = false,
    OverlayState? overlay,
  }) {
    MuToaster.add(
      overlay ?? Overlay.of(context, rootOverlay: true),
      id: message,
      persistent: persistent || busy,
      builder: (progress, close) => MuSnackbar(
        message: message,
        icon: icon,
        tone: tone,
        busy: busy,
        progress: persistent || busy ? null : progress,
        action: action == null
            ? null
            : MuAction(action.label, () {
                action.onPressed();
                close();
              }),
      ),
    );
  }

  // Snackbar.md: min height 48, 2 px line, busy segment 32 % (60 % still with reduced motion).
  static const double _minHeight = 48;
  static const double _line = 2;
  static const double _segment = 0.32;
  static const double _stillSegment = 0.6;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final color = switch (tone) {
      MuToastTone.success => c.success,
      MuToastTone.error => c.error,
      MuToastTone.warning => c.warning,
      MuToastTone.info => c.info,
      MuToastTone.neutral => c.toastAction,
    };
    final reduce = MediaQuery.of(context).disableAnimations;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        color: c.toastBg,
        borderRadius: MuRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(boxShadow: MuElevation.of(context).level2),
          child: Stack(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _minHeight),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    MuSpace.s4,
                    MuSpace.s3,
                    MuSpace.s2,
                    MuSpace.s3,
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: MuSize.iconS,
                          color: tone == MuToastTone.neutral ? c.toastText : color,
                        ),
                        const SizedBox(width: MuSpace.s3),
                      ],
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: MuType.body.copyWith(color: c.toastText),
                        ),
                      ),
                      if (action != null)
                        TextButton(
                          onPressed: action!.onPressed,
                          style: TextButton.styleFrom(
                            foregroundColor: c.toastAction,
                            minimumSize: const Size(MuSize.controlS, MuSize.controlS),
                            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
                            textStyle: MuType.label,
                          ),
                          child: Text(action!.label),
                        ),
                    ],
                  ),
                ),
              ),
              if (busy)
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  height: _line,
                  child: reduce
                      ? FractionallySizedBox(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: _stillSegment,
                          child: ColoredBox(color: color),
                        )
                      : _BusyLine(color: color, segment: _segment),
                )
              else if (progress != null && !reduce)
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  height: _line,
                  child: AnimatedBuilder(
                    animation: progress!,
                    builder: (context, _) => FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: progress!.value,
                      child: ColoredBox(color: color),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusyLine extends StatefulWidget {
  const _BusyLine({required this.color, required this.segment});

  final Color color;
  final double segment;

  @override
  State<_BusyLine> createState() => _BusyLineState();
}

class _BusyLineState extends State<_BusyLine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: MuMotion.shimmer)
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final w = box.maxWidth * widget.segment;
        return Stack(
          children: [
            PositionedDirectional(
              start: -w + (box.maxWidth + w) * _c.value,
              width: w,
              top: 0,
              bottom: 0,
              child: ColoredBox(color: widget.color),
            ),
          ],
        );
      },
    ),
  );
}
