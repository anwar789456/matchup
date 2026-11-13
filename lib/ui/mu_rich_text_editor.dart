import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../l10n/l10n.dart';
import '../theme/theme.dart';
import 'mu_button.dart';
import 'mu_icon_button.dart';
import 'mu_text_field.dart';

/// The formatting tools (RichTextEditor.md: one heading level is left out on purpose for posts).
enum MuRichTool { bold, italic, bulletList, numberedList, quote, link, image }

/// A [TextEditingController] for light Markdown (`**gras**`, `*italique*`, `- `, `1. `, `> `,
/// `[texte](lien)`, `@pseudo`) that shows the formatting while typing: bold is bold, markers are
/// dimmed in `text-secondary`, links and mentions in `link`. The text stays plain Markdown, the
/// format the forum stores.
class MuMarkdownController extends TextEditingController {
  MuMarkdownController({super.text});

  static final _inline = RegExp(
    r'(\*\*)(.+?)(\*\*)|(?<!\*)(\*)(?!\*)(.+?)(?<!\*)(\*)(?!\*)|\[([^\]]+)\]\(([^)]+)\)|(?<![\w@])@[a-zA-Z0-9][a-zA-Z0-9._]{1,38}[a-zA-Z0-9]',
  );
  static final _block = RegExp(r'^(\s{0,3})(- |\* |\d+\. |> )');

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final c = context.mu;
    final base = style ?? MuType.bodyL;
    final marker = base.copyWith(color: c.textSecondary);
    final spans = <InlineSpan>[];
    final lines = text.split('\n');
    for (final (i, line) in lines.indexed) {
      var rest = line;
      var lineStyle = base;
      final block = _block.firstMatch(line);
      if (block != null) {
        spans.add(TextSpan(text: block[0], style: marker));
        rest = line.substring(block.end);
        if (block[2] == '> ') lineStyle = base.copyWith(color: c.textSecondary);
      }
      _inlineSpans(rest, lineStyle, marker, c, spans);
      if (i < lines.length - 1) spans.add(TextSpan(text: '\n', style: base));
    }
    return TextSpan(style: base, children: spans);
  }

  static void _inlineSpans(String s, TextStyle style, TextStyle marker, MuColors c, List<InlineSpan> out) {
    var at = 0;
    for (final m in _inline.allMatches(s)) {
      if (m.start > at) out.add(TextSpan(text: s.substring(at, m.start), style: style));
      if (m[1] != null) {
        out
          ..add(TextSpan(text: m[1], style: marker))
          ..add(
            TextSpan(
              text: m[2],
              style: style.merge(MuType.labelL.copyWith(color: style.color)),
            ),
          )
          ..add(TextSpan(text: m[3], style: marker));
      } else if (m[4] != null) {
        out
          ..add(TextSpan(text: m[4], style: marker))
          ..add(
            TextSpan(
              text: m[5],
              style: style.copyWith(fontStyle: FontStyle.italic),
            ),
          )
          ..add(TextSpan(text: m[6], style: marker));
      } else if (m[7] != null) {
        out
          ..add(TextSpan(text: '[', style: marker))
          ..add(
            TextSpan(
              text: m[7],
              style: style.copyWith(color: c.link, decoration: TextDecoration.underline, decorationColor: c.link),
            ),
          )
          ..add(TextSpan(text: '](${m[8]})', style: marker));
      } else {
        out.add(
          TextSpan(
            text: m[0],
            style: style.copyWith(color: c.link),
          ),
        );
      }
      at = m.end;
    }
    if (at < s.length) out.add(TextSpan(text: s.substring(at), style: style));
  }

  // ── Formatting ──────────────────────────────────────────────────────────────────────────

  /// The formats under the caret, for the pressed tools.
  Set<MuRichTool> get activeTools {
    final out = <MuRichTool>{};
    final caret = selection.isValid ? selection.start : text.length;
    final lineStart = text.lastIndexOf('\n', caret == 0 ? 0 : caret - 1) + 1;
    final lineEnd = text.indexOf('\n', caret);
    final line = text.substring(lineStart, lineEnd < 0 ? text.length : lineEnd);
    final block = _block.firstMatch(line)?[2];
    if (block == '- ' || block == '* ') out.add(MuRichTool.bulletList);
    if (block != null && RegExp(r'^\d+\. $').hasMatch(block)) out.add(MuRichTool.numberedList);
    if (block == '> ') out.add(MuRichTool.quote);
    final col = caret - lineStart;
    for (final m in _inline.allMatches(line)) {
      if (col < m.start || col > m.end) continue;
      if (m[1] != null) out.add(MuRichTool.bold);
      if (m[4] != null) out.add(MuRichTool.italic);
      if (m[7] != null) out.add(MuRichTool.link);
    }
    return out;
  }

  /// Wraps the selection in [mark] (or removes it when already wrapped). With no selection,
  /// inserts the pair and puts the caret between.
  void toggleInline(String mark) {
    final sel = selection.isValid ? selection : TextSelection.collapsed(offset: text.length);
    final before = text.substring(0, sel.start);
    final inside = text.substring(sel.start, sel.end);
    final after = text.substring(sel.end);
    if (before.endsWith(mark) && after.startsWith(mark)) {
      value = TextEditingValue(
        text: before.substring(0, before.length - mark.length) + inside + after.substring(mark.length),
        selection: TextSelection(baseOffset: sel.start - mark.length, extentOffset: sel.end - mark.length),
      );
      return;
    }
    if (inside.startsWith(mark) && inside.endsWith(mark) && inside.length >= mark.length * 2) {
      final bare = inside.substring(mark.length, inside.length - mark.length);
      value = TextEditingValue(
        text: before + bare + after,
        selection: TextSelection(baseOffset: sel.start, extentOffset: sel.start + bare.length),
      );
      return;
    }
    value = TextEditingValue(
      text: '$before$mark$inside$mark$after',
      selection: inside.isEmpty
          ? TextSelection.collapsed(offset: sel.start + mark.length)
          : TextSelection(baseOffset: sel.start + mark.length, extentOffset: sel.end + mark.length),
    );
  }

  /// Adds or removes a line prefix (`- `, `1. `, `> `) on every line of the selection.
  void toggleBlock(MuRichTool tool) {
    final sel = selection.isValid ? selection : TextSelection.collapsed(offset: text.length);
    final start = text.lastIndexOf('\n', sel.start == 0 ? 0 : sel.start - 1) + 1;
    final endNl = text.indexOf('\n', sel.end);
    final end = endNl < 0 ? text.length : endNl;
    final lines = text.substring(start, end).split('\n');
    bool has(String l) => switch (tool) {
      MuRichTool.bulletList => l.startsWith('- '),
      MuRichTool.numberedList => RegExp(r'^\d+\. ').hasMatch(l),
      _ => l.startsWith('> '),
    };
    final remove = lines.every(has);
    final changed = [
      for (final (i, l) in lines.indexed)
        () {
          final bare = l.replaceFirst(_block, '');
          if (remove) return bare;
          return switch (tool) {
            MuRichTool.bulletList => '- $bare',
            MuRichTool.numberedList => '${i + 1}. $bare',
            _ => '> $bare',
          };
        }(),
    ].join('\n');
    final newText = text.replaceRange(start, end, changed);
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + changed.length),
    );
  }

  /// Inserts `[label](url)` over the selection (or « lien »).
  void insertLink(String url, {required String fallbackLabel}) {
    final sel = selection.isValid ? selection : TextSelection.collapsed(offset: text.length);
    final label = sel.isCollapsed ? fallbackLabel : text.substring(sel.start, sel.end);
    final link = '[$label]($url)';
    value = TextEditingValue(
      text: text.replaceRange(sel.start, sel.end, link),
      selection: TextSelection.collapsed(offset: sel.start + link.length),
    );
  }
}

/// RichTextEditor (components/RichTextEditor.md): a text area with a formatting toolbar —
/// Gras, Italique · Liste, Liste numérotée, Citation · Lien, Image — for forum posts. One box
/// (`radius-sm`, `border-control`), the toolbar scrolls sideways on narrow screens, the pressed
/// tool follows the caret, the link bar opens under the toolbar. Counter « 380/2 000 » below.
class MuRichTextEditor extends StatefulWidget {
  const MuRichTextEditor({
    super.key,
    required this.label,
    required this.controller,
    this.tools = MuRichTool.values,
    this.maxLength,
    this.minLines = 5,
    this.maxLines = 14,
    this.placeholder,
    this.helper,
    this.error,
    this.optional = false,
    this.enabled = true,
    this.focusNode,
    this.onChanged,
    this.onInsertImage,
  });

  final String label;
  final MuMarkdownController controller;
  final List<MuRichTool> tools;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final String? placeholder;
  final String? helper;
  final String? error;
  final bool optional;
  final bool enabled;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  /// « Image »: the caller opens its picker (images go through FileUpload).
  final VoidCallback? onInsertImage;

  @override
  State<MuRichTextEditor> createState() => _MuRichTextEditorState();
}

class _MuRichTextEditorState extends State<MuRichTextEditor> {
  late FocusNode _focus = widget.focusNode ?? FocusNode();
  final _url = TextEditingController();
  bool _linkOpen = false;
  Set<MuRichTool> _active = const {};

  // RichTextEditor.md: separators 1 × 20, toolbar padding space-2.
  static const double _separator = 20;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    _focus.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(MuRichTextEditor old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
    }
    if (old.focusNode != widget.focusNode) {
      _focus.removeListener(_rebuild);
      if (old.focusNode == null) _focus.dispose();
      _focus = widget.focusNode ?? FocusNode();
      _focus.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    _focus.removeListener(_rebuild);
    if (widget.focusNode == null) _focus.dispose();
    _url.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _sync() {
    final active = widget.controller.activeTools;
    if (active.length != _active.length || !active.containsAll(_active)) setState(() => _active = active);
  }

  void _apply(MuRichTool tool) {
    final ctrl = widget.controller;
    switch (tool) {
      case MuRichTool.bold:
        ctrl.toggleInline('**');
      case MuRichTool.italic:
        ctrl.toggleInline('*');
      case MuRichTool.bulletList || MuRichTool.numberedList || MuRichTool.quote:
        ctrl.toggleBlock(tool);
      case MuRichTool.link:
        setState(() => _linkOpen = !_linkOpen);
        return;
      case MuRichTool.image:
        widget.onInsertImage?.call();
        return;
    }
    widget.onChanged?.call(ctrl.text);
    // Toolbar taps never steal the text.
    _focus.requestFocus();
  }

  void _addLink() {
    var url = _url.text.trim();
    if (url.isEmpty) return;
    if (!RegExp('^https?://').hasMatch(url)) url = 'https://$url';
    widget.controller.insertLink(url, fallbackLabel: l10n.forumLien);
    widget.onChanged?.call(widget.controller.text);
    _url.clear();
    setState(() => _linkOpen = false);
    _focus.requestFocus();
  }

  (IconData, String) _toolLook(MuRichTool t) => switch (t) {
    MuRichTool.bold => (PhosphorIcons.textB(), l10n.forumOutilGras),
    MuRichTool.italic => (PhosphorIcons.textItalic(), l10n.forumOutilItalique),
    MuRichTool.bulletList => (PhosphorIcons.listBullets(), l10n.forumOutilListe),
    MuRichTool.numberedList => (PhosphorIcons.listNumbers(), l10n.forumOutilListeNumerotee),
    MuRichTool.quote => (PhosphorIcons.quotes(), l10n.forumOutilCitation),
    MuRichTool.link => (PhosphorIcons.link(), l10n.forumOutilLien),
    MuRichTool.image => (PhosphorIcons.image(), l10n.forumOutilImage),
  };

  static int _group(MuRichTool t) => switch (t) {
    MuRichTool.bold || MuRichTool.italic => 0,
    MuRichTool.bulletList || MuRichTool.numberedList || MuRichTool.quote => 1,
    _ => 2,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final length = widget.controller.text.characters.length;
    final over = widget.maxLength != null && length > widget.maxLength!;
    final error = widget.error ?? (over ? l10n.forumRetireNCaracteres(length - widget.maxLength!) : null);
    final focused = _focus.hasFocus;
    final borderColor = !widget.enabled
        ? c.border
        : error != null
        ? c.error
        : focused
        ? c.focus
        : c.borderControl;

    final toolbar = <Widget>[];
    for (final (i, t) in widget.tools.indexed) {
      if (i > 0 && _group(widget.tools[i - 1]) != _group(t)) {
        toolbar.add(
          Container(
            width: 1,
            height: _separator,
            margin: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
            color: c.border,
          ),
        );
      } else if (i > 0) {
        toolbar.add(const SizedBox(width: MuSpace.s1));
      }
      final (icon, label) = _toolLook(t);
      toolbar.add(
        MuIconButton(
          icon: icon,
          label: label,
          size: MuIconButtonSize.s,
          pressed: t == MuRichTool.link ? _linkOpen : (t == MuRichTool.image ? null : _active.contains(t)),
          onPressed: widget.enabled && (t != MuRichTool.image || widget.onInsertImage != null) ? () => _apply(t) : null,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuFieldLabel(label: widget.label, optional: widget.optional, enabled: widget.enabled),
        const SizedBox(height: MuSpace.s2),
        AnimatedContainer(
          duration: MuMotion.durationOf(context, MuMotion.fast),
          decoration: BoxDecoration(
            color: widget.enabled ? c.surface : c.disabledFill,
            borderRadius: MuRadius.smAll,
            border: Border.all(color: borderColor, width: focused || error != null ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                container: true,
                label: l10n.forumMiseEnForme,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(MuSpace.s2),
                  child: Row(children: toolbar),
                ),
              ),
              Divider(height: 1, thickness: 1, color: c.border),
              if (_linkOpen)
                ColoredBox(
                  color: c.surfaceMuted,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s3, MuSpace.s2, MuSpace.s1, MuSpace.s2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextField(
                              controller: _url,
                              autofocus: true,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _addLink(),
                              style: MuType.body,
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                hintText: l10n.forumLienPlaceholder,
                                hintStyle: MuType.body.copyWith(color: c.textSecondary),
                              ),
                            ),
                          ),
                        ),
                        MuButton.primary(label: l10n.ajouter, size: MuButtonSize.s, onPressed: _addLink),
                        MuIconButton(
                          icon: PhosphorIcons.x(),
                          label: l10n.fermer,
                          size: MuIconButtonSize.s,
                          onPressed: () => setState(() => _linkOpen = false),
                        ),
                      ],
                    ),
                  ),
                ),
              Shortcuts(
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.keyB, control: true): _BoldIntent(),
                  SingleActivator(LogicalKeyboardKey.keyI, control: true): _ItalicIntent(),
                },
                child: Actions(
                  actions: {
                    _BoldIntent: CallbackAction<_BoldIntent>(onInvoke: (_) => _apply(MuRichTool.bold)),
                    _ItalicIntent: CallbackAction<_ItalicIntent>(onInvoke: (_) => _apply(MuRichTool.italic)),
                  },
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    enabled: widget.enabled,
                    minLines: widget.minLines,
                    maxLines: widget.maxLines,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: MuType.bodyL.copyWith(color: c.text),
                    onChanged: widget.onChanged,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, MuSpace.s4),
                      hintText: widget.placeholder ?? l10n.forumEditeurPlaceholder,
                      hintStyle: MuType.bodyL.copyWith(color: c.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MuSpace.s1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: error != null
                  ? MuFieldMessage.error(error)
                  : widget.helper != null
                  ? MuFieldMessage.helper(widget.helper!)
                  : const SizedBox.shrink(),
            ),
            if (widget.maxLength != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: MuSpace.s2),
                child: Text(
                  '${formatInt(length)}/${formatInt(widget.maxLength!)}',
                  style: MuType.caption.copyWith(color: over ? c.errorText : c.textSecondary),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BoldIntent extends Intent {
  const _BoldIntent();
}

class _ItalicIntent extends Intent {
  const _ItalicIntent();
}
