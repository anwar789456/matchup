import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_banner.dart' show MuAction;
import 'mu_icon_button.dart';
import '../l10n/l10n.dart';

enum MuToastTone { success, error, warning, info, neutral }

/// Toast (components/Toast.md): non-blocking feedback on `toast-bg` (dark in both themes).
///
/// Use [MuToast.show] to display one; the widget itself is the visual, also usable inline
/// (the ONB-03 illustration). Toasts and snackbars share [MuToaster]'s region and queue.
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

  /// Shows a toast in the toast region: above the tab bar or the sticky action bar on phones,
  /// top-end on wide screens; auto-dismisses after `duration-toast` unless [persistent]. At most
  /// 3 show at once (newest in front), the next ones wait; a toast with the same title replaces
  /// the one on screen.
  static void show(
    BuildContext context, {
    required String title,
    MuToastTone tone = MuToastTone.neutral,
    String? description,
    IconData? icon,
    MuAction? action,
    bool persistent = false,
    OverlayState? overlay,
  }) {
    // [overlay] lets a flow whose page is gone (left game, cancelled booking) still toast.
    MuToaster.add(
      overlay ?? Overlay.of(context, rootOverlay: true),
      id: title,
      persistent: persistent,
      builder: (progress, close) => MuToast(
        title: title,
        tone: tone,
        description: description,
        icon: icon,
        action: action == null
            ? null
            : MuAction(action.label, () {
                action.onPressed();
                close();
              }),
        onClose: close,
        progress: persistent ? null : progress,
      ),
    );
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
              label: l10n.fermer,
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

/// One toast or snackbar waiting or on screen.
class _ToastItem {
  _ToastItem({required this.id, required this.persistent, required this.builder});

  final String id;
  final bool persistent;
  final Widget Function(Animation<double> progress, VoidCallback close) builder;
  final GlobalKey<_ToastTileState> key = GlobalKey();
}

/// The toast region (Toast.md « Stack »): one overlay entry, up to 3 toasts on screen (newest in
/// front, the older ones peeking 10 px behind at 0.95 / 0.90 until a tap expands them), a queue
/// for the next ones, placed `space-4` above the bottom bar registered by [MuToastAnchor].
abstract final class MuToaster {
  static const int max = 3;

  static final ValueNotifier<List<_ToastItem>> _shown = ValueNotifier(const []);
  static final List<_ToastItem> _queue = [];
  static OverlayEntry? _entry;
  static OverlayState? _overlay;
  static final List<_MuToastAnchorState> _anchors = [];

  /// Height of the bar the toasts sit above (tab bar or sticky action bar), 0 when none.
  static final ValueNotifier<double> bottomInset = ValueNotifier(0);

  static void add(
    OverlayState overlay, {
    required String id,
    required bool persistent,
    required Widget Function(Animation<double> progress, VoidCallback close) builder,
  }) {
    if (_overlay != overlay || _entry == null || !_entry!.mounted) {
      _entry?.remove();
      _overlay = overlay;
      _entry = OverlayEntry(builder: (_) => const _ToastRegion());
      overlay.insert(_entry!);
    }
    final item = _ToastItem(id: id, persistent: persistent, builder: builder);
    final shown = [..._shown.value]..removeWhere((x) => x.id == id);
    _queue.removeWhere((x) => x.id == id);
    if (shown.length >= max) {
      _queue.add(item);
    } else {
      shown.add(item);
    }
    _shown.value = shown;
  }

  static void _remove(_ToastItem item) {
    final shown = [..._shown.value]..remove(item);
    while (shown.length < max && _queue.isNotEmpty) {
      shown.add(_queue.removeAt(0));
    }
    _shown.value = shown;
    if (shown.isEmpty) {
      _entry?.remove();
      _entry = null;
    }
  }

  /// Removes every toast at once (sign out, tests).
  static void clear() {
    _queue.clear();
    _shown.value = const [];
    _entry?.remove();
    _entry = null;
  }

  static void _updateInset() {
    var inset = 0.0;
    for (final a in _anchors.reversed) {
      if (a.visible) {
        inset = a.height;
        break;
      }
    }
    if (bottomInset.value != inset) bottomInset.value = inset;
  }
}

/// Marks the bottom bar toasts must stay above (the tab bar, a sticky action bar). The last
/// visible anchor wins, so a pushed page's sticky bar takes over from the tab bar under it.
class MuToastAnchor extends StatefulWidget {
  const MuToastAnchor({super.key, required this.child});

  final Widget child;

  @override
  State<MuToastAnchor> createState() => _MuToastAnchorState();
}

class _MuToastAnchorState extends State<MuToastAnchor> {
  double height = 0;
  bool visible = true;

  @override
  void initState() {
    super.initState();
    MuToaster._anchors.add(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pages covered by another page keep their state with tickers off.
    visible = TickerMode.valuesOf(context).enabled;
    _schedule();
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) height = box.size.height;
      MuToaster._updateInset();
    });
  }

  @override
  void dispose() {
    MuToaster._anchors.remove(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => MuToaster._updateInset());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _schedule();
    return widget.child;
  }
}

class _ToastRegion extends StatefulWidget {
  const _ToastRegion();

  @override
  State<_ToastRegion> createState() => _ToastRegionState();
}

class _ToastRegionState extends State<_ToastRegion> {
  bool _expanded = false;

  // Toast.md: older toasts peek 10 px behind the newest at scale 0.95 / 0.90.
  static const double _peek = 10;
  static const List<double> _scales = [1, 0.95, 0.90];

  void _toggle() {
    setState(() => _expanded = !_expanded);
    for (final item in MuToaster._shown.value) {
      final tile = item.key.currentState;
      _expanded ? tile?._pause() : tile?._resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= MuLayout.bpExpanded;
    return ValueListenableBuilder<double>(
      valueListenable: MuToaster.bottomInset,
      builder: (context, inset, _) => ValueListenableBuilder<List<_ToastItem>>(
        valueListenable: MuToaster._shown,
        builder: (context, shown, _) {
          if (shown.isEmpty) return const SizedBox.shrink();
          if (shown.length < 2 && _expanded) _expanded = false;
          Widget tile(_ToastItem item) => _ToastTile(
            key: item.key,
            item: item,
            fromTop: wide,
            paused: _expanded,
            onDone: () => MuToaster._remove(item),
          );
          final newest = shown.last;
          final Widget stack;
          if (_expanded || shown.length == 1) {
            stack = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, item) in (wide ? shown.reversed : shown).indexed) ...[
                  if (i > 0) const SizedBox(height: MuSpace.s2),
                  tile(item),
                ],
              ],
            );
          } else {
            final older = shown.sublist(0, shown.length - 1).reversed.toList();
            stack = GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: _toggle,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final (i, item) in older.indexed.toList().reversed) ...[
                    // Kept alive offstage so its timer runs; only its surface peeks.
                    Offstage(child: tile(item)),
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(0, (wide ? 1 : -1) * _peek * (i + 1)),
                        child: Transform.scale(
                          scale: _scales[(i + 1).clamp(0, _scales.length - 1)],
                          alignment: wide ? Alignment.bottomCenter : Alignment.topCenter,
                          child: const _Covered(),
                        ),
                      ),
                    ),
                  ],
                  tile(newest),
                ],
              ),
            );
          }
          final bottom = MediaQuery.paddingOf(context).bottom;
          return Align(
            alignment: wide ? AlignmentDirectional.topEnd : Alignment.bottomCenter,
            child: Padding(
              padding: wide
                  ? EdgeInsetsDirectional.only(
                      top: MediaQuery.paddingOf(context).top + MuSpace.s4,
                      end: MuSpace.s6,
                    )
                  : EdgeInsets.fromLTRB(
                      MuSpace.s4,
                      0,
                      MuSpace.s4,
                      (inset > bottom ? inset : bottom) + MuSpace.s4,
                    ),
              child: SizedBox(
                width: wide ? MuSize.toast : double.infinity,
                child: Semantics(
                  container: true,
                  label: l10n.notifications,
                  explicitChildNodes: true,
                  child: stack,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// An older toast behind the newest: only its surface shows.
class _Covered extends StatelessWidget {
  const _Covered();

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.toastBg,
        borderRadius: MuRadius.mdAll,
        boxShadow: MuElevation.of(context).level2,
      ),
    );
  }
}

class _ToastTile extends StatefulWidget {
  const _ToastTile({
    super.key,
    required this.item,
    required this.fromTop,
    required this.paused,
    required this.onDone,
  });

  final _ToastItem item;
  final bool fromTop;
  final bool paused;
  final VoidCallback onDone;

  @override
  State<_ToastTile> createState() => _ToastTileState();
}

class _ToastTileState extends State<_ToastTile> with TickerProviderStateMixin {
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
      if (!widget.paused) _resume();
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
    if (!widget.item.persistent && !_closing) {
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
    final toast = MouseRegion(
      onEnter: (_) => _pause(),
      onExit: (_) {
        if (!widget.paused) _resume();
      },
      child: widget.item.builder(_life, _close),
    );
    return AnimatedBuilder(
      animation: _show,
      builder: (context, child) {
        final t = MuMotion.enter.transform(_show.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * _slide * (widget.fromTop ? -1 : 1)),
            child: child,
          ),
        );
      },
      child: toast,
    );
  }
}
