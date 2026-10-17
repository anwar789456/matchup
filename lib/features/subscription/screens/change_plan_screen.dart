import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/subscription_controller.dart';
import '../data/subscription_repository.dart';
import '../widgets/subscription_widgets.dart';
import '../../../l10n/l10n.dart';

/// SUB-05 · Changer d’offre: Mensuel or Annuel, the preview of what will be charged, then
/// « Passer à l’annuel » (or « Garder le mensuel » when nothing changes).
class ChangePlanScreen extends ConsumerStatefulWidget {
  const ChangePlanScreen({super.key});

  @override
  ConsumerState<ChangePlanScreen> createState() => _ChangePlanScreenState();
}

class _ChangePlanScreenState extends ConsumerState<ChangePlanScreen> {
  MuBillingPeriod? _plan;
  bool _busy = false;

  Future<void> _confirm(Subscription sub, MuBillingPeriod plan) async {
    if (plan == sub.period) {
      goBack(context, Routes.subscription);
      return;
    }
    setState(() => _busy = true);
    await ref.read(subscriptionProvider.notifier).changePeriod(plan);
    if (!mounted) return;
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: plan == MuBillingPeriod.year ? l10n.tuPassesALAnnuel : l10n.tuRestesAuMensuel,
      description: l10n.leChangementCompteAPartir(formatDay(sub.trialEnds)),
    );
    goBack(context, Routes.subscription);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final sub = ref.watch(subscriptionProvider).value;
    if (sub == null) return Scaffold(backgroundColor: c.bg);
    final plan = _plan ?? (sub.yearlyPlan ? MuBillingPeriod.month : MuBillingPeriod.year);
    final year = plan == MuBillingPeriod.year;
    final changes = plan != sub.period;
    final caption = MuType.caption.copyWith(color: c.textSecondary);

    Widget currentPill() => Container(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1 / 2),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: MuRadius.fullAll,
        border: Border.all(color: c.border),
      ),
      child: Text(l10n.tonOffreActuelle, style: MuType.labelS.copyWith(color: c.textSecondary)),
    );

    Widget savingPill() => Container(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1 / 2),
      decoration: BoxDecoration(color: c.successSoft, borderRadius: MuRadius.fullAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.gift(), size: MuSize.iconXs, color: c.successText),
          const SizedBox(width: MuSpace.s1),
          Text('−17 %', style: MuType.labelS.copyWith(color: c.successText)),
        ],
      ),
    );

    Widget line(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: MuType.body.copyWith(color: c.textSecondary)),
          ),
          value,
        ],
      ),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.changerDOffre,
            onBack: _busy ? null : () => goBack(context, Routes.subscription),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                FlowTitle(
                  l10n.mensuelOuAnnuel,
                  lead:
                      l10n.tonEssaiContinueJusquAu(formatDay(sub.trialEnds)),
                ),
                const SizedBox(height: MuSpace.s5),
                MuChoiceCard(
                  title: l10n.mensuelMois(formatDT(Subscription.monthly)),
                  description: l10n.sansEngagementResiliableChaqueMois,
                  leading: Icon(PhosphorIcons.calendarBlank(), size: MuSize.iconM, color: c.text),
                  selected: plan == MuBillingPeriod.month,
                  extra: sub.yearlyPlan ? null : currentPill(),
                  onTap: () => setState(() => _plan = MuBillingPeriod.month),
                ),
                const SizedBox(height: MuSpace.s3),
                MuChoiceCard(
                  title: l10n.annuelAn(formatDT(Subscription.yearly)),
                  description:
                      l10n.soitMoisMoisOfferts(formatDT((Subscription.yearly / 12 * 1000).round() / 1000)),
                  leading: Icon(PhosphorIcons.calendarCheck(), size: MuSize.iconM, color: c.text),
                  selected: year,
                  extra: sub.yearlyPlan ? currentPill() : savingPill(),
                  onTap: () => setState(() => _plan = MuBillingPeriod.year),
                ),
                const SizedBox(height: MuSpace.s6),
                Semantics(
                  header: true,
                  child: Text(
                    changes
                        ? (year
                              ? l10n.ceQueTuPaierasAvec
                              : l10n.ceQueTuPaierasAvec2)
                        : l10n.rienNeChange,
                    style: MuType.labelL.copyWith(color: c.text),
                  ),
                ),
                const SizedBox(height: MuSpace.s3),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: MuRadius.mdAll,
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      line(
                        l10n.aujourdHui2,
                        Text(formatDT(0), style: MuType.numS.copyWith(color: c.text)),
                      ),
                      Divider(height: 1, thickness: 1, color: c.border),
                      line(
                        l10n.le(formatDay(sub.trialEnds)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              formatDT(year ? Subscription.yearly : Subscription.monthly),
                              style: MuType.numS.copyWith(color: c.text),
                            ),
                            if (year) ...[
                              const SizedBox(width: MuSpace.s2),
                              Text(l10n.auLieuDe(formatDT(Subscription.monthly)), style: caption),
                            ],
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: c.border),
                      line(
                        l10n.ensuite,
                        Text(
                          year
                              ? l10n.chaqueOct(formatDT(Subscription.yearly))
                              : l10n.chaqueMoisLe(formatDT(Subscription.monthly)),
                          style: MuType.label.copyWith(color: c.text),
                        ),
                      ),
                      if (year)
                        Container(
                          color: c.successSoft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: MuSpace.s4,
                            vertical: MuSpace.s3,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.piggyBank(),
                                size: MuSize.iconS,
                                color: c.successText,
                              ),
                              const SizedBox(width: MuSpace.s2),
                              Expanded(
                                child: Text(
                                  l10n.tuEconomisesParAn(formatDT(Subscription.monthly * 12 - Subscription.yearly)),
                                  style: MuType.label.copyWith(color: c.successText),
                                ),
                              ),
                              Text(
                                l10n.vs2(formatDT(Subscription.monthly)),
                                style: MuType.caption.copyWith(color: c.successText),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s3),
                CheckLine(
                  icon: PhosphorIcons.info(),
                  text: year
                      ? l10n.surTaTuPeuxRevenir(sub.cardLabel)
                      : l10n.surTaTuPeuxPasser(sub.cardLabel),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          MuButton.primary(
            label: year
                ? (changes ? l10n.passerALAnnuel : l10n.garderLAnnuel)
                : (changes ? l10n.passerAuMensuel : l10n.garderLeMensuel),
            size: MuButtonSize.xl,
            fullWidth: true,
            loading: _busy,
            onPressed: _busy ? null : () => _confirm(sub, plan),
          ),
        ],
      ),
    );
  }
}
