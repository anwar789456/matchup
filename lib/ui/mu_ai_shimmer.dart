import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../theme/theme.dart';
import 'src/card_surface.dart';

enum _Variant { lines, status, steps }

/// AiShimmer (components/AiShimmer.md): the AI at work — `ai-soft` shapes crossed by the
/// violet→blue sweep, a twinkling sparkle and named steps. Still frame when animations are off.
class MuAiShimmer extends StatefulWidget {
  /// A paragraph not written yet (12px bars).
  const MuAiShimmer.lines({super.key, this.count = 3, required this.label})
    : _variant = _Variant.lines,
      steps = const [],
      current = 0;

  /// An inline wait: the sparkle and what the AI is doing.
  const MuAiShimmer.status({super.key, required this.label})
    : _variant = _Variant.status,
      count = 0,
      steps = const [],
      current = 0;

  /// A multi-step job: header, one segment per step, the step list. [current] is the running
  /// step (0-based); `current == steps.length` is done (« C’est prêt »).
  const MuAiShimmer.steps({
    super.key,
    required this.label,
    required this.steps,
    required this.current,
  }) : _variant = _Variant.steps,
       count = 0;

  final _Variant _variant;
  final String label;
  final int count;
  final List<String> steps;
  final int current;

  @override
  State<MuAiShimmer> createState() => _MuAiShimmerState();
}

class _MuAiShimmerState extends State<MuAiShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: MuMotion.shimmer,
  );

  // AiShimmer.md: bars 12 high, 10 apart; widths 100 / 94 / 97 / 88 %, the last 58 %.
  static const double _bar = 12;
  static const double _barGap = 10;
  static const _widths = [1.0, 0.94, 0.97, 0.88];
  static const double _lastWidth = 0.58;
  static const double _segment = 6;
  static const double _ring = 22;
  static const double _sparkle = 16;
  static const double _bandAlpha = 0.3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  /// The sweep: `ai-soft` with a band of the AI gradient sliding start → end.
  Widget _swept(Widget shapes) {
    final c = context.mu;
    final still = MediaQuery.disableAnimationsOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedBuilder(
      animation: _sweep,
      builder: (context, child) {
        final t = still ? 0.5 : _sweep.value;
        final shift = (rtl ? 1 - t : t) * 3 - 1.5;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(shift - 1, 0),
            end: Alignment(shift + 1, 0),
            colors: [
              c.aiSoft,
              c.aiGradientFrom.withValues(alpha: _bandAlpha),
              c.aiGradientTo.withValues(alpha: _bandAlpha),
              c.aiSoft,
            ],
            stops: const [0, 0.4, 0.6, 1],
          ).createShader(rect),
          child: child,
        );
      },
      child: shapes,
    );
  }

  Widget _sparkleIcon() {
    final c = context.mu;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) =>
          LinearGradient(colors: [c.aiGradientFrom, c.aiGradientTo])
              .createShader(rect),
      child: Icon(
        PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
        size: _sparkle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => switch (widget._variant) {
    _Variant.lines => _lines(),
    _Variant.status => _status(),
    _Variant.steps => _steps(),
  };

  Widget _lines() {
    final c = context.mu;
    final n = widget.count < 1 ? 1 : widget.count;
    return Semantics(
      liveRegion: true,
      label: widget.label,
      child: _swept(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) const SizedBox(height: _barGap),
              FractionallySizedBox(
                widthFactor: i == n - 1 && n > 1
                    ? _lastWidth
                    : _widths[i % _widths.length],
                child: Container(
                  height: _bar,
                  decoration: BoxDecoration(
                    color: c.aiSoft,
                    borderRadius: MuRadius.xsAll,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _status() {
    final c = context.mu;
    return Semantics(
      liveRegion: true,
      label: widget.label,
      excludeSemantics: true,
      child: Container(
        height: MuSize.controlS,
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3),
        decoration: ShapeDecoration(
          color: c.aiSoft,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sparkleIcon(),
            const SizedBox(width: MuSpace.s2),
            Text(widget.label, style: MuType.labelS.copyWith(color: c.aiText)),
          ],
        ),
      ),
    );
  }

  Widget _steps() {
    final c = context.mu;
    final steps = widget.steps;
    final current = widget.current.clamp(0, steps.length);
    final done = current >= steps.length;
    return MuCardSurface(
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                done
                    ? Icon(
                        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                        size: _sparkle,
                        color: c.aiText,
                      )
                    : _sparkleIcon(),
                const SizedBox(width: MuSpace.s2),
                Expanded(
                  child: Text(
                    done ? l10n.entAiReady : widget.label,
                    style: MuType.label.copyWith(color: c.text),
                  ),
                ),
                if (!done)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${l10n.entStep} '),
                        TextSpan(text: '${current + 1}', style: MuType.numXs),
                        TextSpan(text: ' ${l10n.entStepOutOf} '),
                        TextSpan(text: '${steps.length}', style: MuType.numXs),
                      ],
                    ),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: MuSpace.s3),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < steps.length; i++) ...[
                    if (i > 0) const SizedBox(width: MuSpace.s1),
                    Expanded(
                      child: i == current
                          ? _swept(
                              Container(
                                height: _segment,
                                decoration: BoxDecoration(
                                  color: c.aiSoft,
                                  borderRadius: MuRadius.xsAll,
                                ),
                              ),
                            )
                          : Container(
                              height: _segment,
                              decoration: BoxDecoration(
                                borderRadius: MuRadius.xsAll,
                                color: i < current ? null : c.aiSoft,
                                gradient: i < current
                                    ? LinearGradient(
                                        colors: [
                                          c.aiGradientFrom,
                                          c.aiGradientTo,
                                        ],
                                      )
                                    : null,
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: MuSpace.s3),
            for (final (i, s) in steps.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: MuSpace.s1 + MuSpace.s1 / 2,
                ),
                child: Semantics(
                  label:
                      '$s, ${i < current
                          ? l10n.entStepDone
                          : i == current
                          ? l10n.entStepRunning
                          : l10n.entStepTodo}',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: _ring,
                        child: i < current
                            ? Icon(
                                PhosphorIcons.checkCircle(
                                  PhosphorIconsStyle.fill,
                                ),
                                size: _ring - MuSpace.s1,
                                color: c.aiText,
                              )
                            : i == current
                            ? DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: c.ai500),
                                ),
                                child: Center(child: _sparkleIcon()),
                              )
                            : Icon(
                                PhosphorIcons.circleDashed(),
                                size: _ring - MuSpace.s1,
                                color: c.textSecondary,
                              ),
                      ),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: Text(
                          i == current ? '$s…' : s,
                          style: i == current
                              ? MuType.label.copyWith(color: c.aiText)
                              : MuType.body.copyWith(
                                  color: i < current ? c.text : c.textSecondary,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
