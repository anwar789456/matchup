import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../payments/widgets/checkout_widgets.dart';
import '../controllers/subscription_controller.dart';
import '../data/subscription_repository.dart';
import '../widgets/subscription_widgets.dart';
import '../../../l10n/l10n.dart';

/// The billing period picked on SUB-01, carried to SUB-02.
class PremiumPeriodController extends Notifier<MuBillingPeriod> {
  @override
  MuBillingPeriod build() => MuBillingPeriod.month;

  void set(MuBillingPeriod p) => state = p;
}

final premiumPeriodProvider = NotifierProvider<PremiumPeriodController, MuBillingPeriod>(
  PremiumPeriodController.new,
);

/// The plans of SUB-01 (STORY-DATA « Plans »).
abstract final class Plans {
  static MuPlan premium = MuPlan(
    name: l10n.premium,
    audience: l10n.joueur,
    icon: PhosphorIcons.user(),
    pitch: l10n.passeAvantLesAutresEt,
    monthly: Subscription.monthly,
    yearly: Subscription.yearly,
    features: [
      (l10n.prioriteSurLesListesD, true),
      (l10n.plansDEntrainementIa, true),
      (l10n.programmesDesCoachsInclus, true),
      (l10n.statistiquesAvancees, true),
      (l10n.pasDeFraisDeService, true),
    ],
  );
  static MuPlan free = MuPlan(
    name: l10n.gratuit,
    audience: l10n.joueur,
    icon: PhosphorIcons.user(),
    pitch: l10n.partiesReservationsEtNiveauIa,
    monthly: 0,
    yearly: 0,
    features: [
      (l10n.partiesOuvertesATonNiveau, true),
      (l10n.reservationEtPaiementDeTa, true),
      (l10n.niveauIaEtFiabilite, true),
      (l10n.prioriteSurLesListesD, false),
      (l10n.plansDEntrainementIa, false),
    ],
  );
  static MuPlan pro = MuPlan(
    name: l10n.pro,
    audience: l10n.proprietaire,
    icon: PhosphorIcons.storefront(),
    pitch: l10n.remplisTesCreneauxCreuxEt,
    monthly: 149,
    yearly: 1490,
    features: [
      (l10n.terrainsIllimites, true),
      (l10n.reservationsEnLigne, true),
      (l10n.paiementsDesJoueurs, true),
      (l10n.tarifsDynamiques, true),
      (l10n.insightsIa, true),
      (l10n.plusieursSites, true),
    ],
  );
  static MuPlan starter = MuPlan(
    name: l10n.starter,
    audience: l10n.proprietaire,
    icon: PhosphorIcons.storefront(),
    pitch: l10n.tonTerrainReservableEnLigne,
    monthly: 79,
    yearly: 790,
    features: [
      (l10n.siteJusquATerrains, true),
      (l10n.reservationsEnLigne, true),
      (l10n.paiementsDesJoueurs, true),
      (l10n.tarifsDynamiques, false),
      (l10n.insightsIa, false),
      (l10n.plusieursSites, false),
    ],
  );
  static MuPlan coach = MuPlan(
    name: l10n.coach,
    audience: l10n.entraineurs,
    icon: PhosphorIcons.chalkboardTeacher(),
    pitch: l10n.publieTesProgrammesEtSuis2,
    monthly: 39,
    yearly: 390,
    features: [
      (l10n.programmesIllimites, true),
      (l10n.paiementsDesEleves, true),
      (l10n.statistiquesDeTesEleves, true),
      (l10n.commissionDeSurLesVentes, true),
    ],
  );
}

/// « 19 DT/mois » or « 190 DT/an ».
String perPeriod(num amount, MuBillingPeriod p) =>
    '${formatDT(amount)}/${p == MuBillingPeriod.year ? 'an' : 'mois'}';

/// « 14 jours gratuits, puis 19 DT/mois · Résiliable à tout moment ».
String trialNote(MuPlan plan, MuBillingPeriod p) =>
    l10n.joursGratuitsPuisResiliableA(perPeriod(p == MuBillingPeriod.year ? plan.yearly : plan.monthly, p));

/// SUB-01 · Offres et abonnements: Joueur · Propriétaire · Coach tabs, Mensuel / Annuel, the
/// pricing cards, the Gratuit / Premium comparison and the FAQ, with the sticky « Essayer Premium
/// gratuitement ».
class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({super.key});

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> {
  int _tab = 0;

  // SUB-01 comparison: the Gratuit and Premium columns are 80 and 84 wide, rows at least 48.
  static const double _freeCol = 80;
  static const double _premCol = 84;
  static const double _row = 48;
  static const double _premTint = 0.14;
  static const double _premHeadTint = 0.34;

  static final _intro = [
    l10n.essaiePremiumJoursGratuitementAucun,
    l10n.metsTonTerrainEnLigne,
    l10n.vendsTesProgrammesEtSuis,
  ];

  static final _rows = <(String, Object, Object)>[
    (l10n.partiesOuvertesEtReservations, true, true),
    (l10n.paiementDeTaPartEn, true, true),
    (l10n.niveauIaEtFiabilite, true, true),
    (l10n.prioriteSurLesListesD, false, true),
    (l10n.plansDEntrainementIa, false, true),
    (l10n.programmesDesCoachs, false, true),
    (l10n.statistiques, l10n.deBase, l10n.avancees),
    (l10n.fraisDeService, l10n.offertsAuLancement, l10n.dt),
  ];

  static final _faq = [
    (
      l10n.estCeQueJePaie,
      l10n.nonDtAujourdHuiOn,
    ),
    (
      l10n.commentJeResilie,
      l10n.dansMonCompteAbonnementResilier,
    ),
    (
      l10n.jePeuxPasserAL,
      l10n.ouiAToutMomentTu,
    ),
    (
      l10n.queSePasseTIl,
      l10n.tuGardesTesMatchsTon,
    ),
  ];

  void _tryPremium() => context.push(Routes.premiumCheckout);

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final period = ref.watch(premiumPeriodProvider);
    final sub = ref.watch(subscriptionProvider).value;
    final premium = sub?.premium ?? false;
    final yearly = period == MuBillingPeriod.year;

    Widget cell(Object v, {required bool prem}) {
      if (v is String) {
        return Text(
          v,
          textAlign: TextAlign.center,
          style: prem
              ? MuType.labelS.copyWith(color: c.text)
              : MuType.caption.copyWith(color: c.textSecondary),
        );
      }
      return v == true
          ? Semantics(
              label: l10n.inclus,
              child: Icon(
                PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                size: MuSize.iconS,
                color: c.successText,
              ),
            )
          : Semantics(
              label: l10n.nonInclus,
              child: Icon(PhosphorIcons.minus(), size: MuSize.iconS, color: c.textDisabled),
            );
    }

    Widget compareRow(Widget label, Widget free, Widget prem, {bool head = false}) =>
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: head ? MuSize.controlXl : _row),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      MuSpace.s4,
                      MuSpace.s2,
                      MuSpace.s2,
                      MuSpace.s2,
                    ),
                    child: Align(alignment: AlignmentDirectional.centerStart, child: label),
                  ),
                ),
                SizedBox(
                  width: _freeCol,
                  child: Center(child: free),
                ),
                Container(
                  width: _premCol,
                  color: c.accent.withValues(alpha: head ? _premHeadTint : _premTint),
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
                  child: Center(child: prem),
                ),
              ],
            ),
          ),
        );

    final cards = switch (_tab) {
      0 => [
        MuPricingCard(
          plan: Plans.premium,
          period: period,
          recommended: true,
          current: premium,
          savings: l10n.moisOfferts,
          cta: l10n.essayerJoursGratuits,
          trialNote: trialNote(Plans.premium, period),
          onCta: _tryPremium,
        ),
        MuPricingCard(
          plan: Plans.free,
          period: period,
          compact: true,
          current: !premium,
          onCta: null,
        ),
      ],
      1 => [
        MuPricingCard(
          plan: Plans.pro,
          period: period,
          recommended: true,
          savings: l10n.moisOfferts,
          cta: l10n.choisirPro,
          trialNote: trialNote(Plans.pro, period),
          onCta: () => context.push(Routes.ownerCompany),
        ),
        MuPricingCard(
          plan: Plans.starter,
          period: period,
          savings: l10n.moisOfferts,
          cta: l10n.choisirStarter,
          trialNote: trialNote(Plans.starter, period),
          onCta: () => context.push(Routes.ownerCompany),
        ),
      ],
      _ => [
        MuPricingCard(
          plan: Plans.coach,
          period: period,
          savings: l10n.moisOfferts,
          cta: l10n.devenirCoach,
          trialNote: trialNote(Plans.coach, period),
          onCta: () => context.push(Routes.coachProfile),
        ),
      ],
    };

    final caption = MuType.caption.copyWith(color: c.textSecondary);
    final (barLabel, barNote, barAction) = switch (_tab) {
      0 when premium => (l10n.gererMonAbonnement, null, () => context.push(Routes.subscription)),
      0 => (
        l10n.essayerPremiumGratuitement,
        l10n.dtAujourdHuiPuisDes(perPeriod(yearly ? Subscription.yearly : Subscription.monthly, period)),
        _tryPremium,
      ),
      1 => (
        l10n.terminerMonEspaceProprietaire,
        l10n.tuChoisisTonOffreA,
        () => context.push(Routes.ownerCompany),
      ),
      _ => (
        l10n.devenirCoach,
        l10n.profilVerifieAvantTaPremiere,
        () => context.push(Routes.coachProfile),
      ),
    };

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.offresEtAbonnements,
            onBack: () => goBack(context, Routes.home),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.jouePlusProgressePlusVite,
                    style: MuType.h1.copyWith(color: c.text),
                  ),
                ),
                const SizedBox(height: MuSpace.s2),
                Text(_intro[_tab], style: MuType.bodyL.copyWith(color: c.textSecondary)),
                const SizedBox(height: MuSpace.s5),
                MuTabs(
                  label: l10n.offresParProfil,
                  tabs: [MuTab(l10n.joueur), MuTab(l10n.proprietaire), MuTab(l10n.coach)],
                  index: _tab,
                  fullWidth: true,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                const SizedBox(height: MuSpace.s6),
                MuSegmentedControl<MuBillingPeriod>(
                  semanticLabel: l10n.periodeDeFacturation,
                  expand: true,
                  segments: [
                    MuSegment(value: MuBillingPeriod.month, label: l10n.mensuel),
                    MuSegment(value: MuBillingPeriod.year, label: l10n.annuel, badge: '−17 %'),
                  ],
                  value: period,
                  onChanged: (p) => ref.read(premiumPeriodProvider.notifier).set(p),
                ),
                const SizedBox(height: MuSpace.s6),
                for (final (i, card) in cards.indexed) ...[
                  if (i > 0) const SizedBox(height: MuSpace.s4),
                  card,
                ],
                if (_tab == 0) ...[
                  const SizedBox(height: MuSpace.s6),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.compareGratuitEtPremium,
                      style: MuType.h3.copyWith(color: c.text),
                    ),
                  ),
                  const SizedBox(height: MuSpace.s1),
                  Text(
                    l10n.tesReservationsTonNiveauEt,
                    style: MuType.body.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: MuSpace.s3),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: MuRadius.mdAll,
                      border: Border.all(color: c.border),
                      boxShadow: MuElevation.of(context).level1,
                    ),
                    child: Column(
                      children: [
                        ColoredBox(
                          color: c.surfaceMuted,
                          child: compareRow(
                            Text(l10n.inclus2, style: MuType.overline.copyWith(color: c.textSecondary)),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l10n.gratuit, style: MuType.label.copyWith(color: c.text)),
                                Text(formatDT(0), style: caption),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l10n.premium, style: MuType.label.copyWith(color: c.text)),
                                Text(
                                  perPeriod(
                                    yearly ? Subscription.yearly : Subscription.monthly,
                                    period,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: MuType.caption.copyWith(color: c.text),
                                ),
                              ],
                            ),
                            head: true,
                          ),
                        ),
                        for (final (label, free, prem) in _rows) ...[
                          Divider(height: 1, thickness: 1, color: c.border),
                          compareRow(
                            Text(label, style: MuType.body.copyWith(color: c.text)),
                            cell(free, prem: false),
                            cell(prem, prem: true),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: MuSpace.s6),
                  Semantics(
                    header: true,
                    child: Text(l10n.questionsFrequentes, style: MuType.h3.copyWith(color: c.text)),
                  ),
                  const SizedBox(height: MuSpace.s3),
                  FaqAccordion(items: _faq),
                ],
                const SizedBox(height: MuSpace.s5),
                SecureNote(text: l10n.prixTtcEnDinarsPaiement),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          MuButton.primary(
            label: barLabel,
            size: MuButtonSize.xl,
            fullWidth: true,
            onPressed: barAction,
          ),
          if (barNote != null) Text(barNote, textAlign: TextAlign.center, style: caption),
        ],
      ),
    );
  }
}
