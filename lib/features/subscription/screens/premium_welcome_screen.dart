import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../home/controllers/home_providers.dart';
import '../controllers/subscription_controller.dart';
import '../widgets/subscription_widgets.dart';
import 'offers_screen.dart';
import '../../../l10n/l10n.dart';

/// SUB-03 · Bienvenue dans Premium: the hero, what is unlocked now, the trial recap, then
/// « Découvrir Premium » (Home) or « Gérer mon abonnement » (SUB-04).
class PremiumWelcomeScreen extends ConsumerWidget {
  const PremiumWelcomeScreen({super.key});

  // SUB-03: the crown medal is 80 inside a 96 halo, the crown 36.
  static const double _medal = 80;
  static const double _halo = 96;
  static const double _crown = 36;
  static const double _haloAlpha = 0.18;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final me = ref.watch(meProvider).value;
    final sub = ref.watch(subscriptionProvider).value;
    final padel = me?.levels[MuSport.padel];
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    final inverse = c.textInverse;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s2, MuSpace.s2, MuSpace.s4, 0),
              child: Row(
                children: [
                  MuIconButton(
                    icon: PhosphorIcons.x(),
                    label: l10n.fermer,
                    size: MuIconButtonSize.l,
                    onPressed: () => context.go(Routes.home),
                  ),
                  const Spacer(),
                  MuStatusBadge(
                    status: MuStatus.confirmed,
                    label: l10n.essaiActive,
                    size: MuBadgeSize.s,
                  ),
                  const Spacer(),
                  const SizedBox(width: MuSize.controlL),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, MuSpace.s6),
              children: [
                Container(
                  padding: const EdgeInsets.all(MuSpace.s6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? c.night700
                        : c.surfaceInverse,
                    borderRadius: MuRadius.lgAll,
                    border: Theme.of(context).brightness == Brightness.dark
                        ? Border.all(color: c.border)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: _halo,
                        height: _halo,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: _haloAlpha),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: _medal,
                          height: _medal,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                          child: Icon(
                            PhosphorIcons.crown(PhosphorIconsStyle.fill),
                            size: _crown,
                            color: c.onAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: MuSpace.s4),
                      Text(l10n.matchupPremium2, style: MuType.overline.copyWith(color: c.accent)),
                      const SizedBox(height: MuSpace.s2),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.bienvenueDansPremium(me?.firstName ?? l10n.yassine),
                          textAlign: TextAlign.center,
                          style: MuType.h1.copyWith(color: inverse),
                        ),
                      ),
                      const SizedBox(height: MuSpace.s3),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: l10n.toutEstDebloqueJusquAu),
                            TextSpan(
                              text: formatDay(sub?.trialEnds ?? DateTime(2026, 10, 30)),
                              style: MuType.label.copyWith(color: inverse),
                            ),
                            const TextSpan(text: '.\nTu ne paies rien d’ici là.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: MuType.body.copyWith(color: inverse.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s6),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.ceQuiChangeDesMaintenant,
                    style: MuType.h3.copyWith(color: c.text),
                  ),
                ),
                const SizedBox(height: MuSpace.s3),
                MuCardSurface(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s1),
                  child: Column(
                    children: [
                      for (final (i, row) in [
                        BenefitRow(
                          icon: PhosphorIcons.hourglass(),
                          title: l10n.prioriteSurLesListesD,
                          text: l10n.quandUnePlaceSeLibere,
                        ),
                        BenefitRow(
                          icon: PhosphorIcons.barbell(),
                          title: l10n.plansDEntrainement,
                          trailing: MuAiLabel(size: MuAiLabelSize.s),
                          text:
                              l10n.unPlanParSemaineSelon(formatLevel(padel ?? 3.5)),
                        ),
                        BenefitRow(
                          icon: PhosphorIcons.listChecks(),
                          title: l10n.programmesDesCoachsInclus,
                          text: l10n.plusBesoinDeLesAcheter,
                        ),
                        BenefitRow(
                          icon: PhosphorIcons.chartLineUp(),
                          title: l10n.statistiquesAvancees,
                          text: l10n.tendancesMeilleursCoequipiersHistoriqueC,
                        ),
                        BenefitRow(
                          icon: PhosphorIcons.tag(),
                          title: l10n.pasDeFraisDeService,
                          text: l10n.surToutesTesReservationsEt,
                        ),
                      ].indexed) ...[
                        if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
                        row,
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s6),
                Semantics(
                  header: true,
                  child: Text(l10n.tonAbonnement, style: MuType.h3.copyWith(color: c.text)),
                ),
                const SizedBox(height: MuSpace.s2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                  child: Column(
                    children: [
                      SubLine(
                        l10n.essaiGratuit,
                        l10n.jusquAu2(formatDay(sub?.trialEnds ?? DateTime(2026, 10, 30))),
                      ),
                      Divider(height: 1, thickness: 1, color: c.border),
                      SubLine(l10n.rappel, formatDay(sub?.reminder ?? DateTime(2026, 10, 27))),
                      Divider(height: 1, thickness: 1, color: c.border),
                      SubLine(
                        l10n.ensuite,
                        '${perPeriod(sub?.price ?? 19, sub?.period ?? MuBillingPeriod.month)} · ${sub?.cardLabel ?? l10n.visa}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s3),
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.envelopeSimple(),
                      size: MuSize.iconXs,
                      color: c.textSecondary,
                    ),
                    const SizedBox(width: MuSpace.s2),
                    Expanded(
                      child: Text(
                        l10n.confirmationEnvoyeeA(me?.email ?? l10n.tonAdresse),
                        style: caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          MuButton.primary(
            label: l10n.decouvrirPremium,
            trailing: PhosphorIcons.arrowRight(),
            size: MuButtonSize.xl,
            fullWidth: true,
            onPressed: () => context.go(Routes.home),
          ),
          MuButton.tertiary(
            label: l10n.gererMonAbonnement,
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: () => context.push(Routes.subscription),
          ),
        ],
      ),
    );
  }
}
