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
    name: 'Premium',
    audience: 'Joueur',
    icon: PhosphorIcons.user(),
    pitch: 'Passe avant les autres et progresse avec l’IA.',
    monthly: Subscription.monthly,
    yearly: Subscription.yearly,
    features: const [
      ('Priorité sur les listes d’attente', true),
      ('Plans d’entraînement IA', true),
      ('Programmes des coachs inclus', true),
      ('Statistiques avancées', true),
      ('Pas de frais de service', true),
    ],
  );
  static MuPlan free = MuPlan(
    name: 'Gratuit',
    audience: 'Joueur',
    icon: PhosphorIcons.user(),
    pitch: 'Parties, réservations et niveau IA, sans engagement.',
    monthly: 0,
    yearly: 0,
    features: const [
      ('Parties ouvertes à ton niveau', true),
      ('Réservation et paiement de ta part', true),
      ('Niveau IA et fiabilité', true),
      ('Priorité sur les listes d’attente', false),
      ('Plans d’entraînement IA', false),
    ],
  );
  static MuPlan pro = MuPlan(
    name: 'Pro',
    audience: 'Propriétaire',
    icon: PhosphorIcons.storefront(),
    pitch: 'Remplis tes créneaux creux et gère plusieurs sites.',
    monthly: 149,
    yearly: 1490,
    features: const [
      ('Terrains illimités', true),
      ('Réservations en ligne', true),
      ('Paiements des joueurs', true),
      ('Tarifs dynamiques', true),
      ('Insights IA', true),
      ('Plusieurs sites', true),
    ],
  );
  static MuPlan starter = MuPlan(
    name: 'Starter',
    audience: 'Propriétaire',
    icon: PhosphorIcons.storefront(),
    pitch: 'Ton terrain réservable en ligne en 10 minutes.',
    monthly: 79,
    yearly: 790,
    features: const [
      ('1 site · jusqu’à 3 terrains', true),
      ('Réservations en ligne', true),
      ('Paiements des joueurs', true),
      ('Tarifs dynamiques', false),
      ('Insights IA', false),
      ('Plusieurs sites', false),
    ],
  );
  static MuPlan coach = MuPlan(
    name: 'Coach',
    audience: 'Entraîneurs',
    icon: PhosphorIcons.chalkboardTeacher(),
    pitch: 'Publie tes programmes et suis tes élèves.',
    monthly: 39,
    yearly: 390,
    features: const [
      ('Programmes illimités', true),
      ('Paiements des élèves', true),
      ('Statistiques de tes élèves', true),
      ('Commission de 10 % sur les ventes', true),
    ],
  );
}

/// « 19 DT/mois » or « 190 DT/an ».
String perPeriod(num amount, MuBillingPeriod p) =>
    '${formatDT(amount)}/${p == MuBillingPeriod.year ? 'an' : 'mois'}';

/// « 14 jours gratuits, puis 19 DT/mois · Résiliable à tout moment ».
String trialNote(MuPlan plan, MuBillingPeriod p) =>
    '14 jours gratuits, puis ${perPeriod(p == MuBillingPeriod.year ? plan.yearly : plan.monthly, p)}'
    ' · Résiliable à tout moment';

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

  static const _intro = [
    'Essaie Premium 14 jours gratuitement. Aucun prélèvement avant le ven. 30 oct., résiliable en 2 étapes.',
    'Mets ton terrain en ligne et encaisse les parts des joueurs. 14 jours d’essai sur les deux offres.',
    'Vends tes programmes et suis tes élèves. 14 jours d’essai, puis une commission de 10 % sur tes ventes.',
  ];

  static const _rows = <(String, Object, Object)>[
    ('Parties ouvertes et réservations', true, true),
    ('Paiement de ta part en ligne', true, true),
    ('Niveau IA et fiabilité', true, true),
    ('Priorité sur les listes d’attente', false, true),
    ('Plans d’entraînement IA', false, true),
    ('Programmes des coachs', false, true),
    ('Statistiques', 'De base', 'Avancées'),
    ('Frais de service', 'Offerts au lancement', '0 DT'),
  ];

  static const _faq = [
    (
      'Est-ce que je paie pendant l’essai ?',
      'Non : 0 DT aujourd’hui. On te prévient le mar. 27 oct., 3 jours avant le premier prélèvement de 19 DT le ven. 30 oct.',
    ),
    (
      'Comment je résilie ?',
      'Dans Mon compte › Abonnement › « Résilier l’abonnement », en 2 étapes, sans appel ni frais. Premium reste actif jusqu’à la fin de la période déjà payée.',
    ),
    (
      'Je peux passer à l’annuel plus tard ?',
      'Oui, à tout moment. Tu vois le montant exact avant de confirmer, et ce que tu as déjà payé est déduit au prorata.',
    ),
    (
      'Que se passe-t-il si je repasse en Gratuit ?',
      'Tu gardes tes matchs, ton niveau, ta fiabilité et ton solde. Tu perds la priorité sur les listes d’attente, les plans IA et les statistiques avancées.',
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
              label: 'Inclus',
              child: Icon(
                PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                size: MuSize.iconS,
                color: c.successText,
              ),
            )
          : Semantics(
              label: 'Non inclus',
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
          savings: '2 mois offerts',
          cta: 'Essayer 14 jours gratuits',
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
          savings: '2 mois offerts',
          cta: 'Choisir Pro',
          trialNote: trialNote(Plans.pro, period),
          onCta: () => context.push(Routes.ownerCompany),
        ),
        MuPricingCard(
          plan: Plans.starter,
          period: period,
          savings: '2 mois offerts',
          cta: 'Choisir Starter',
          trialNote: trialNote(Plans.starter, period),
          onCta: () => context.push(Routes.ownerCompany),
        ),
      ],
      _ => [
        MuPricingCard(
          plan: Plans.coach,
          period: period,
          savings: '2 mois offerts',
          cta: 'Devenir coach',
          trialNote: trialNote(Plans.coach, period),
          onCta: () => context.push(Routes.coachProfile),
        ),
      ],
    };

    final caption = MuType.caption.copyWith(color: c.textSecondary);
    final (barLabel, barNote, barAction) = switch (_tab) {
      0 when premium => ('Gérer mon abonnement', null, () => context.push(Routes.subscription)),
      0 => (
        'Essayer Premium gratuitement',
        '0 DT aujourd’hui, puis ${perPeriod(yearly ? Subscription.yearly : Subscription.monthly, period)} dès le ven. 30 oct. · Résiliable à tout moment',
        _tryPremium,
      ),
      1 => (
        'Terminer mon espace propriétaire',
        'Tu choisis ton offre à la dernière étape · 14 jours gratuits',
        () => context.push(Routes.ownerCompany),
      ),
      _ => (
        'Devenir coach',
        'Profil vérifié avant ta première vente · 14 jours gratuits',
        () => context.push(Routes.coachProfile),
      ),
    };

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: 'Offres et abonnements',
            onBack: () => goBack(context, Routes.home),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Joue plus. Progresse plus vite.',
                    style: MuType.h1.copyWith(color: c.text),
                  ),
                ),
                const SizedBox(height: MuSpace.s2),
                Text(_intro[_tab], style: MuType.bodyL.copyWith(color: c.textSecondary)),
                const SizedBox(height: MuSpace.s5),
                MuTabs(
                  label: 'Offres par profil',
                  tabs: const [MuTab('Joueur'), MuTab('Propriétaire'), MuTab('Coach')],
                  index: _tab,
                  fullWidth: true,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                const SizedBox(height: MuSpace.s6),
                MuSegmentedControl<MuBillingPeriod>(
                  semanticLabel: 'Période de facturation',
                  expand: true,
                  segments: const [
                    MuSegment(value: MuBillingPeriod.month, label: 'Mensuel'),
                    MuSegment(value: MuBillingPeriod.year, label: 'Annuel', badge: '−17 %'),
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
                      'Compare Gratuit et Premium',
                      style: MuType.h3.copyWith(color: c.text),
                    ),
                  ),
                  const SizedBox(height: MuSpace.s1),
                  Text(
                    'Tes réservations, ton niveau et ton historique restent dans les deux offres.',
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
                            Text('INCLUS', style: MuType.overline.copyWith(color: c.textSecondary)),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Gratuit', style: MuType.label.copyWith(color: c.text)),
                                Text(formatDT(0), style: caption),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Premium', style: MuType.label.copyWith(color: c.text)),
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
                    child: Text('Questions fréquentes', style: MuType.h3.copyWith(color: c.text)),
                  ),
                  const SizedBox(height: MuSpace.s3),
                  const FaqAccordion(items: _faq),
                ],
                const SizedBox(height: MuSpace.s5),
                const SecureNote(text: 'Prix TTC en dinars · Paiement sécurisé par Stripe'),
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
