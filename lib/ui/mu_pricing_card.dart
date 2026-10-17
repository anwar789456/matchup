import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_button.dart';

enum MuBillingPeriod { month, year }

/// A plan shown by [MuPricingCard].
@immutable
class MuPlan {
  const MuPlan({
    required this.name,
    required this.audience,
    required this.pitch,
    required this.monthly,
    required this.yearly,
    required this.features,
    this.icon,
  });

  final String name;

  /// « Propriétaire ».
  final String audience;
  final IconData? icon;
  final String pitch;
  final num monthly;
  final num yearly;

  /// (label, included).
  final List<(String, bool)> features;
}

/// PricingCard (components/PricingCard.md): eyebrow, name, pitch, price for the [period], the CTA,
/// the trial note and the feature list. [recommended] adds the Volt « Populaire » badge, the 2 px
/// `primary` edge and `elevation-2`; [chosen] draws the selection ring 4 px outside the card and
/// turns the CTA into « Offre choisie ».
class MuPricingCard extends StatelessWidget {
  const MuPricingCard({
    super.key,
    required this.plan,
    required this.period,
    required this.onCta,
    this.recommended = false,
    this.chosen = false,
    this.trialDays = 14,
    this.savings,
    this.current = false,
    this.compact = false,
    this.cta,
    this.trialNote,
  });

  final MuPlan plan;
  final MuBillingPeriod period;
  final VoidCallback? onCta;
  final bool recommended;
  final bool chosen;
  final int trialDays;

  /// Yearly badge (« 2 mois offerts »).
  final String? savings;

  /// « Ton offre actuelle » in place of the button, no trial note.
  final bool current;

  /// A row for plan pickers: name + badges, pitch, amount over its unit.
  final bool compact;

  /// The button label (« Essayer 14 jours gratuits »); « Choisir [plan] » by default.
  final String? cta;

  /// Overrides the « 14 jours gratuits, puis … » note.
  final String? trialNote;

  // PricingCard.md: 2 px edge on the recommended plan, 2 px ring 4 px outside the chosen one;
  // feature icons 18; badges 2 px tall padding.
  static const double _edge = 2;
  static const double _ringGap = MuSpace.s1;
  static const double _featureIcon = 18;
  static const double _pillPadY = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final yearly = period == MuBillingPeriod.year;
    final amount = yearly ? plan.yearly : plan.monthly;
    final unit = yearly ? '/ an' : '/ mois';
    final after = yearly ? '${formatDT(plan.yearly)}/an' : '${formatDT(plan.monthly)}/mois';

    if (compact) return _compact(context, c, yearly, amount);
    final free = amount == 0;
    final cta = current
        ? _currentBlock(c)
        : chosen
        ? MuButton.primary(
            label: 'Offre choisie',
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: onCta,
          )
        : recommended
        ? MuButton.primary(
            label: this.cta ?? 'Choisir ${plan.name}',
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: onCta,
          )
        : MuButton.secondary(
            label: this.cta ?? 'Choisir ${plan.name}',
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: onCta,
          );
    final unitText = free ? 'pour toujours' : unit;

    return Semantics(
      container: true,
      selected: chosen,
      label: '${plan.name}, ${formatDT(amount)} $unit${recommended ? ', populaire' : ''}',
      child: Stack(
        // Passes a stretched height on to the card (two plans side by side stay level).
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            left: -_ringGap - _edge,
            top: -_ringGap - _edge,
            right: -_ringGap - _edge,
            bottom: -_ringGap - _edge,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: MuMotion.durationOf(context, MuMotion.fast),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(MuRadius.md + _ringGap + _edge),
                  border: Border.all(
                    color: chosen ? c.primary : c.primary.withValues(alpha: 0),
                    width: _edge,
                  ),
                ),
              ),
            ),
          ),
          _card(context, c, yearly, amount, unitText, after, cta),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    MuColors c,
    bool yearly,
    num amount,
    String unit,
    String after,
    Widget cta,
  ) {
    return AnimatedContainer(
      duration: MuMotion.durationOf(context, MuMotion.fast),
      padding: const EdgeInsets.all(MuSpace.s6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        border: recommended ? Border.all(color: c.primary, width: _edge) : null,
        boxShadow: recommended ? MuElevation.of(context).level2 : MuElevation.of(context).level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (plan.icon != null) ...[
                Icon(plan.icon, size: MuSize.iconXs, color: c.textSecondary),
                const SizedBox(width: MuSpace.s2),
              ],
              Expanded(
                child: Text(
                  plan.audience.toUpperCase(),
                  style: MuType.overline.copyWith(color: c.textSecondary),
                ),
              ),
              if (recommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: _pillPadY),
                  decoration: BoxDecoration(color: c.accent, borderRadius: MuRadius.fullAll),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.star(PhosphorIconsStyle.fill),
                        size: MuSize.iconXs,
                        color: c.onAccent,
                      ),
                      const SizedBox(width: MuSpace.s1),
                      Text('Populaire', style: MuType.labelS.copyWith(color: c.onAccent)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Text(plan.name, style: MuType.h3.copyWith(color: c.text)),
          const SizedBox(height: MuSpace.s1),
          Text(plan.pitch, style: MuType.body.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(formatDT(amount), style: MuType.numXl.copyWith(color: c.text)),
              const SizedBox(width: MuSpace.s2),
              Text(unit, style: MuType.body.copyWith(color: c.textSecondary)),
            ],
          ),
          if (yearly && savings != null) ...[
            const SizedBox(height: MuSpace.s1),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: _pillPadY),
                  decoration: BoxDecoration(color: c.successSoft, borderRadius: MuRadius.fullAll),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.gift(), size: MuSize.iconXs, color: c.successText),
                      const SizedBox(width: MuSpace.s1),
                      Text(savings!, style: MuType.labelS.copyWith(color: c.successText)),
                    ],
                  ),
                ),
                const SizedBox(width: MuSpace.s2),
                Text(
                  'soit ${formatDT((plan.yearly / 12 * 1000).round() / 1000)}/mois',
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ],
          const SizedBox(height: MuSpace.s5),
          cta,
          if (!current) ...[
            const SizedBox(height: MuSpace.s3),
            Text(
              trialNote ?? '$trialDays jours gratuits, puis $after · Résiliable à tout moment',
              textAlign: TextAlign.center,
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
          ],
          const SizedBox(height: MuSpace.s5),
          Container(height: 1, color: c.border),
          const SizedBox(height: MuSpace.s5),
          for (final (i, (label, included)) in plan.features.indexed) ...[
            if (i > 0) const SizedBox(height: MuSpace.s3),
            Semantics(
              label: included ? label : '$label, non inclus',
              excludeSemantics: true,
              child: Row(
                children: [
                  Icon(
                    included ? PhosphorIcons.check() : PhosphorIcons.x(),
                    size: _featureIcon,
                    color: included ? c.successText : c.textDisabled,
                  ),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: Text(
                      label,
                      style: MuType.body.copyWith(color: included ? c.text : c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _currentBlock(MuColors c) => Container(
    constraints: const BoxConstraints(minHeight: MuSize.controlL),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: c.surfaceMuted,
      borderRadius: MuRadius.smAll,
      border: Border.all(color: c.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
          size: MuSize.iconXs,
          color: c.successText,
        ),
        const SizedBox(width: MuSpace.s2),
        Text('Ton offre actuelle', style: MuType.label.copyWith(color: c.textSecondary)),
      ],
    ),
  );

  Widget _compact(BuildContext context, MuColors c, bool yearly, num amount) {
    final free = amount == 0;
    final unit = free ? 'pour toujours' : (yearly ? '/ an' : '/ mois');
    return Semantics(
      container: true,
      label: '${plan.name}, ${formatDT(amount)} $unit${current ? ', ton offre actuelle' : ''}',
      child: Container(
        padding: const EdgeInsets.all(MuSpace.s4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: MuRadius.mdAll,
          border: recommended ? Border.all(color: c.primary, width: _edge) : null,
          boxShadow: MuElevation.of(context).level1,
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: MuSpace.s2,
                      runSpacing: MuSpace.s1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(plan.name, style: MuType.labelL.copyWith(color: c.text)),
                        if (current)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: MuSpace.s2,
                              vertical: _pillPadY,
                            ),
                            decoration: BoxDecoration(
                              color: c.surfaceMuted,
                              borderRadius: MuRadius.fullAll,
                              border: Border.all(color: c.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                                  size: MuSize.iconXs,
                                  color: c.textSecondary,
                                ),
                                const SizedBox(width: MuSpace.s1),
                                Text(
                                  'Ton offre actuelle',
                                  style: MuType.labelS.copyWith(color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: MuSpace.s1),
                    Text(plan.pitch, style: MuType.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(formatDT(amount), style: MuType.numL.copyWith(color: c.text)),
                  ),
                  Text(unit, style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
