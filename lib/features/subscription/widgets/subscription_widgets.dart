import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/theme.dart';

/// The SUB-01 FAQ: question rows (56 high) that open their answer, caret turning.
class FaqAccordion extends StatefulWidget {
  const FaqAccordion({super.key, required this.items, this.initiallyOpen = 0});

  /// (question, answer).
  final List<(String, String)> items;
  final int? initiallyOpen;

  @override
  State<FaqAccordion> createState() => _FaqAccordionState();
}

class _FaqAccordionState extends State<FaqAccordion> {
  late final Set<int> _open = {?widget.initiallyOpen};

  // SUB-01: summary rows at least 56 high.
  static const double _row = 56;

  Widget answer(int i, String a) {
    final c = context.mu;
    return _open.contains(i)
        ? Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s4),
            child: SizedBox(
              width: double.infinity,
              child: Text(a, style: MuType.body.copyWith(color: c.textSecondary)),
            ),
          )
        : const SizedBox(width: double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final duration = MuMotion.durationOf(context, MuMotion.base);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: c.border),
        boxShadow: MuElevation.of(context).level1,
      ),
      child: Column(
        children: [
          for (final (i, (q, a)) in widget.items.indexed) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
            Semantics(
              button: true,
              expanded: _open.contains(i),
              child: InkWell(
                onTap: () => setState(() => _open.contains(i) ? _open.remove(i) : _open.add(i)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _row),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MuSpace.s4,
                      vertical: MuSpace.s3,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(q, style: MuType.label.copyWith(color: c.text)),
                        ),
                        const SizedBox(width: MuSpace.s3),
                        AnimatedRotation(
                          turns: _open.contains(i) ? 0.5 : 0,
                          duration: duration,
                          child: Icon(
                            PhosphorIcons.caretDown(),
                            size: MuSize.iconS,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // AnimatedSize asserts with a zero duration (reduced motion): show it straight then.
            if (duration == Duration.zero)
              answer(i, a)
            else
              AnimatedSize(
                duration: duration,
                alignment: AlignmentDirectional.topStart,
                child: answer(i, a),
              ),
          ],
        ],
      ),
    );
  }
}

/// A label/value line of the subscription cards (« Prochain prélèvement · 19 DT · ven. 30 oct. »).
class SubLine extends StatelessWidget {
  const SubLine(this.label, this.value, {super.key, this.inverse = false, this.strong = true});

  final String label;
  final String value;
  final bool inverse;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final ink = inverse ? c.textInverse : c.text;
    final soft = inverse ? c.textInverse.withValues(alpha: 0.7) : c.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: MuType.body.copyWith(color: soft)),
          ),
          const SizedBox(width: MuSpace.s3),
          Text(value, style: (strong ? MuType.label : MuType.body).copyWith(color: ink)),
        ],
      ),
    );
  }
}

/// An icon in a soft square, then a title and a caption (SUB-03 benefits, SUB-08 kept list).
class BenefitRow extends StatelessWidget {
  const BenefitRow({super.key, required this.icon, required this.title, this.text, this.trailing});

  final IconData icon;
  final String title;
  final String? text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: MuSize.controlS,
            height: MuSize.controlS,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
            child: Icon(icon, size: MuSize.iconS, color: c.text),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: MuSpace.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(title, style: MuType.label.copyWith(color: c.text)),
                    ?trailing,
                  ],
                ),
                if (text != null)
                  Text(text!, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A check-circle line (« Résiliable à tout moment … », SUB-08 « Jusque-là, tu gardes tout »).
class CheckLine extends StatelessWidget {
  const CheckLine({super.key, this.text, this.span, this.icon});

  final String? text;
  final InlineSpan? span;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
            size: MuSize.iconS,
            color: c.successText,
          ),
          const SizedBox(width: MuSpace.s2),
          Expanded(
            child: Text.rich(
              span ?? TextSpan(text: text),
              style: MuType.body.copyWith(color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}
