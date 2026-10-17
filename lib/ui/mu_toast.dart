import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_banner.dart' show MuAction;
import 'mu_icon_button.dart';

enum MuToastTone { success, error, warning, info, neutral }

/// Toast (components/Toast.md): non-blocking feedback on `toast-bg` (dark in both themes).
///
/// Use [MuToast.show] to display one; the widget itself is the visual, also usable inline
/// (the ONB-03 illustration). The 3-deep stack comes with the Notifications milestone; for now a
/// new toast replaces the current one.
class MuToast extends StatelessWidget {
  const MuToast({
    super.key,
    required this.title,
    this.tone = MuToastTone.neutral,
    this.description,
    this.icon,
    this.action,
    this.onClose,
    this.progress,
  });

  final String title;
  final MuToastTone tone;
  final String? description;
  final IconData? icon;
  final MuAction? action;

  /// Shows the close button « Fermer ».
  final VoidCallback? onClose;

  /// Remaining time (1 → 0) drawn as the 2 px bottom line; null for persistent toasts.
  final Animation<double>? progress;

  // Toast.md: description at 74 % of toast-text, close icon at 80 %, 2 px progress line,
  // action 32 high.
  static const double _descriptionAlpha = 0.74;
  static const double _closeAlpha = 0.8;
  static const double _line = 2;

  static _ToastHost? _current;

  /// Shows a toast: bottom on phones, top-end on wide screens; auto-dismisses after
  /// `duration-toast` unless [persistent].
  static void show(
    BuildContext context, {
    required String title,
    MuToastTone tone = MuToastTone.neutral,
    String? description,
    MuAction? action,
    bool persistent = false,
    OverlayState? overlay,
  }) {
    _current?.remove();
    // [overlay] lets a flow whose page is gone (left game, cancelled booking) still toast.
    overlay ??= Overlay.of(context, rootOverlay: true);
    late final _ToastHost host;
    host = _ToastHost(
      overlay: overlay,
      builder: (progress, close) => MuToast(
        title: title,
        tone: tone,
        description: description,
        action: action,
        onClose: close,
        progress: persistent ? null : progress,
      ),
      persistent: persistent,
      onRemoved: () {
        if (identical(_current, host)) _current = null;
      },
    );
    _current = host..insert();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final (Color iconColor, IconData? defaultIcon) = switch (tone) {
      MuToastTone.success => (c.success, PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)),
      MuToastTone.error => (c.error, PhosphorIcons.warningCircle(PhosphorIconsStyle.fill)),
      MuToastTone.warning => (c.warning, PhosphorIcons.warning(PhosphorIconsStyle.fill)),
      MuToastTone.info => (c.info, PhosphorIcons.info(PhosphorIconsStyle.fill)),
      MuToastTone.neutral => (c.toastText, null),
    };
    final glyph = icon ?? defaultIcon;
    final lineColor = tone == MuToastTone.neutral ? c.toastAction : iconColor;

    final body = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s4, MuSpace.s3, MuSpace.s2, MuSpace.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (glyph != null) ...[
            Icon(glyph, size: MuSize.iconS, color: iconColor),
            const SizedBox(width: MuSpace.s3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: MuType.label.copyWith(color: c.toastText)),
                if (description != null)
                  Text(
                    description!,
                    style: MuType.caption.copyWith(
                      color: c.toastText.withValues(alpha: _descriptionAlpha),
                    ),
                  ),
              ],
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
          if (onClose != null)
            MuIconButton(
              icon: PhosphorIcons.x(),
              label: 'Fermer',
              size: MuIconButtonSize.s,
              color: c.toastText.withValues(alpha: _closeAlpha),
              onPressed: onClose,
            ),
        ],
      ),
    );

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
              body,
              if (progress != null && !MediaQuery.of(context).disableAnimations)
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
                      child: ColoredBox(color: lineColor),
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

/// One toast in the root overlay, with its enter/exit animation and auto-dismiss timer.
class _ToastHost {
  _ToastHost({
    required this.overlay,
    required this.builder,
    required this.persistent,
    required this.onRemoved,
  });

  final OverlayState overlay;
  final Widget Function(Animation<double> progress, VoidCallback close) builder;
  final bool persistent;
  final VoidCallback onRemoved;
  OverlayEntry? _entry;

  void insert() {
    _entry = OverlayEntry(
      builder: (context) => _ToastLayer(
        persistent: persistent,
        builder: builder,
        onDone: remove,
      ),
    );
    overlay.insert(_entry!);
  }

  void remove() {
    _entry?.remove();
    _entry = null;
    onRemoved();
  }
}

class _ToastLayer extends StatefulWidget {
  const _ToastLayer({required this.persistent, required this.builder, required this.onDone});

  final bool persistent;
  final Widget Function(Animation<double> progress, VoidCallback close) builder;
  final VoidCallback onDone;

  @override
  State<_ToastLayer> createState() => _ToastLayerState();
}

class _ToastLayerState extends State<_ToastLayer> with TickerProviderStateMixin {
  // The auto-dismiss timer keeps its 4 s even when the system shortens animations (reduce
  // motion scales controllers down); only the enter/exit motion follows that setting.
  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: MuMotion.toast,
    value: 1,
    animationBehavior: AnimationBehavior.preserve,
  );
  late final AnimationController _show = AnimationController(vsync: this);
  bool _closing = false;

  // Toast.md: fade + 8 px slide toward its edge.
  static const double _slide = 8;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _show.duration = MuMotion.durationOf(context, MuMotion.base);
    if (_show.value == 0 && !_show.isAnimating) {
      _show.forward();
      if (!widget.persistent) {
        _life.reverse().whenCompleteOrCancel(() {
          if (_life.value == 0) _close();
        });
      }
    }
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    await _show.reverse();
    widget.onDone();
  }

  void _pause() => _life.stop();

  void _resume() {
    if (!widget.persistent && !_closing) {
      _life.reverse().whenCompleteOrCancel(() {
        if (_life.value == 0) _close();
      });
    }
  }

  @override
  void dispose() {
    _life.dispose();
    _show.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= MuLayout.bpExpanded;
    final toast = MouseRegion(
      onEnter: (_) => _pause(),
      onExit: (_) => _resume(),
      child: widget.builder(_life, _close),
    );
    final animated = AnimatedBuilder(
      animation: _show,
      builder: (context, child) {
        final t = MuMotion.enter.transform(_show.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * _slide * (wide ? -1 : 1)),
            child: child,
          ),
        );
      },
      child: toast,
    );
    return SafeArea(
      child: Align(
        alignment: wide ? AlignmentDirectional.topEnd : Alignment.bottomCenter,
        child: Padding(
          padding: wide
              ? const EdgeInsetsDirectional.only(top: MuSpace.s4, end: MuSpace.s6)
              : const EdgeInsets.all(MuSpace.s4),
          child: SizedBox(width: wide ? MuSize.toast : double.infinity, child: animated),
        ),
      ),
    );
  }
}
