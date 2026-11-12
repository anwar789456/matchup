import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/theme.dart';

/// Renders a forum text (light Markdown) on the type scale (RichTextEditor.md « Content »):
/// paragraphs and lists in [style], blocks `space-3` apart, list markers `text-secondary`,
/// quotes indented with a 3 px `border-strong` rule in `text-secondary`, links underlined in
/// `link`, `@mentions` in `link`, **bold** in the semibold weight.
class ForumMarkdown extends StatefulWidget {
  const ForumMarkdown(this.text, {super.key, this.style, this.highlights = const []});

  final String text;
  final TextStyle? style;

  /// Ranges of [text] to mark (FRM-03): (start, end).
  final List<(int, int)> highlights;

  @override
  State<ForumMarkdown> createState() => _ForumMarkdownState();
}

class _ForumMarkdownState extends State<ForumMarkdown> {
  final _taps = <TapGestureRecognizer>[];

  static final _inline = RegExp(
    r'\*\*(.+?)\*\*|(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)|\[([^\]]+)\]\(([^)]+)\)|(?<![\w@])@[a-zA-Z0-9][a-zA-Z0-9._]{1,38}[a-zA-Z0-9]',
  );

  // RichTextEditor.md: quote rule 3 px.
  static const double _quoteRule = 3;

  @override
  void dispose() {
    for (final t in _taps) {
      t.dispose();
    }
    super.dispose();
  }

  List<InlineSpan> _spans(String s, TextStyle style, MuColors c) {
    final out = <InlineSpan>[];
    var at = 0;
    for (final m in _inline.allMatches(s)) {
      if (m.start > at) out.add(TextSpan(text: s.substring(at, m.start)));
      if (m[1] != null) {
        out.add(
          TextSpan(
            text: m[1],
            style: MuType.labelL.copyWith(fontSize: style.fontSize, height: style.height, color: style.color),
          ),
        );
      } else if (m[2] != null) {
        out.add(
          TextSpan(
            text: m[2],
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else if (m[3] != null) {
        final url = Uri.tryParse(m[4]!);
        final tap = TapGestureRecognizer()..onTap = url == null ? null : () => launchUrl(url, mode: LaunchMode.externalApplication);
        _taps.add(tap);
        out.add(
          TextSpan(
            text: m[3],
            style: TextStyle(color: c.link, decoration: TextDecoration.underline, decorationColor: c.link),
            recognizer: tap,
          ),
        );
      } else {
        out.add(
          TextSpan(
            text: m[0],
            style: TextStyle(color: c.link),
          ),
        );
      }
      at = m.end;
    }
    if (at < s.length) out.add(TextSpan(text: s.substring(at)));
    return out;
  }

  /// Plain spans with [widget.highlights] marked in `warning-soft` with a `warning` underline.
  List<InlineSpan> _highlighted(String s, MuColors c) {
    final marks = [...widget.highlights]..sort((a, b) => a.$1.compareTo(b.$1));
    final out = <InlineSpan>[];
    var at = 0;
    for (final (start, end) in marks) {
      if (start < at || end > s.length) continue;
      if (start > at) out.add(TextSpan(text: s.substring(at, start)));
      out.add(
        TextSpan(
          text: s.substring(start, end),
          style: TextStyle(backgroundColor: c.warningSoft, decoration: TextDecoration.underline, decorationColor: c.warning),
        ),
      );
      at = end;
    }
    if (at < s.length) out.add(TextSpan(text: s.substring(at)));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
    final c = context.mu;
    final style = (widget.style ?? MuType.bodyL).copyWith(color: (widget.style ?? MuType.bodyL).color ?? c.text);

    // Highlighted text (FRM-03 preview) stays one plain paragraph so the ranges match.
    if (widget.highlights.isNotEmpty) {
      return Text.rich(TextSpan(style: style, children: _highlighted(widget.text, c)));
    }

    final blocks = <Widget>[];
    final lines = widget.text.trim().split('\n');
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        i++;
        continue;
      }
      final bullet = RegExp(r'^\s*[-*] (.*)$').firstMatch(line);
      final number = RegExp(r'^\s*(\d+)\. (.*)$').firstMatch(line);
      if (bullet != null || number != null) {
        final items = <(String, String)>[];
        while (i < lines.length) {
          final b = RegExp(r'^\s*[-*] (.*)$').firstMatch(lines[i]);
          final n = RegExp(r'^\s*(\d+)\. (.*)$').firstMatch(lines[i]);
          if (b == null && n == null) break;
          items.add(b != null ? ('•', b[1]!) : ('${n![1]}.', n[2]!));
          i++;
        }
        blocks.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (marker, text) in items)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: MuSpace.s2, bottom: MuSpace.s1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: MuSpace.s5,
                        child: Text(marker, style: style.copyWith(color: c.textSecondary)),
                      ),
                      Expanded(
                        child: Text.rich(TextSpan(style: style, children: _spans(text, style, c))),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
        continue;
      }
      if (line.startsWith('> ')) {
        final quote = <String>[];
        while (i < lines.length && lines[i].startsWith('> ')) {
          quote.add(lines[i].substring(2));
          i++;
        }
        final q = style.copyWith(color: c.textSecondary);
        blocks.add(
          Container(
            padding: const EdgeInsetsDirectional.only(start: MuSpace.s4),
            decoration: BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(color: c.borderStrong, width: _quoteRule),
              ),
            ),
            child: Text.rich(TextSpan(style: q, children: _spans(quote.join('\n'), q, c))),
          ),
        );
        continue;
      }
      // A paragraph: consecutive non-empty lines.
      final para = <String>[];
      while (i < lines.length && lines[i].trim().isNotEmpty && !RegExp(r'^\s*([-*]|\d+\.) |^> ').hasMatch(lines[i])) {
        para.add(lines[i]);
        i++;
      }
      blocks.add(Text.rich(TextSpan(style: style, children: _spans(para.join('\n'), style, c))));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (k, b) in blocks.indexed) ...[if (k > 0) const SizedBox(height: MuSpace.s3), b],
      ],
    );
  }
}
