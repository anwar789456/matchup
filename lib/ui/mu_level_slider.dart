import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_button.dart';
import 'mu_level_indicator.dart' show muLevelBands;
import 'src/interaction.dart';
import '../l10n/l10n.dart';

/// LevelSlider (components/LevelSlider.md): one level on the 1,0–7,0 scale, step 0,5, with a
/// big readout, the four bands, and — after the AI questionnaire — the « IA » estimate as a marker
/// above the track with « Revenir à 3,5 ».
class MuLevelSlider extends StatefulWidget {
  MuLevelSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.aiEstimate,
    String? aiNote,
    this.readout = true,
  }) : aiNote = aiNote ?? l10n.dApresTesReponses;

  final double value;
  final ValueChanged<double>? onChanged;
  final String label;
  final double? aiEstimate;

  /// Why the estimate (« d’après tes réponses »).
  final String aiNote;
  final bool readout;

  static const double min = 1;
  static const double max = 7;
  static const double step = 0.5;

  @override
  State<MuLevelSlider> createState() => _MuLevelSliderState();
}

class _MuLevelSliderState extends State<MuLevelSlider> {
  bool _dragging = false;

  // LevelSlider.md: track 6 with 3 px gaps between bands; thumb 28 with a 2 px edge; AI marker
  // 22 high with a 1,5 px stem.
  static const double _track = 6;
  static const double _bandGap = 3;
  static const double _thumb = 28;
  static const double _thumbEdge = 2;
  static const double _marker = 22;
  static const double _stem = 1.5;
  static const double _sparkle = 14;

  bool get _enabled => widget.onChanged != null;

  double _snap(double v) =>
      (v / MuLevelSlider.step).round() * MuLevelSlider.step;

  void _set(double v) {
    final next = _snap(v.clamp(MuLevelSlider.min, MuLevelSlider.max));
    if (next != widget.value) widget.onChanged?.call(next);
  }

  void _fromDx(double dx, double width) {
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final f = (dx / width).clamp(0.0, 1.0);
    _set(MuLevelSlider.min + (ltr ? f : 1 - f) * (MuLevelSlider.max - MuLevelSlider.min));
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final k = e.logicalKey;
    double? next;
    if (k == LogicalKeyboardKey.arrowRight) next = widget.value + (rtl ? -0.5 : 0.5);
    if (k == LogicalKeyboardKey.arrowLeft) next = widget.value + (rtl ? 0.5 : -0.5);
    if (k == LogicalKeyboardKey.arrowUp) next = widget.value + 0.5;
    if (k == LogicalKeyboardKey.arrowDown) next = widget.value - 0.5;
    if (k == LogicalKeyboardKey.pageUp) next = widget.value + 1.5;
    if (k == LogicalKeyboardKey.pageDown) next = widget.value - 1.5;
    if (k == LogicalKeyboardKey.home) next = MuLevelSlider.min;
    if (k == LogicalKeyboardKey.end) next = MuLevelSlider.max;
    if (next == null) return KeyEventResult.ignored;
    _set(next);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final v = widget.value;
    final band = levelBand(v);
    final ai = widget.aiEstimate;
    final ink = _enabled ? c.text : c.textDisabled;
    final fill = _enabled ? c.primary : c.textDisabled;
    final duration = MuMotion.durationOf(context, MuMotion.fast);

    double frac(double level) =>
        ((level - MuLevelSlider.min) / (MuLevelSlider.max - MuLevelSlider.min)).clamp(0.0, 1.0);

    final track = LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final bandW = (width - _bandGap * 3) / 4;

      // Fill of band i up to the value (each band spans 1,5 points).
      double bandFill(int i) => ((v - 1 - i * 1.5) / 1.5).clamp(0.0, 1.0);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (d) => _fromDx(d.localPosition.dx, width) : null,
        onHorizontalDragStart: _enabled ? (_) => setState(() => _dragging = true) : null,
        onHorizontalDragUpdate: _enabled ? (d) => _fromDx(d.localPosition.dx, width) : null,
        onHorizontalDragEnd: _enabled ? (_) => setState(() => _dragging = false) : null,
        child: SizedBox(
          height: (ai != null ? _marker + MuSpace.s2 : 0) + MuSize.touchTarget,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Track: one segment per band.
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: (MuSize.touchTarget - _track) / 2,
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: _bandGap),
                      SizedBox(
                        width: bandW,
                        child: ClipRRect(
                          borderRadius: MuRadius.fullAll,
                          child: Container(
                            height: _track,
                            color: c.border,
                            alignment: AlignmentDirectional.centerStart,
                            child: FractionallySizedBox(
                              widthFactor: bandFill(i),
                              heightFactor: 1,
                              child: ColoredBox(color: fill),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // AI estimate marker with its stem down to the track.
              if (ai != null)
                PositionedDirectional(
                  start: frac(ai) * width - _marker * 1.5,
                  top: 0,
                  width: _marker * 3,
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        Container(
                          height: _marker,
                          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
                          decoration: ShapeDecoration(
                            color: c.aiSoft,
                            shape: StadiumBorder(side: BorderSide(color: c.ai500)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                                  size: _sparkle, color: c.ai500),
                              const SizedBox(width: MuSpace.s1),
                              Text('IA ', style: MuType.labelS.copyWith(color: c.aiText)),
                              Text(formatLevel(ai), style: MuType.numXs.copyWith(color: c.aiText)),
                            ],
                          ),
                        ),
                        Container(
                          width: _stem,
                          height: MuSpace.s2 + (MuSize.touchTarget - _track) / 2,
                          color: c.ai500,
                        ),
                      ],
                    ),
                  ),
                ),
              // Thumb.
              PositionedDirectional(
                start: frac(v) * width - _thumb / 2,
                bottom: (MuSize.touchTarget - _thumb) / 2,
                child: MuFocusRing(
                  shape: BoxShape.circle,
                  borderRadius: MuRadius.fullAll,
                  child: Focus(
                    canRequestFocus: _enabled,
                    onKeyEvent: _onKey,
                    child: AnimatedContainer(
                      duration: duration,
                      width: _thumb,
                      height: _thumb,
                      decoration: BoxDecoration(
                        color: c.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _dragging ? c.primary : c.borderControl,
                          width: _thumbEdge,
                        ),
                        boxShadow: _dragging
                            ? MuElevation.of(context).level2
                            : MuElevation.of(context).level1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });

    return Semantics(
      slider: true,
      label: widget.label,
      value: '${formatLevel(v)} – $band',
      increasedValue: v < MuLevelSlider.max ? formatLevel(v + 0.5) : null,
      decreasedValue: v > MuLevelSlider.min ? formatLevel(v - 0.5) : null,
      onIncrease: _enabled ? () => _set(v + 0.5) : null,
      onDecrease: _enabled ? () => _set(v - 0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: widget.readout
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.label,
                          style: MuType.label.copyWith(color: c.textSecondary)),
                      const SizedBox(height: MuSpace.s1),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(formatLevel(v), style: MuType.numXl.copyWith(color: ink)),
                          ),
                          const SizedBox(width: MuSpace.s3),
                          Text(band, style: MuType.h3.copyWith(color: ink)),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(widget.label, style: MuType.label.copyWith(color: c.text)),
                      ),
                      Text('${formatLevel(v)} ', style: MuType.numM.copyWith(color: ink)),
                      Text(band, style: MuType.label.copyWith(color: ink)),
                    ],
                  ),
          ),
          const SizedBox(height: MuSpace.s2),
          ExcludeSemantics(child: track),
          const SizedBox(height: MuSpace.s1),
          ExcludeSemantics(
            child: Row(
              children: [
                for (final (i, name) in muLevelBands.indexed)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: name == band
                              ? MuType.labelS.copyWith(color: c.text)
                              : MuType.caption.copyWith(color: c.textSecondary),
                        ),
                        Text(
                          '${formatLevel(1 + i * 1.5).replaceAll(',0', '')}–'
                          '${formatLevel(2.5 + i * 1.5).replaceAll(',0', '')}',
                          style: MuType.numXs.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (ai != null) ...[
            const SizedBox(height: MuSpace.s2),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: MuSpace.s2,
              children: [
                Text(
                  l10n.estimeParLIa(formatLevel(ai), widget.aiNote),
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
                if (v != ai && _enabled)
                  MuButton.link(
                    label: l10n.revenirA(formatLevel(ai)),
                    inline: true,
                    linkStyle: MuType.labelS,
                    onPressed: () => widget.onChanged?.call(ai),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
