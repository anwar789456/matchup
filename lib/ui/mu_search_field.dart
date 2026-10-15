import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_icon_button.dart';
import 'src/interaction.dart';

enum MuSearchFieldSize { l, m }

/// One row of the suggestion panel.
@immutable
class MuSearchSuggestion<T> {
  const MuSearchSuggestion({required this.value, required this.title, this.subtitle, this.leading});

  final T value;
  final String title;
  final String? subtitle;
  final Widget? leading;
}

/// SearchField (components/SearchField.md): the pill search bar with magnifier and clear button,
/// opening a panel of suggestions under it; the matched letters get the Volt marker.
///
/// [search] is called (debounced 250 ms) with the query and returns the rows, up to 3 per group in
/// the full search. Recent searches, groups and the filter button come with the Explorer milestone.
class MuSearchField<T> extends StatefulWidget {
  const MuSearchField({
    super.key,
    required this.label,
    this.placeholder,
    this.controller,
    this.size = MuSearchFieldSize.l,
    this.search,
    this.onSelected,
    this.onSubmitted,
    this.emptyMessage,
    this.enabled = true,
  });

  /// Accessible name (« Ajouter une zone »); visually carried by the magnifier and placeholder.
  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final MuSearchFieldSize size;
  final Future<List<MuSearchSuggestion<T>>> Function(String query)? search;
  final ValueChanged<T>? onSelected;
  final ValueChanged<String>? onSubmitted;

  /// Shown in the panel when nothing matches (« Aucun résultat pour “…” »).
  final String Function(String query)? emptyMessage;
  final bool enabled;

  @override
  State<MuSearchField<T>> createState() => _MuSearchFieldState<T>();
}

class _MuSearchFieldState<T> extends State<MuSearchField<T>> {
  TextEditingController? _own;
  final _focus = FocusNode();
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  Timer? _debounce;
  List<MuSearchSuggestion<T>> _results = const [];
  String _query = '';

  // SearchField.md: debounce 250 ms; panel max 420 high.
  static const _debounceTime = Duration(milliseconds: 250);
  static const double _panelMax = 420;

  TextEditingController get _controller => widget.controller ?? (_own ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onText);
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onText);
    _own?.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!_focus.hasFocus) _close();
    setState(() {});
  }

  void _onText() {
    final q = _controller.text.trim();
    setState(() {});
    if (q == _query) return;
    _query = q;
    _debounce?.cancel();
    if (q.isEmpty || widget.search == null) {
      _close();
      return;
    }
    _debounce = Timer(_debounceTime, () async {
      final results = await widget.search!(q);
      if (!mounted || q != _query) return;
      setState(() => _results = results);
      _portal.show();
    });
  }

  void _close() {
    if (_portal.isShowing) _portal.hide();
  }

  void _select(MuSearchSuggestion<T> s) {
    widget.onSelected?.call(s.value);
    _controller.clear();
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final large = widget.size == MuSearchFieldSize.l;
    final valueStyle = large ? MuType.bodyL : MuType.body;
    final height = large ? MuSize.controlL : MuSize.controlM;
    final focused = _focus.hasFocus;

    final field = AnimatedContainer(
      duration: MuMotion.durationOf(context, MuMotion.fast),
      height: height,
      padding: EdgeInsetsDirectional.only(start: large ? MuSpace.s4 : MuSpace.s3, end: MuSpace.s1),
      decoration: ShapeDecoration(
        color: widget.enabled ? c.surface : c.disabledFill,
        shape: StadiumBorder(
          side: BorderSide(
            color: focused ? c.focus : c.borderControl,
            width: focused ? 2 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.magnifyingGlass(), size: MuSize.iconS, color: c.textSecondary),
          const SizedBox(width: MuSpace.s2),
          Expanded(
            child: Semantics(
              label: widget.label,
              textField: true,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                // Same tap group as the panel: tapping a suggestion keeps the field focused.
                groupId: _focus,
                enabled: widget.enabled,
                textInputAction: TextInputAction.search,
                style: valueStyle.copyWith(color: c.text),
                cursorColor: c.focus,
                onSubmitted: (v) {
                  if (_results.isNotEmpty && _portal.isShowing) {
                    _select(_results.first);
                  } else {
                    widget.onSubmitted?.call(v);
                  }
                },
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  hintText: widget.placeholder,
                  hintStyle: valueStyle.copyWith(color: c.textSecondary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            MuIconButton(
              icon: PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
              label: 'Effacer',
              size: MuIconButtonSize.s,
              color: c.textSecondary,
              onPressed: _controller.clear,
            )
          else
            const SizedBox(width: MuSpace.s3),
        ],
      ),
    );

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) => _panel(context),
        child: MuFocusRing(borderRadius: MuRadius.fullAll, forceVisible: true, child: field),
      ),
    );
  }

  Widget _panel(BuildContext context) {
    final c = context.mu;
    final box = this.context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 0;
    final height = box?.size.height ?? 0;
    final message = widget.emptyMessage?.call(_query) ?? 'Aucun résultat pour « $_query »';
    return CompositedTransformFollower(
      link: _link,
      showWhenUnlinked: false,
      offset: Offset(0, height + MuSpace.s1),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: TapRegion(
          groupId: _focus,
          onTapOutside: (_) => _close(),
          child: SizedBox(
            width: width,
            child: Material(
              color: c.surfaceElevated,
              borderRadius: MuRadius.lgAll,
              elevation: MuElevation.materialLevel2,
              shadowColor: MuElevation.of(context).shadowColor,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: _panelMax),
                child: _results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(MuSpace.s4),
                        child: Text(message, style: MuType.body.copyWith(color: c.textSecondary)),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(MuSpace.s2),
                        shrinkWrap: true,
                        children: [
                          for (final r in _results)
                            InkWell(
                              borderRadius: MuRadius.smAll,
                              onTap: () => _select(r),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: MuSize.touchTarget),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: MuSpace.s3, vertical: MuSpace.s2),
                                  child: Row(
                                    children: [
                                      if (r.leading != null) ...[
                                        r.leading!,
                                        const SizedBox(width: MuSpace.s3),
                                      ],
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text.rich(_highlight(r.title, c),
                                                style: MuType.label.copyWith(color: c.text)),
                                            if (r.subtitle != null)
                                              Text(r.subtitle!,
                                                  style: MuType.caption
                                                      .copyWith(color: c.textSecondary)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Volt marker on the matched letters, ignoring case and accents.
  TextSpan _highlight(String text, MuColors c) {
    final i = foldAccents(text).indexOf(foldAccents(_query));
    if (_query.isEmpty || i < 0) return TextSpan(text: text);
    final end = i + _query.length;
    return TextSpan(children: [
      TextSpan(text: text.substring(0, i)),
      TextSpan(
        text: text.substring(i, end),
        style: TextStyle(color: c.onAccent, background: Paint()..color = c.accent),
      ),
      TextSpan(text: text.substring(end)),
    ]);
  }
}

/// Lower-case without French diacritics, for search matching (« ennasr » finds « Ennasr »,
/// « sidi bou said » finds « Sidi Bou Saïd »). Keeps the string length.
String foldAccents(String s) {
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final lower = s.toLowerCase();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    b.write(i < 0 ? ch : to[i]);
  }
  return b.toString();
}
