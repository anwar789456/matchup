import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../../home/controllers/home_providers.dart';
import '../data/wallet_repository.dart';
import '../../../l10n/l10n.dart';

enum _Filter { all, payments, refunds, topups }

/// WAL-01 · Portefeuille: the balance card and « Recharger », the refund request in review,
/// « Demander un remboursement », then the filterable history grouped by date.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final balance = ref.watch(meProvider).value?.balance ?? 0;
    final history = ref.watch(walletHistoryProvider);
    final refunds = ref.watch(refundRequestsProvider).value ?? const <RefundRequest>[];
    final now = ref.read(clockProvider)();
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inverse = dark ? c.text : c.textInverse;

    final items = [
      for (final t in history.value ?? const <MuTransaction>[])
        if (switch (_filter) {
          _Filter.all => true,
          _Filter.payments => t.kind == MuTransactionKind.booking,
          _Filter.refunds => t.kind == MuTransactionKind.refund || t.status == MuTransactionStatus.refunded,
          _Filter.topups => t.kind == MuTransactionKind.topup,
        })
          t,
    ];
    String group(DateTime d) {
      if (d.year == now.year && d.month == now.month && d.day == now.day) return l10n.aujourdHui2;
      return '${_month(d.month)} ${d.year}';
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.portefeuille,
            backLabel: l10n.retourAuMenuDuCompte,
            onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s8),
              children: [
                Semantics(
                  label: l10n.soldeMatchup3(formatDT(balance)),
                  child: Container(
                    padding: const EdgeInsets.all(MuSpace.s5),
                    decoration: BoxDecoration(
                      color: dark ? c.night700 : c.surfaceInverse,
                      borderRadius: MuRadius.lgAll,
                      border: dark ? Border.all(color: c.border) : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(PhosphorIcons.wallet(), size: MuSize.iconXs, color: inverse.withValues(alpha: 0.7)),
                            const SizedBox(width: MuSpace.s1),
                            Text(l10n.soldeMatchup4, style: MuType.overline.copyWith(color: inverse.withValues(alpha: 0.7))),
                          ],
                        ),
                        const SizedBox(height: MuSpace.s2),
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(text: formatAmount(balance), style: MuType.numHero.copyWith(color: inverse)),
                            TextSpan(text: ' DT', style: MuType.numL.copyWith(color: inverse)),
                          ]),
                        ),
                        Text(l10n.paieTesPartsEnUn, style: MuType.caption.copyWith(color: inverse.withValues(alpha: 0.7))),
                        const SizedBox(height: MuSpace.s4),
                        MuNightTheme(
                        child: Builder(
                            builder: (context) => MuButton.primary(
                              label: l10n.recharger,
                              leading: PhosphorIcons.plus(),
                              size: MuButtonSize.l,
                              fullWidth: true,
                              onPressed: () => this.context.push(Routes.walletTopUp),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MuSpace.s4),
                MuSettingsGroup(
                  children: [
                    for (final r in refunds.where((r) => r.stage != RefundStage.refunded))
                      MuSettingsRow(
                        icon: PhosphorIcons.arrowUUpLeft(),
                        title: l10n.remboursementDemande(formatDT(r.amount)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MuStatusBadge(status: MuStatus.pending, label: l10n.enCoursDExamen, size: MuBadgeSize.s),
                            const SizedBox(width: MuSpace.s2),
                            Text(r.transaction.label.split(' · ').last, style: caption),
                            const SizedBox(width: MuSpace.s2),
                            Icon(PhosphorIcons.caretRight(), size: MuSize.iconXs, color: c.textSecondary),
                          ],
                        ),
                        onTap: () => context.push(Routes.walletRefundStatus(r.id)),
                      ),
                    MuSettingsRow(
                      icon: PhosphorIcons.receipt(),
                      title: l10n.demanderUnRemboursement,
                      description: l10n.terrainFermeMatchAnnule,
                      onTap: () => context.push(Routes.walletRefund),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s6),
                Semantics(header: true, child: Text(l10n.historique, style: MuType.h2.copyWith(color: c.text))),
                const SizedBox(height: MuSpace.s1),
                Text(l10n.lesPaiementsParCarteSont, style: caption),
                const SizedBox(height: MuSpace.s3),
                Semantics(
                  label: l10n.filtrerLHistorique,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final (f, label) in [
                          (_Filter.all, l10n.tout),
                          (_Filter.payments, l10n.paiements),
                          (_Filter.refunds, l10n.remboursements),
                          (_Filter.topups, l10n.recharges),
                        ]) ...[
                          MuChip(label: label, kind: MuChipKind.choice, size: MuChipSize.s, selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
                          const SizedBox(width: MuSpace.s2),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MuSpace.s4),
                if (history.value == null)
                  const MuTransactionList(children: [MuTransactionRow.loading(), MuTransactionRow.loading()])
                else if (items.isEmpty)
                  MuEmptyState(compact: true, title: l10n.rienDansCetteCategorie)
                else
                  for (final (i, t) in items.indexed) ...[
                    if (i == 0 || group(items[i - 1].date) != group(t.date)) ...[
                      if (i > 0) const SizedBox(height: MuSpace.s5),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: MuSpace.s1, bottom: MuSpace.s2),
                        child: Text(group(t.date).toUpperCase(), style: MuType.overline.copyWith(color: c.textSecondary)),
                      ),
                      MuTransactionList(
                        children: [
                          for (final x in items.where((x) => group(x.date) == group(t.date)))
                            MuTransactionRow(tx: x, onTap: () => showComingSoon(context)),
                        ],
                      ),
                    ],
                  ],
                const SizedBox(height: MuSpace.s5),
                Center(child: Text(l10n.cEstToutTonHistorique, style: caption)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _month(int m) => [l10n.janvier, l10n.fevrier2, l10n.mars2, l10n.avril, l10n.mai, l10n.juin, l10n.juillet, l10n.aout2, l10n.septembre, l10n.octobre, l10n.novembre, l10n.decembre2][m - 1];
}
