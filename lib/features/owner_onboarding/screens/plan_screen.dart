import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/pro_providers.dart';
import '../controllers/owner_controller.dart';
import '../data/owner_draft.dart';
import '../data/owner_repository.dart';
import '../widgets/owner_wizard.dart';
import '../../../l10n/l10n.dart';

/// The owner plans (OWN-08).
abstract final class OwnerPlans {
  static final starter = MuPlan(
    name: l10n.starter,
    audience: l10n.proprietaire,
    icon: PhosphorIcons.storefront(),
    pitch: l10n.tonTerrainReservableEnLigne,
    monthly: 79,
    yearly: 790,
    features: [
      (l10n.jusquATerrains, true),
      (l10n.calendrierEtReservationsEnLigne, true),
      (l10n.paiementEnLigneCommission, true),
      (l10n.statistiquesDOccupationEtDe, false),
      (l10n.tarifsHeuresCreusesPleines, false),
      (l10n.comptesGerants, false),
    ],
  );

  static final pro = MuPlan(
    name: l10n.pro,
    audience: l10n.proprietaire,
    icon: PhosphorIcons.storefront(),
    pitch: l10n.remplisTesCreneauxCreux,
    monthly: 149,
    yearly: 1490,
    features: [
      (l10n.terrainsIllimites, true),
      (l10n.statistiquesDOccupationEtDe, true),
      (l10n.tarifsHeuresCreusesPleines, true),
      (l10n.jusquAComptesGerants, true),
      (l10n.paiementEnLigneCommission2, true),
      (l10n.supportPrioritaire7j, true),
    ],
  );

  static MuPlan of(OwnerPlan p) => p == OwnerPlan.pro ? pro : starter;
}

/// OWN-08 — the plan: monthly or yearly, Starter or Pro, then the free trial starts.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  static const double _stackBelow = 720;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final d = ref.watch(ownerProvider).requireValue;
    final owner = ref.read(ownerProvider.notifier);
    final period = d.yearly ? MuBillingPeriod.year : MuBillingPeriod.month;
    final plan = OwnerPlans.of(d.plan);
    final trialEnd = ref.watch(clockProvider)().add(const Duration(days: OwnerCatalog.trialDays));
    final then = d.yearly ? '${formatDT(plan.yearly)}/an' : '${formatDT(plan.monthly)}/mois';
    final venue = d.venueName.trim().isEmpty ? l10n.tonTerrain2 : d.venueName.trim();
    final n = d.courts.length;

    Widget card(OwnerPlan p) => MuPricingCard(
      plan: OwnerPlans.of(p),
      period: period,
      recommended: p == OwnerPlan.pro,
      chosen: d.plan == p,
      savings: l10n.moisOfferts,
      trialDays: OwnerCatalog.trialDays,
      onCta: () => owner.edit((d) => d.copyWith(plan: p)),
    );

    final cards = MediaQuery.sizeOf(context).width < _stackBelow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              card(OwnerPlan.starter),
              const SizedBox(height: MuSpace.s6),
              card(OwnerPlan.pro),
            ],
          )
        : IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: card(OwnerPlan.starter)),
                const SizedBox(width: MuSpace.s5),
                Expanded(child: card(OwnerPlan.pro)),
              ],
            ),
          );

    return OwnerWizard(
      step: 7,
      title: l10n.choisisTonOffre,
      lead:
          l10n.joursDEssaiGratuitSur(OwnerCatalog.trialDays),
      continueLabel: l10n.demarrerLEssaiGratuit,
      draftNote: false,
      onContinue: () async {
        await owner.startTrial();
        if (context.mounted) context.go(Routes.ownerDashboard);
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: MuSpace.s4,
            runSpacing: MuSpace.s3,
            children: [
              MuSegmentedControl<MuBillingPeriod>(
                semanticLabel: l10n.periodeDeFacturation,
                value: period,
                segments: [
                  MuSegment(value: MuBillingPeriod.month, label: l10n.mensuel),
                  MuSegment(value: MuBillingPeriod.year, label: l10n.annuel, badge: l10n.moisOfferts),
                ],
                onChanged: (v) => owner.edit((d) => d.copyWith(yearly: v == MuBillingPeriod.year)),
              ),
              if (n > OwnerCatalog.starterCourts)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.info(), size: MuSize.iconXs, color: c.textSecondary),
                    const SizedBox(width: MuSpace.s2),
                    Flexible(
                      child: Text(
                        l10n.aTerrainsAvecStarterSeuls(venue, n, OwnerCatalog.starterCourts),
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: MuSpace.s5),
          cards,
          const SizedBox(height: MuSpace.s5),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: MuSpace.s3,
            runSpacing: MuSpace.s2,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.shieldCheck(), size: MuSize.iconXs, color: c.textSecondary),
                  const SizedBox(width: MuSpace.s2),
                  Text(
                    l10n.sansEngagementResiliableEnClics,
                    style: MuType.label.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              Text(
                l10n.dtAujourdHuiPuisA(plan.name, then, formatDay(trialEnd)),
                style: MuType.label.copyWith(color: c.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
