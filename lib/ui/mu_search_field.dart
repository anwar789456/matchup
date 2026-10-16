import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/search.dart';
import '../theme/theme.dart';
import 'mu_button.dart';
import 'mu_icon_button.dart';
import 'src/interaction.dart';

enum MuSearchFieldSize { l, m }

/// One row of the suggestion panel.
@immutable
class MuSearchSuggestion<T> {
  const MuSearchSuggestion({
    required this.value,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.semanticLabel,
  });

  final T value;
  final String title;

  /// Highlighted too (« Football · La Marsa »).
  final String? subtitle;

  /// A 40 tile, sport tile or Avatar S.
  final Widget? leading;

  /// The game time « 20h00 » in `num-s` at the end.
  final String? trailing;
  final String? semanticLabel;
}

/// A group of suggestions under its plural name (« Terrains », « Joueurs », « Parties »).
@immutable
class MuSearchGroup<T> {
  const MuSearchGroup({required this.label, required this.items});

  final String label;
  final List<MuSearchSuggestion<T>> items;
}

/// Volt marker on the letters of [text] matching [query], ignoring case and accents.
TextSpan muSearchHighlight(String text, String query, MuColors c) {
  final i = query.isEmpty ? -1 : foldAccents(text).indexOf(foldAccents(query));
  if (i < 0) return TextSpan(text: text);
  final end = i + query.length;
  return TextSpan(children: [
    TextSpan(text: text.substring(0, i)),
    TextSpan(
      text: text.substring(i, end),
      style: TextStyle(color: c.onAccent, background: Paint()..color = c.accent),
    ),
    TextSpan(text: text.substring(end)),
  ]);
}

/// SearchField (components/SearchField.md): the pill search bar with magnifier and clear button,
/// opening a panel of suggestions under it; the matched letters get the Volt marker.
///
/// [search] is called (debounced 250 ms) with the query and returns the rows of the panel. The full
/// search page shows recent searches and groups inline with [MuSearchResults] instead; [onTap]
/// turns the field into a button that opens that page.
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
    this.autofocus = false,
    this.onChanged,
    this.onTap,
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
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  /// Read-only: tapping the field calls this (Explorer opens the search page).
  final VoidCallback? onTap;

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
    widget.onChanged?.call(q);
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
                autofocus: widget.autofocus,
                readOnly: widget.onTap != null,
                onTap: widget.onTap,
                // Same tap group as the panel: tapping a suggestion keeps the field focused.
                groupId: _focus,
                enabled: widget.enabled,
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
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
                  isCollapsed: true,
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

  TextSpan _highlight(String text, MuColors c) => muSearchHighlight(text, _query, c);
}

/// The search page's results (EXP-05), inline under the field: recent searches with « Tout
/// effacer » (those matching the query once typing starts), then the groups — up to
/// [maxPerGroup] rows each — with the matched letters marked; or the no-result state.
class MuSearchResults<T> extends StatelessWidget {
  const MuSearchResults({
    super.key,
    required this.query,
    this.recent = const [],
    this.groups = const [],
    this.maxPerGroup = 3,
    this.onSelected,
    this.onRecent,
    this.onRemoveRecent,
    this.onClearRecent,
    this.emptyAction,
  });

  final String query;
  final List<String> recent;
  final List<MuSearchGroup<T>> groups;
  final int maxPerGroup;
  final ValueChanged<T>? onSelected;
  final ValueChanged<String>? onRecent;
  final ValueChanged<String>? onRemoveRecent;
  final VoidCallback? onClearRecent;

  /// The helpful action of the no-result state (« Voir les terrains près de moi »).
  final Widget? emptyAction;

  // SearchField.md: the no-result magnifier sits in a 48 circle.
  static const double _emptyIcon = 48;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final q = foldAccents(query);
    final recents = [
      for (final r in recent)
        if (q.isEmpty || foldAccents(r).contains(q)) r,
    ];
    final shown = [
      for (final g in groups)
        if (g.items.isNotEmpty) g,
    ];

    Widget header(String label, [Widget? action]) => Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            MuSpace.s3,
            MuSpace.s3,
            MuSpace.s1,
            MuSpace.s1,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    label.toUpperCase(),
                    style: MuType.overline.copyWith(color: c.textSecondary),
                  ),
                ),
              ),
              ?action,
            ],
          ),
        );

    if (recents.isEmpty && shown.isEmpty && query.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(MuSpace.s6),
        child: Column(
          children: [
            Container(
              width: _emptyIcon,
              height: _emptyIcon,
              decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
              child: Icon(
                PhosphorIcons.magnifyingGlass(),
                size: MuSize.iconM,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: MuSpace.s3),
            Text(
              'Aucun résultat pour « $query »',
              textAlign: TextAlign.center,
              style: MuType.label.copyWith(color: c.text),
            ),
            const SizedBox(height: MuSpace.s1),
            Text(
              'Vérifie l’orthographe ou cherche un quartier, un terrain ou un joueur.',
              textAlign: TextAlign.center,
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
            if (emptyAction != null) ...[const SizedBox(height: MuSpace.s4), emptyAction!],
          ],
        ),
      );
    }

    final children = <Widget>[];
    if (recents.isNotEmpty) {
      children.add(header(
        'Recherches récentes',
        onClearRecent == null
            ? null
            : MuButton.link(label: 'Tout effacer', onPressed: onClearRecent),
      ));
      for (final r in recents) {
        children.add(_ResultRow(
          onTap: onRecent == null ? null : () => onRecent!(r),
          semanticLabel: 'Recherche récente : $r',
          leading: Icon(
            PhosphorIcons.clockCounterClockwise(),
            size: MuSize.iconS,
            color: c.textSecondary,
          ),
          title: Text.rich(
            muSearchHighlight(r, query, c),
            style: MuType.body.copyWith(color: c.text),
          ),
          trailing: onRemoveRecent == null
              ? null
              : MuIconButton(
                  icon: PhosphorIcons.x(),
                  label: 'Retirer « $r » des recherches récentes',
                  size: MuIconButtonSize.s,
                  color: c.textSecondary,
                  onPressed: () => onRemoveRecent!(r),
                ),
        ));
      }
    }
    for (final g in shown) {
      if (children.isNotEmpty) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
          child: Divider(height: 1, thickness: 1, color: c.border),
        ));
      }
      children.add(header(g.label));
      for (final item in g.items.take(maxPerGroup)) {
        children.add(_ResultRow(
          onTap: onSelected == null ? null : () => onSelected!(item.value),
          semanticLabel: item.semanticLabel ??
              [item.title, item.subtitle, item.trailing].whereType<String>().join(', '),
          leading: item.leading,
          title: Text.rich(
            muSearchHighlight(item.title, query, c),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MuType.label.copyWith(color: c.text),
          ),
          subtitle: item.subtitle == null
              ? null
              : Text.rich(
                  muSearchHighlight(item.subtitle!, query, c),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
          trailing: item.trailing == null
              ? null
              : Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(item.trailing!, style: MuType.numS.copyWith(color: c.text)),
                ),
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

/// A result row: ≥ 44 high, `radius-sm`, padding `space-2` `space-3`, `space-3` gaps.
class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.title,
    required this.semanticLabel,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget title;
  final String semanticLabel;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: MuRadius.smAll,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: MuSize.touchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: MuSpace.s3)],
              Expanded(
                child: Semantics(
                  button: onTap != null,
                  label: semanticLabel,
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [title, ?subtitle],
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: MuSpace.s3), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
