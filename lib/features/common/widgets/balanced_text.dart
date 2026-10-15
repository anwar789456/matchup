import 'package:flutter/material.dart';

/// Text whose lines are balanced like CSS `text-wrap: balance` (used by the designs' centred
/// titles): the narrowest width that keeps the same number of lines.
class BalancedText extends StatefulWidget {
  const BalancedText(this.text, {super.key, required this.style, this.textAlign});

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  State<BalancedText> createState() => _BalancedTextState();
}

class _BalancedTextState extends State<BalancedText> {
  @override
  void initState() {
    super.initState();
    // Re-measure once the fonts have loaded (google_fonts loads them asynchronously).
    PaintingBinding.instance.systemFonts.addListener(_fontsChanged);
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_fontsChanged);
    super.dispose();
  }

  void _fontsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(widget.text, style: widget.style, textAlign: widget.textAlign);
    return LayoutBuilder(builder: (context, constraints) {
      final max = constraints.maxWidth;
      if (!max.isFinite) return text;
      final painter = TextPainter(
        text: TextSpan(
          text: widget.text,
          style: DefaultTextStyle.of(context).style.merge(widget.style),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      );
      int linesAt(double width) {
        painter.layout(maxWidth: width);
        return painter.computeLineMetrics().length;
      }

      final lines = linesAt(max);
      var width = max;
      if (lines > 1) {
        var lo = 0.0;
        var hi = max;
        // Binary search to a pixel.
        while (hi - lo > 1) {
          final mid = (lo + hi) / 2;
          if (linesAt(mid) > lines) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        width = hi;
      }
      painter.dispose();
      return Center(
        widthFactor: 1,
        child: SizedBox(width: width.ceilToDouble(), child: text),
      );
    });
  }
}
