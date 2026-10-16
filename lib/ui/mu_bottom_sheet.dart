import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_icon_button.dart';

/// The sheet heights: shares of the screen (`sheet-peek` 30 %, `sheet-half` 55 %, `sheet-full`
/// 92 %), or `auto` (the content, up to 92 %, no snap points).
enum MuSheetHeight {
  peek(MuSize.sheetPeek),
  half(MuSize.sheetHalf),
  full(MuSize.sheetFull),
  auto(MuSize.sheetFull);

  const MuSheetHeight(this.share);

  final double share;
}

/// BottomSheet (components/BottomSheet.md): the panel that rises from the bottom edge — a drag
/// handle, a header with title and close, a scrolling body and a sticky footer.
///
/// Open it with [MuBottomSheet.show]; the widget itself is the panel (also shown inline in the
/// gallery). [child] and [footer] are rebuilt by the caller: pass a `Consumer` to keep them live.
class MuBottomSheet extends StatefulWidget {
  const MuBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.label,
    this.headerAction,
    this.footer,
    this.showClose = true,
    this.closeLabel = 'Fermer',
    this.onClose,
    this.scrollController,
    this.onHandle,
    this.handleExpands = true,
  });

  final Widget child;

  /// `h3`, one line: names the task (« Filtres », « Comment partager ? »).
  final String? title;

  /// Accessible name when there is no title.
  final String? label;

  /// A tertiary button before the close (« Réinitialiser »).
  final Widget? headerAction;

  /// Sticky footer: one XL primary, or secondary + primary.
  final Widget? footer;
  final bool showClose;
  final String closeLabel;
  final VoidCallback? onClose;

  /// The draggable sheet's controller, so scrolling the body at its top resizes the sheet.
  final ScrollController? scrollController;

  /// The handle is a real button: it cycles the heights.
  final VoidCallback? onHandle;

  /// « Agrandir le panneau », or « Réduire le panneau » at the top height.
  final bool handleExpands;

  // BottomSheet.md: handle 36 × 4 in a 64 × 20 button `space-1` from the top; header min 56.
  static const Size _handle = Size(36, 4);
  static const Size _handleButton = Size(64, 20);

  /// Shows a modal sheet at [height], snapping to [snapPoints] (peek, half, full by default),
  /// with the `scrim` behind it. Returns what the sheet pops with.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    String? label,
    Widget? headerAction,
    Widget? footer,
    MuSheetHeight height = MuSheetHeight.half,
    List<MuSheetHeight> snapPoints = const [
      MuSheetHeight.peek,
      MuSheetHeight.half,
      MuSheetHeight.full,
    ],
    bool dismissible = true,
    bool showClose = true,
  }) {
    final c = context.mu;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      // Above the tab bar and the FAB (EXP-04): sheets belong to the whole app, not one tab.
      useRootNavigator: true,
      useSafeArea: true,
      isDismissible: dismissible,
      // The snapping sheet drags itself; only the content-sized one uses the route's drag.
      enableDrag: dismissible && height == MuSheetHeight.auto,
      backgroundColor: c.surfaceElevated.withValues(alpha: 0),
      elevation: 0,
      barrierColor: c.scrim,
      barrierLabel: title ?? label,
      sheetAnimationStyle: AnimationStyle(
        duration: reduce ? Duration.zero : MuMotion.slow,
        reverseDuration: reduce ? Duration.zero : MuMotion.base,
        curve: MuMotion.enter,
        reverseCurve: MuMotion.exit,
      ),
      builder: (context) {
        void close() => Navigator.of(context).maybePop();
        if (height == MuSheetHeight.auto) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * MuSheetHeight.auto.share,
            ),
            child: MuBottomSheet(
              title: title,
              label: label,
              headerAction: headerAction,
              footer: footer,
              showClose: showClose && dismissible,
              onClose: close,
              child: child,
            ),
          );
        }
        return _SnappingSheet(
          height: height,
          snapPoints: snapPoints,
          dismissible: dismissible,
          builder: (controller, onHandle, atTop) => MuBottomSheet(
            title: title,
            label: label,
            headerAction: headerAction,
            footer: footer,
            showClose: showClose && dismissible,
            onClose: close,
            scrollController: controller,
            onHandle: onHandle,
            handleExpands: !atTop,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<MuBottomSheet> createState() => _MuBottomSheetState();
}

class _MuBottomSheetState extends State<MuBottomSheet> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    final scrolled = n.metrics.pixels > 0;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final e = MuElevation.of(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final hasFooter = widget.footer != null;

    final handle = Semantics(
      button: true,
      label: widget.handleExpands ? 'Agrandir le panneau' : 'Réduire le panneau',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onHandle,
        child: SizedBox(
          height: MuSize.touchTarget,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: MuSpace.s1),
              child: SizedBox.fromSize(
                size: MuBottomSheet._handleButton,
                child: Center(
                  child: Container(
                    width: MuBottomSheet._handle.width,
                    height: MuBottomSheet._handle.height,
                    decoration: BoxDecoration(
                      color: c.borderStrong,
                      borderRadius: MuRadius.fullAll,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final hasHeader = widget.title != null || widget.headerAction != null || widget.showClose;
    final header = !hasHeader
        ? null
        : AnimatedContainer(
            duration: MuMotion.durationOf(context, MuMotion.fast),
            constraints: const BoxConstraints(minHeight: MuSize.controlXl),
            padding: const EdgeInsetsDirectional.only(start: MuSpace.s4, end: MuSpace.s2),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _scrolled ? c.border : c.border.withValues(alpha: 0)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: widget.title == null
                      ? const SizedBox.shrink()
                      : Semantics(
                          header: true,
                          child: Text(
                            widget.title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MuType.h3.copyWith(color: c.text),
                          ),
                        ),
                ),
                ?widget.headerAction,
                if (widget.showClose)
                  MuIconButton(
                    icon: PhosphorIcons.x(),
                    label: widget.closeLabel,
                    size: MuIconButtonSize.l,
                    onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
                  ),
              ],
            ),
          );

    final body = NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        padding: EdgeInsets.fromLTRB(
          MuSpace.s4,
          MuSpace.s2,
          MuSpace.s4,
          hasFooter ? MuSpace.s4 : MuSpace.s6 + safeBottom,
        ),
        child: widget.child,
      ),
    );

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: widget.title ?? widget.label,
      child: Material(
        color: c.surfaceElevated,
        borderRadius: MuRadius.lgTop,
        clipBehavior: Clip.antiAlias,
        elevation: MuElevation.materialLevel3,
        shadowColor: e.shadowColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The handle overlaps the header's top, as in the spec (64 × 20 button at space-1).
            SizedBox(
              height: MuSpace.s5,
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: MuSize.touchTarget,
                child: handle,
              ),
            ),
            ?header,
            Flexible(child: body),
            if (hasFooter)
              DecoratedBox(
                decoration: BoxDecoration(color: c.surfaceElevated, boxShadow: e.level2Up),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    MuSpace.s4,
                    MuSpace.s3,
                    MuSpace.s4,
                    MuSpace.s3 + safeBottom,
                  ),
                  child: widget.footer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A `DraggableScrollableSheet` snapping to the given heights; releasing below 60 % of the lowest
/// one closes it.
class _SnappingSheet extends StatefulWidget {
  const _SnappingSheet({
    required this.height,
    required this.snapPoints,
    required this.dismissible,
    required this.builder,
  });

  final MuSheetHeight height;
  final List<MuSheetHeight> snapPoints;
  final bool dismissible;
  final Widget Function(ScrollController controller, VoidCallback onHandle, bool atTop) builder;

  @override
  State<_SnappingSheet> createState() => _SnappingSheetState();
}

class _SnappingSheetState extends State<_SnappingSheet> {
  final _controller = DraggableScrollableController();
  late double _size = widget.height.share;
  bool _closing = false;

  // BottomSheet.md: releasing below 60 % of the lowest height closes the sheet.
  static const double _closeShare = 0.6;

  List<double> get _snaps {
    final s = {...widget.snapPoints.map((p) => p.share), widget.height.share}.toList()..sort();
    return s;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final size = _controller.size;
      if ((size - _size).abs() > 0.001) setState(() => _size = size);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _cycle() {
    final snaps = _snaps;
    final i = snaps.indexWhere((s) => s > _size + 0.01);
    final next = i < 0 ? snaps.first : snaps[i];
    _controller.animateTo(
      next,
      duration: MuMotion.durationOf(context, MuMotion.slow),
      curve: MuMotion.move,
    );
  }

  @override
  Widget build(BuildContext context) {
    final snaps = _snaps;
    final atTop = _size >= snaps.last - 0.01;
    final minSize = widget.dismissible ? 0.0 : snaps.first;
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (n) {
        if (widget.dismissible && !_closing && n.extent < snaps.first * _closeShare) {
          _closing = true;
          Navigator.of(context).maybePop();
        }
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _controller,
        expand: false,
        initialChildSize: widget.height.share,
        minChildSize: minSize,
        maxChildSize: snaps.last,
        snap: true,
        snapSizes: [
          for (final s in snaps)
            if (s > minSize && s < snaps.last) s,
        ],
        builder: (context, scrollController) => widget.builder(scrollController, _cycle, atTop),
      ),
    );
  }
}
