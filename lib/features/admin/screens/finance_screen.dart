import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../core/search.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_widgets.dart';
import '../../../l10n/l10n.dart';

/// ADM-06 · Finance: cashed and refunded this week, what to validate, 30 days of takings, where
/// the money comes from, and the searchable transactions.
class AdminFinanceScreen extends ConsumerStatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  ConsumerState<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends ConsumerState<AdminFinanceScreen> {
  AdminTxFilter _filter = AdminTxFilter.all;
  String _query = '';

  bool _keep(MuTransaction t) {
    final q = foldAccents(_query.trim());
    if (q.isNotEmpty && !foldAccents('${t.label} ${t.meta}').contains(q)) return false;
    return switch (_filter) {
      AdminTxFilter.all => true,
      AdminTxFilter.bookings => t.kind == MuTransactionKind.booking,
      AdminTxFilter.subscriptions => t.kind == MuTransactionKind.subscription,
      AdminTxFilter.refunds => t.kind == MuTransactionKind.refund,
      AdminTxFilter.payouts => t.kind == MuTransactionKind.payout,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final now = ref.read(clockProvider)();
    final f = ref.watch(adminFinanceProvider).value;
    final payouts = (ref.watch(adminPayoutsProvider).value ?? const <AdminPayout>[])
        .where((p) => !p.validated)
        .length;
    final refunds = (ref.watch(adminRefundsProvider).value ?? const <AdminRefund>[])
        .where((r) => !r.done)
        .length;
    final churn = (ref.watch(adminChurnProvider).value ?? const <ChurnRisk>[])
        .where((r) => !r.ignored)
        .toList();
    final days = [for (var i = 29; i >= 0; i--) DateTime(now.year, now.month, now.day - i)];
    final today = f?.today.where(_keep).toList() ?? const <MuTransaction>[];
    final week = f?.week.where(_keep).toList() ?? const <MuTransaction>[];
    final sourcesTotal = f?.sources.fold(0.0, (a, s) => a + s.$2) ?? 0;

    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AdminHeader(title: l10n.finance, subtitle: l10n.auToutesLesVilles(formatDateTime(now))),
          Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s1, MuSpace.s4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminKpiGrid(
                  children: [
                    MuKpiCard(
                      label: l10n.encaisseJours,
                      value: formatAmount(f?.cashed ?? 48600),
                      unit: dtUnit,
                      delta: f?.cashedDelta ?? 6,
                      deltaText: signedPercent(f?.cashedDelta ?? 6),
                      period: l10n.vsJoursAvant,
                    ),
                    MuKpiCard(
                      label: l10n.rembourseJours,
                      value: formatAmount(f?.refunded ?? 1140),
                      unit: dtUnit,
                      delta: f?.refundedDelta ?? -12,
                      deltaText: signedPercent(f?.refundedDelta ?? -12),
                      upIsGood: false,
                      period: l10n.vsJoursAvant,
                    ),
                  ],
                ),
                const SizedBox(height: adminSectionGap),
                AdminSectionHead(title: l10n.aValider),
                const SizedBox(height: MuSpace.s2),
                AdminList(
                  inset: AdminList.tileInset,
                  children: [
                    AdminRow(
                      leading: AdminIconTile(PhosphorIcons.bank()),
                      onTap: () => context.push(Routes.adminPayouts),
                      child: AdminTexts(
                        title: l10n.versementsEtRemboursements,
                        lines: [l10n.versementsRemboursements(payouts, refunds)],
                      ),
                    ),
                    AdminRow(
                      leading: AdminIconTile(
                        PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                        tone: AdminTileTone.ai,
                      ),
                      end: MuCounter(
                        value: churn.length,
                        tone: MuCounterTone.neutral,
                        semanticLabel: l10n.abonnesARisque(churn.length),
                      ),
                      onTap: () => context.push(Routes.adminChurn),
                      child: AdminTexts(
                        title: l10n.risqueDeChurn,
                        titleEnd: MuAiLabel(size: MuAiLabelSize.s),
                        lines: [
                          l10n.abonnesPremiumMois(churn.length, formatAmount(churn.length * 19), dtUnit),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: adminSectionGap),
                if (f == null)
                  const MuSkeleton(height: 240)
                else
                  MuLineChart(
                    title: l10n.encaissementsJours,
                    subtitle: l10n.enDuAu(dtUnit, formatDay(days.first), formatDay(days.last)),
                    x: [for (final d in days) '${d.day} ${formatMonth(d)}'],
                    tooltipX: [for (final d in days) formatDay(d)],
                    series: [MuSeries(label: l10n.encaisse, data: f.revenue)],
                    format: (v) => formatDT(v.round()),
                    compact: (v) => v == 0
                        ? '0'
                        : '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1).replaceAll('.', ',')} k $dtUnit',
                    xTicks: const [1, 15, 29],
                    height: 240,
                  ),
                const SizedBox(height: adminSectionGap),
                if (f != null)
                  MuDonutChart(
                    title: l10n.dOuVientLArgent,
                    subtitle: l10n.derniersJoursEncaisses(formatDT(sourcesTotal)),
                    data: [for (final s in f.sources) MuSlice(label: s.$1, value: s.$2)],
                    format: (v) => formatDT(v.round()),
                    centerFormat: (v) => formatAmount(v.round()),
                    total: formatAmount(sourcesTotal.round()),
                    totalLabel: l10n.encaisses(dtUnit),
                    thickness: 28,
                    categoryLabel: l10n.source,
                    valueLabel: l10n.montant,
                  ),
                const SizedBox(height: adminSectionGap),
                AdminSectionHead(
                  title: l10n.transactions,
                  end: MuButton.tertiary(
                    label: l10n.exporter,
                    leading: PhosphorIcons.downloadSimple(),
                    size: MuButtonSize.s,
                    onPressed: () => showComingSoon(context),
                  ),
                ),
                const SizedBox(height: MuSpace.s2),
                MuSearchField<String>(
                  label: l10n.rechercherUneTransaction,
                  placeholder: l10n.nomTerrainReferenceMu,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          Semantics(
            container: true,
            label: l10n.typeDeTransaction,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
              child: Row(
                children: [
                  for (final (k, label) in [
                    (AdminTxFilter.all, l10n.tout),
                    (AdminTxFilter.bookings, l10n.reservations),
                    (AdminTxFilter.subscriptions, l10n.abonnements),
                    (AdminTxFilter.refunds, l10n.remboursements),
                    (AdminTxFilter.payouts, l10n.versements),
                  ]) ...[
                    MuChip(
                      kind: MuChipKind.choice,
                      label: label,
                      selected: _filter == k,
                      onSelected: (_) => setState(() => _filter = k),
                    ),
                    const SizedBox(width: MuSpace.s2),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (f == null)
                  const MuTransactionList(
                    children: [MuTransactionRow.loading(), MuTransactionRow.loading()],
                  )
                else if (today.isEmpty && week.isEmpty)
                  MuEmptyState(compact: true, title: l10n.aucuneTransactionTrouvee)
                else ...[
                  for (final (title, list) in [(l10n.aujourdHui2, today), (l10n.cetteSemaine, week)])
                    if (list.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          MuSpace.s1,
                          MuSpace.s3,
                          MuSpace.s1,
                          MuSpace.s2,
                        ),
                        child: Semantics(
                          header: true,
                          child: Text(
                            title.toUpperCase(),
                            style: MuType.overline.copyWith(color: c.textSecondary),
                          ),
                        ),
                      ),
                      MuTransactionList(
                        children: [
                          for (final t in list)
                            MuTransactionRow(tx: t, onTap: () => showComingSoon(context)),
                        ],
                      ),
                    ],
                ],
                const SizedBox(height: MuSpace.s16 + MuSpace.s10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
