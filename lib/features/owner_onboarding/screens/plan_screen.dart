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

/// The owner plans (OWN-08).
abstract final class OwnerPlans {
  static final starter = MuPlan(
    name: 'Starter',
    audience: 'Propriétaire',
    icon: PhosphorIcons.storefront(),
    pitch: 'Ton terrain réservable en ligne en 10 minutes.',
    monthly: 79,
    yearly: 790,
    features: const [
      ('Jusqu’à 2 terrains', true),
      ('Calendrier et réservations en ligne', true),
      ('Paiement en ligne · commission 5 %', true),
      ('Statistiques d’occupation et de revenus', false),
      ('Tarifs heures creuses / pleines', false),
      ('Comptes gérants', false),
    ],
  );

  static final pro = MuPlan(
    name: 'Pro',
    audience: 'Propriétaire',
    icon: PhosphorIcons.storefront(),
    pitch: 'Remplis tes créneaux creux.',
    monthly: 149,
    yearly: 1490,
    features: const [
      ('Terrains illimités', true),
      ('Statistiques d’occupation et de revenus', true),
      ('Tarifs heures creuses / pleines', true),
      ('Jusqu’à 5 comptes gérants', true),
      ('Paiement en ligne · commission 3 %', true),
      ('Support prioritaire 7j/7', true),
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
    final venue = d.venueName.trim().isEmpty ? 'Ton terrain' : d.venueName.trim();
    final n = d.courts.length;

    Widget card(OwnerPlan p) => MuPricingCard(
      plan: OwnerPlans.of(p),
      period: period,
      recommended: p == OwnerPlan.pro,
      chosen: d.plan == p,
      savings: '2 mois offerts',
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
      title: 'Choisis ton offre',
      lead:
          '${OwnerCatalog.trialDays} jours d’essai gratuit sur les deux offres. Aucun paiement '
          'aujourd’hui.',
      continueLabel: 'Démarrer l’essai gratuit',
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
                semanticLabel: 'Période de facturation',
                value: period,
                segments: const [
                  MuSegment(value: MuBillingPeriod.month, label: 'Mensuel'),
                  MuSegment(value: MuBillingPeriod.year, label: 'Annuel', badge: '2 mois offerts'),
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
                        '$venue a $n terrains : avec Starter, seuls '
                        '${OwnerCatalog.starterCourts} seraient réservables.',
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
                    'Sans engagement · résiliable en 2 clics',
                    style: MuType.label.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              Text(
                '${plan.name} · 0 DT aujourd’hui, puis $then à partir du ${formatDay(trialEnd)}',
                style: MuType.label.copyWith(color: c.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
