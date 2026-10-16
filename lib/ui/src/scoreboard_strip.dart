import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../mu_skeleton.dart';

/// One cell of a [MuScoreboardStrip]: an `overline` label (with an optional icon), a value and a
/// `caption` line under it.
@immutable
class MuStripCell {
  const MuStripCell({required this.label, required this.value, this.sub, this.labelIcon});

  final String label;
  final Widget value;
  final Widget? sub;
  final IconData? labelIcon;
}

/// The scoreboard strip shared by the cards (GameCard.md « Scoreboard strip »): full bleed,
/// `surface-muted` band, `border` hairlines around and between cells; cell padding `space-3`
/// (`space-4` at the edges, `space-2` when the strip is ≤ 340); label `overline`
/// `text-secondary`, value `num-l` + unit `num-m`, sub `caption`.
class MuScoreboardStrip extends StatelessWidget {
  const MuScoreboardStrip({
    super.key,
    required this.cells,
    this.semanticLabel,
    this.loading = false,
  });

  final List<MuStripCell> cells;

  /// Read instead of the cells (« Heure 20h00, 2 libres sur 10, 15 DT par joueur »).
  final String? semanticLabel;

  /// Skeleton blocks in the same layout.
  final bool loading;

  static const double _narrow = 340;

  // Skeleton blocks: label, value and sub line widths (HOM-02).
  static const double _skelLabel = 48;
  static const double _skelValue = 64;
  static const double _skelSub = 56;

  /// « 15 » `num-l` + « DT » `num-m`, never mirrored.
  static Widget value(BuildContext context, String main, [String? unit, Color? color]) =>
      _value(context, main, unit, color, MuType.numL, MuType.numM);

  /// The smaller value of the booking strip: `num-m` + unit `num-s`.
  static Widget valueM(BuildContext context, String main, [String? unit, Color? color]) =>
      _value(context, main, unit, color, MuType.numM, MuType.numS);

  static Widget _value(
    BuildContext context,
    String main,
    String? unit,
    Color? color,
    TextStyle mainStyle,
    TextStyle unitStyle,
  ) {
    final c = context.mu;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: main, style: mainStyle),
            if (unit != null) TextSpan(text: ' $unit', style: unitStyle),
          ],
        ),
        style: TextStyle(color: color ?? c.text),
      ),
    );
  }

  /// A `caption` sub line in `text-secondary` (or [color]).
  static Widget sub(BuildContext context, String text, {Color? color, IconData? icon}) {
    final c = context.mu;
    final style = MuType.caption.copyWith(color: color ?? c.textSecondary);
    if (icon == null) return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: MuSize.iconXs, color: color ?? c.textSecondary),
        const SizedBox(width: MuSpace.s1),
        Flexible(
          child: Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final hairline = BorderSide(color: c.border);
    final captionLine = MuType.caption.fontSize! * MuType.caption.height!;
    final valueLine = MuType.numL.fontSize! * MuType.numL.height!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final edge = constraints.maxWidth <= _narrow ? MuSpace.s2 : MuSpace.s4;
        final inner = constraints.maxWidth <= _narrow ? MuSpace.s2 : MuSpace.s3;

        Widget cell(int i) {
          final cell = cells[i];
          final first = i == 0;
          final last = i == cells.length - 1;
          return Expanded(
            child: Container(
              padding: EdgeInsetsDirectional.fromSTEB(
                first ? edge : inner,
                MuSpace.s3,
                last ? edge : inner,
                MuSpace.s3,
              ),
              decoration: BoxDecoration(border: last ? null : BorderDirectional(end: hairline)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: loading
                    ? [
                        const MuSkeleton(width: _skelLabel, height: MuSkeleton.textHeight),
                        const SizedBox(height: MuSpace.s2),
                        MuSkeleton(width: _skelValue, height: valueLine - MuSpace.s1),
                        const SizedBox(height: MuSpace.s2),
                        const MuSkeleton(width: _skelSub, height: MuSkeleton.textHeight),
                      ]
                    : [
                        Row(
                          children: [
                            if (cell.labelIcon != null) ...[
                              Icon(cell.labelIcon, size: MuSize.iconXs, color: c.textSecondary),
                              const SizedBox(width: MuSpace.s1),
                            ],
                            Flexible(
                              child: Text(
                                cell.label.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MuType.overline.copyWith(color: c.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: MuSpace.s1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: cell.value,
                        ),
                        const SizedBox(height: MuSpace.s1),
                        // A fixed caption line, so the cells match without intrinsic sizing.
                        SizedBox(
                          height: captionLine,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: cell.sub ?? const SizedBox.shrink(),
                          ),
                        ),
                      ],
              ),
            ),
          );
        }

        final strip = DecoratedBox(
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            border: Border.symmetric(horizontal: hairline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (var i = 0; i < cells.length; i++) cell(i)],
          ),
        );
        if (semanticLabel == null || loading) return strip;
        return Semantics(label: semanticLabel, excludeSemantics: true, child: strip);
      },
    );
  }
}
