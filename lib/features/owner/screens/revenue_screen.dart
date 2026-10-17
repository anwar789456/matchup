import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/coming_soon.dart';
import '../data/revenue_repository.dart';
import '../../../l10n/l10n.dart';

/// OWN-25 Revenus: the next payout (dark emphasis card), the period, two KPIs, revenue per day,
/// the online / on-site split, the weekly payouts, the monthly statement and the payout account.
class OwnerRevenueScreen extends ConsumerStatefulWidget {
  const OwnerRevenueScreen({super.key});

  @override
  ConsumerState<OwnerRevenueScreen> createState() => _OwnerRevenueScreenState();
}

class _OwnerRevenueScreenState extends ConsumerState<OwnerRevenueScreen> {
  RevenuePeriod _period = RevenuePeriod.month;

  /// The figures on screen while another period loads (KpiCard « Refreshing »).
  OwnerRevenue? _shown;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final payouts = ref.watch(ownerPayoutsProvider).value;
    final revenue = ref.watch(ownerRevenueProvider(_period)).value ?? _shown;
    _shown = revenue;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.revenus,
            subtitle: l10n.espaceProprietaire2(Story.arenaFive.name),
            backLabel: l10n.retourAPlus,
            onBack: () => goBack(context, Routes.ownerMore),
            actions: [
              MuBarAction(
                icon: PhosphorIcons.downloadSimple(),
                label: l10n.exporterLesRevenus,
                onPressed: () => showComingSoon(context),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(
                MuSpace.s4,
                MuSpace.s2,
                MuSpace.s4,
                MuSpace.s8,
              ),
              children: [
                if (payouts == null)
                  const MuSkeleton(height: _nextSkeleton, radius: MuRadius.lgAll)
                else
                  _NextPayout(payouts: payouts),
                const SizedBox(height: MuSpace.s5),
                MuSegmentedControl<RevenuePeriod>(
                  semanticLabel: l10n.periode,
                  expand: true,
                  value: _period,
                  onChanged: (p) => setState(() => _period = p),
                  segments: [
                    MuSegment(value: RevenuePeriod.week, label: l10n.jours),
                    MuSegment(value: RevenuePeriod.month, label: l10n.jours2),
                    MuSegment(value: RevenuePeriod.year, label: l10n.mois),
                  ],
                ),
                const SizedBox(height: MuSpace.s5),
                if (revenue == null)
                  const MuSkeleton(height: _chartSkeleton, radius: MuRadius.mdAll)
                else ...[
                  _Kpis(revenue: revenue),
                  const SizedBox(height: MuSpace.s5),
                  _Chart(revenue: revenue),
                  const SizedBox(height: MuSpace.s5),
                  _Split(revenue: revenue),
                ],
                if (payouts != null) ...[
                  const SizedBox(height: MuSpace.s5),
                  _Payouts(payouts: payouts),
                  const SizedBox(height: MuSpace.s5),
                  _Card(
                    children: [
                      _LinkRow(
                        icon: PhosphorIcons.filePdf(),
                        title: l10n.telechargerLeReleveDOctobre,
                        subtitle: l10n.pdfPourTaComptabiliteTva,
                        trailing: PhosphorIcons.downloadSimple(),
                        onTap: () => showComingSoon(context),
                      ),
                      Divider(height: 1, thickness: 1, color: c.border),
                      _LinkRow(
                        icon: PhosphorIcons.bank(),
                        title: l10n.compteDeVersement,
                        subtitle:
                            '${payouts.holder} · ${payouts.bank} ${ltr('•••• ${payouts.last4}')}',
                        trailing: PhosphorIcons.caretRight(),
                        directional: true,
                        onTap: () => showComingSoon(context),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const double _nextSkeleton = 220;
  static const double _chartSkeleton = 420;
}

String _signed(int v) => v > 0 ? '+$v' : (v < 0 ? '−${-v}' : '0');

/// « 1,5k DT », « 500 DT », « 0 » — short enough for the chart's tick column.
String _compactDT(double v) {
  if (v == 0) return '0';
  if (v.abs() < 1000) return formatDT(v.round());
  final k = v / 1000;
  final text = k == k.roundToDouble()
      ? formatInt(k.round())
      : k.toStringAsFixed(1).replaceAll('.', ',');
  return '${text}k\u00a0$dtUnit';
}

/// The dark « Prochain versement · estimé » card (Night match emphasis card, CLAUDE.md
/// rule 13), with its two decorative rings.
class _NextPayout extends StatelessWidget {
  const _NextPayout({required this.payouts});

  final OwnerPayouts payouts;

  // OWN-25 source: rings 230 (end −90, top −60) and 110 (end −30, top 0), 1.5 px.
  static const double _bigRing = 230;
  static const double _smallRing = 110;
  static const double _bigRingEnd = -90;
  static const double _bigRingTop = -60;
  static const double _smallRingEnd = -30;
  static const double _ringStroke = 1.5;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? c.text : c.textInverse;
    final muted = ink.withValues(alpha: 0.72);
    final caption = MuType.caption.copyWith(color: muted);
    final next = payouts.next;
    final days = payouts.expectedDays;
    final expectedDays = days.length == 2
        ? '${formatWeekday(days[0])} ${days[0].day} et ${formatDay(days[1])}'
        : days.map(formatDay).join(', ');
    final collectedRange =
        l10n.duAu(payouts.collectedFrom.day, payouts.collectedTo.day, formatMonth(payouts.collectedTo));
    final date = formatDay(next.date);
    final account = '${payouts.bank} ${ltr('•••• ${payouts.last4}')}';

    Widget ring(double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ink.withValues(alpha: 0.12), width: _ringStroke),
      ),
    );

    Widget meta(String label, String value, String note) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: caption),
        const SizedBox(height: MuSpace.s1 / 2),
        Text(value, style: MuType.numM.copyWith(color: ink)),
        const SizedBox(height: MuSpace.s1 / 2),
        Text(note, style: caption),
      ],
    );

    return Semantics(
      container: true,
      label:
          l10n.prochainVersementEstimeSurDeja(formatDT(next.amount), date, account, formatDT(payouts.collected), collectedRange, formatDT(payouts.expected), expectedDays),
      excludeSemantics: true,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: dark ? c.night700 : c.surfaceInverse,
          borderRadius: MuRadius.lgAll,
          border: dark ? Border.all(color: c.border) : null,
          boxShadow: dark ? null : MuElevation.of(context).level2,
        ),
        child: Stack(
          children: [
            PositionedDirectional(end: _bigRingEnd, top: _bigRingTop, child: ring(_bigRing)),
            PositionedDirectional(end: _smallRingEnd, top: 0, child: ring(_smallRing)),
            Padding(
              padding: const EdgeInsets.all(MuSpace.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIcons.bank(), size: MuSize.iconXs, color: muted),
                      const SizedBox(width: MuSpace.s1 + MuSpace.s1 / 2),
                      Flexible(
                        child: Text(
                          'Prochain versement · estimé'.toUpperCase(),
                          style: MuType.overline.copyWith(color: muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MuSpace.s1),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formatAmount(next.amount),
                          style: MuType.numHero.copyWith(color: ink),
                        ),
                        TextSpan(
                          text: ' $dtUnit',
                          style: MuType.numL.copyWith(color: ink),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MuSpace.s1),
                  Text(
                    '${date[0].toUpperCase()}${date.substring(1)} sur $account',
                    style: MuType.body.copyWith(color: muted),
                  ),
                  const SizedBox(height: MuSpace.s4),
                  Divider(height: 1, thickness: 1, color: ink.withValues(alpha: 0.16)),
                  const SizedBox(height: MuSpace.s3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: meta(l10n.dejaEncaisse, formatDT(payouts.collected), collectedRange),
                      ),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: meta(
                          l10n.encoreAttendu,
                          '≈ ${formatDT(payouts.expected)}',
                          expectedDays,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.revenue});

  final OwnerRevenue revenue;

  @override
  Widget build(BuildContext context) {
    final r = revenue;
    final (span, before) = switch (r.period) {
      RevenuePeriod.week => ('7 j', l10n.vsJAvant),
      RevenuePeriod.month => ('30 j', l10n.vsJAvant2),
      RevenuePeriod.year => (l10n.mois, l10n.vsMoisAvant),
    };
    const pad = EdgeInsets.all(MuSpace.s4);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MuKpiCard(
              label: l10n.revenus2(span),
              value: formatAmount(r.total),
              unit: dtUnit,
              delta: r.revenueDelta.toDouble(),
              deltaText: '${_signed(r.revenueDelta)} %',
              period: before,
              padding: pad,
            ),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: MuKpiCard(
              label: l10n.reservations,
              value: formatInt(r.bookings),
              delta: r.bookingsDelta.toDouble(),
              deltaText: _signed(r.bookingsDelta),
              period: before,
              padding: pad,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.revenue});

  final OwnerRevenue revenue;

  // OWN-25 source: the chart is 220 high.
  static const double _height = 220;

  @override
  Widget build(BuildContext context) {
    final r = revenue;
    final monthly = r.period == RevenuePeriod.year;
    final n = r.dates.length;
    return MuLineChart(
      key: ValueKey(r.period),
      title: monthly ? l10n.revenusParMois : l10n.revenusParJour,
      subtitle: l10n.terrainsEnLigneEtSur(Story.arenaFive.name, dtUnit),
      x: [for (final d in r.dates) monthly ? formatMonth(d) : '${d.day} ${formatMonth(d)}'],
      tooltipX: [for (final d in r.dates) monthly ? '${formatMonth(d)} ${d.year}' : formatDay(d)],
      series: [MuSeries(label: l10n.revenus, data: r.values)],
      format: (v) => formatDT(v.round()),
      compact: _compactDT,
      height: _height,
      dateHeader: monthly ? l10n.mois2 : l10n.jour,
      xTicks: switch (r.period) {
        RevenuePeriod.week => [0, 3, n - 1],
        RevenuePeriod.month => [1, 15, n - 1],
        RevenuePeriod.year => [0, 4, 8, n - 1],
      },
    );
  }
}

/// « D’où viennent les 26 740 DT »: paid online vs taken at the desk.
class _Split extends StatelessWidget {
  const _Split({required this.revenue});

  final OwnerRevenue revenue;

  // OWN-25 source: 10 × 10 legend keys, radius 2.
  static const double _key = 10;
  static const double _keyRadius = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = revenue;
    final online = r.onlinePercent;
    final caption = MuType.caption.copyWith(color: c.textSecondary);

    Widget part(Widget key, String label, num amount, String note) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: MuSpace.s1 + MuSpace.s1 / 2,
          children: [
            key,
            Text(label, style: caption),
          ],
        ),
        const SizedBox(height: MuSpace.s1 / 2),
        Text(formatDT(amount), style: MuType.numM.copyWith(color: c.text)),
        const SizedBox(height: MuSpace.s1 / 2),
        Text(note, style: caption),
      ],
    );

    return MuCardSurface(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s5, vertical: MuSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.dOuViennentLes(formatDT(r.total)),
            style: MuType.label.copyWith(color: c.text),
          ),
          const SizedBox(height: MuSpace.s3),
          Semantics(
            label: l10n.payesEnLigne(online),
            excludeSemantics: true,
            child: MuProgressBar(
              value: r.online.toDouble(),
              max: r.total.toDouble(),
              size: MuProgressSize.l,
              showValue: false,
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The online column hugs its content; the on-site one takes the rest.
              SizedBox(
                child: part(
                  Container(
                    width: _key,
                    height: _key,
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(_keyRadius),
                    ),
                  ),
                  l10n.payeEnLigne(online),
                  r.online,
                  l10n.verseChaqueLundi,
                ),
              ),
              const SizedBox(width: MuSpace.s5),
              Expanded(
                child: part(
                  Container(
                    width: _key,
                    height: _key,
                    decoration: BoxDecoration(
                      color: c.surfaceMuted,
                      borderRadius: BorderRadius.circular(_keyRadius),
                      border: Border.all(color: c.borderStrong),
                    ),
                  ),
                  l10n.encaisseSurPlace(100 - online),
                  r.onSite,
                  l10n.noteALAccueil,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Payouts extends StatelessWidget {
  const _Payouts({required this.payouts});

  final OwnerPayouts payouts;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final next = payouts.next;
    final card = ltr('•••• ${payouts.last4}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(l10n.versements, style: MuType.h3.copyWith(color: c.text)),
              ),
            ),
            Text(l10n.chaqueLundi, style: MuType.caption.copyWith(color: c.textSecondary)),
          ],
        ),
        const SizedBox(height: MuSpace.s2),
        _Card(
          children: [
            MuTransactionRow(
              tx: MuTransaction(
                id: 'next',
                kind: MuTransactionKind.payout,
                label: l10n.prevu(formatDay(next.date)),
                meta: next.from == null || next.to == null
                    ? ''
                    : l10n.paiementsDuAu(next.from!.day, next.to!.day, formatMonth(next.to!)),
                amount: next.amount,
                date: next.date,
                status: MuTransactionStatus.pending,
              ),
            ),
            for (final p in payouts.history)
              MuTransactionRow(
                tx: MuTransaction(
                  id: p.ref!,
                  kind: MuTransactionKind.payout,
                  label: l10n.verse(formatDay(p.date)),
                  meta: '${ltr(p.ref!)} · $card',
                  amount: p.amount,
                  date: p.date,
                ),
                onTap: () => showComingSoon(context),
              ),
          ],
        ),
      ],
    );
  }
}

/// A `mu-card` that clips its rows.
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        boxShadow: MuElevation.of(context).level1,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.directional = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final IconData trailing;
  final VoidCallback onTap;

  /// The trailing icon mirrors in RTL (a caret, not the download arrow).
  final bool directional;

  // OWN-25 source (`rv-link__ico`): 40 circle.
  static const double _circle = 40;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            MuSpace.s4,
            MuSpace.s3,
            MuSpace.s3,
            MuSpace.s3,
          ),
          child: Row(
            children: [
              Container(
                width: _circle,
                height: _circle,
                decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
                child: Icon(icon, size: MuSize.iconS, color: c.text),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: MuType.label.copyWith(color: c.text)),
                    const SizedBox(height: MuSpace.s1 / 2),
                    Text(subtitle, style: MuType.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              directional
                  ? MuDirectionalIcon(trailing, size: MuSize.iconS, color: c.textSecondary)
                  : Icon(trailing, size: MuSize.iconS, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
