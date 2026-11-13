import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../data/coach_story.dart';
import '../widgets/coach_shell.dart';
import '../widgets/coach_widgets.dart';

enum _Period { month, sixMonths, year }

/// COA-12 · Revenus: net earnings after commission (this month, 6 months, the year), the next
/// payout, the 6-month chart, this month by source, the latest operations and the settings.
class CoachEarningsScreen extends ConsumerStatefulWidget {
  const CoachEarningsScreen({super.key});

  @override
  ConsumerState<CoachEarningsScreen> createState() => _CoachEarningsScreenState();
}

class _CoachEarningsScreenState extends ConsumerState<CoachEarningsScreen> {
  _Period _period = _Period.month;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final now = ref.watch(clockProvider)();
    const monthly = CoachStory.monthlyNet;
    final net = switch (_period) {
      _Period.month => monthly.last,
      _Period.sixMonths => monthly.skip(monthly.length - 6).fold<num>(0, (a, b) => a + b),
      _Period.year => monthly.fold<num>(0, (a, b) => a + b),
    };
    final gross = (net / (1 - CoachStory.commission)).round();
    final fee = gross - net;
    final upTo = l10n.coaUpTo(formatDay(now));
    final heading = switch (_period) {
      _Period.month => '${formatMonthLong(now)} · $upTo',
      _Period.sixMonths => l10n.coaLastSixMonths,
      _Period.year => '${now.year} · $upTo',
    };
    final months = [
      for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i),
    ];

    Widget line(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: (strong ? MuType.label : MuType.body).copyWith(
                color: strong ? c.text : c.textSecondary,
              ),
            ),
          ),
          Text(value, style: (strong ? MuType.numM : MuType.numS).copyWith(color: c.text)),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        padding: const EdgeInsets.only(bottom: MuSpace.s8),
        children: [
          CoachHeader(title: l10n.coaTabEarnings),
          Padding(
            padding: const EdgeInsets.all(MuSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MuSegmentedControl<_Period>(
                  semanticLabel: l10n.coaPeriod,
                  expand: true,
                  value: _period,
                  onChanged: (v) => setState(() => _period = v),
                  segments: [
                    MuSegment(value: _Period.month, label: l10n.coaThisMonth),
                    MuSegment(value: _Period.sixMonths, label: l10n.coaSixMonths),
                    MuSegment(value: _Period.year, label: '${now.year}'),
                  ],
                ),
                const SizedBox(height: MuSpace.s4),
                MuCardSurface(
                  padding: const EdgeInsets.all(MuSpace.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          heading.toUpperCase(),
                          style: MuType.overline.copyWith(color: c.textSecondary),
                        ),
                      ),
                      const SizedBox(height: MuSpace.s2),
                      MoneyHero(amount: net, style: MuType.numHero),
                      if (_period == _Period.month) ...[
                        const SizedBox(height: MuSpace.s1),
                        DeltaLine(
                          percent: CoachStory.revenueDelta,
                          period: l10n.coaVsLastMonthNet(formatMonth(DateTime(now.year, now.month - 1))),
                        ),
                      ],
                      const SizedBox(height: MuSpace.s4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3),
                        decoration: BoxDecoration(
                          color: c.surfaceMuted,
                          borderRadius: MuRadius.smAll,
                        ),
                        child: Column(
                          children: [
                            line(l10n.coaSalesAndPremium, formatDT(gross)),
                            Divider(height: 1, thickness: 1, color: c.border),
                            line(
                              l10n.coaCommission((CoachStory.commission * 100).round()),
                              '−${formatDT(fee)}',
                            ),
                            Divider(height: 1, thickness: 1, color: c.border),
                            line(l10n.coaYourNet, formatDT(net), strong: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s4),
                MuCardSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: MuSize.controlM,
                            height: MuSize.controlM,
                            decoration: BoxDecoration(color: c.accent, borderRadius: MuRadius.smAll),
                            alignment: Alignment.center,
                            child: Icon(PhosphorIcons.bank(), size: MuSize.iconS, color: c.onAccent),
                          ),
                          const SizedBox(width: MuSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.coaNextPayout, style: MuType.label.copyWith(color: c.text)),
                                Text(
                                  '${formatDay(CoachStory.nextPayoutDate)} · ${CoachStory.bank}',
                                  style: MuType.caption.copyWith(color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          MoneyHero(amount: CoachStory.nextPayout, style: MuType.numL),
                        ],
                      ),
                      const SizedBox(height: MuSpace.s3),
                      Divider(height: 1, thickness: 1, color: c.border),
                      const SizedBox(height: MuSpace.s3),
                      Row(
                        children: [
                          Icon(PhosphorIcons.checkCircle(), size: MuSize.iconXs, color: c.successText),
                          const SizedBox(width: MuSpace.s2),
                          Expanded(
                            child: Text(
                              l10n.coaLastPayout(
                                formatDT(CoachStory.lastPayout),
                                formatDay(CoachStory.lastPayoutDate),
                                CoachStory.lastPayoutRef,
                              ),
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s4),
                MuBarChart(
                  title: l10n.coaNetSixMonths,
                  subtitle: l10n.coaNetSixMonthsDetail(formatMonthLong(now)),
                  categories: [for (final m in months) formatMonth(m)],
                  tooltipCategories: [for (final m in months) '${formatMonthLong(m)} ${m.year}'],
                  series: [
                    MuBarSeries(
                      label: l10n.coaNet,
                      data: [for (final v in monthly.skip(monthly.length - 6)) v.toDouble()],
                      color: c.chart1,
                    ),
                  ],
                  format: formatDT,
                  compact: (v) => v >= 1000 ? '${formatAmount((v / 1000).round())}k $dtUnit' : formatAmount(v),
                  categoryLabel: l10n.coaMonth,
                  height: 220,
                ),
                const SizedBox(height: MuSpace.s4),
                MuBarChart(
                  title: l10n.coaBySource(formatMonthLong(now)),
                  subtitle: l10n.coaBySourceDetail(formatDay(now)),
                  orientation: Axis.horizontal,
                  categories: [for (final s in CoachStory.sources) s.$1],
                  series: [
                    MuBarSeries(
                      label: l10n.coaNet,
                      data: [for (final s in CoachStory.sources) s.$2.toDouble()],
                      color: c.chart1,
                    ),
                  ],
                  format: formatDT,
                  categoryLabel: l10n.coaSource,
                  height: 160,
                ),
              ],
            ),
          ),
          CoachSection(
            title: l10n.coaLatestOperations,
            action: l10n.coaSeeAll,
            onAction: () => showComingSoon(context),
          ),
          const SizedBox(height: MuSpace.s3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: MuCardSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, o) in CoachStory.operations.indexed) ...[
                    if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
                    MuTransactionRow(
                      tx: MuTransaction(
                        id: 'op-$i',
                        kind: switch (o.$5) {
                          'premium' => MuTransactionKind.subscription,
                          'refund' => MuTransactionKind.refund,
                          _ => MuTransactionKind.booking,
                        },
                        sport: o.$5 == 'sale' ? MuSport.padel : null,
                        label: o.$1,
                        meta: o.$5 == 'premium' ? o.$2 : '${o.$2} · ${formatDateTime(o.$3)}',
                        amount: o.$4,
                        date: o.$3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s6, MuSpace.s4, 0),
            child: MuSettingsGroup(
              title: l10n.coaSettings.toUpperCase(),
              children: [
                MuSettingsRow(
                  icon: PhosphorIcons.bank(),
                  title: l10n.coaBankDetails,
                  description: l10n.coaBankDetailsLine(CoachStory.bank),
                  onTap: () => showComingSoon(context),
                ),
                MuSettingsRow(
                  icon: PhosphorIcons.crownSimple(),
                  title: l10n.coaCoachPlan,
                  description: l10n.coaCoachPlanLine(
                    formatDT(CoachStory.coachPlan),
                    formatDay(CoachStory.coachPlanRenewal),
                  ),
                  onTap: () => showComingSoon(context),
                ),
                MuSettingsRow(
                  icon: PhosphorIcons.receipt(),
                  title: l10n.coaStatements,
                  description: l10n.coaStatementsLine(CoachStory.lastStatement),
                  onTap: () => showComingSoon(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
