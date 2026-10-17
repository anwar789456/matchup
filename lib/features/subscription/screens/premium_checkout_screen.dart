import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../payments/data/payment_repository.dart';
import '../../payments/widgets/checkout_widgets.dart';
import '../controllers/subscription_controller.dart';
import '../data/subscription_repository.dart';
import '../widgets/subscription_widgets.dart';
import 'offers_screen.dart';

/// SUB-02 · Checkout Premium: the trial at 0 DT today — the plan (Mensuel / Annuel), the
/// timeline (today, reminder mar. 27 oct., first charge ven. 30 oct.), the card for after the
/// trial (the Phase 9 card rows), the consent and « Commencer l’essai gratuit · 0 DT ».
class PremiumCheckoutScreen extends ConsumerStatefulWidget {
  const PremiumCheckoutScreen({super.key});

  @override
  ConsumerState<PremiumCheckoutScreen> createState() => _PremiumCheckoutScreenState();
}

class _PremiumCheckoutScreenState extends ConsumerState<PremiumCheckoutScreen> {
  String? _cardId;
  bool _agree = false;
  bool _tried = false;
  bool _busy = false;

  // SUB-02: the timeline dots are 24, the plan mark 40.
  static const double _dot = 24;
  static const double _mark = 40;

  Future<void> _start(PaymentCard card, MuBillingPeriod period) async {
    if (!_agree) {
      setState(() => _tried = true);
      return;
    }
    setState(() => _busy = true);
    await ref.read(subscriptionProvider.notifier).startTrial(period, card.label);
    if (!mounted) return;
    context.go(Routes.premiumWelcome);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final period = ref.watch(premiumPeriodProvider);
    final yearly = period == MuBillingPeriod.year;
    final cards = ref.watch(paymentCardsProvider).value ?? const <PaymentCard>[];
    _cardId ??= cards.where((x) => x.isDefault).firstOrNull?.id ?? cards.firstOrNull?.id;
    final card = cards.where((x) => x.id == _cardId).firstOrNull;
    final amount = yearly ? Subscription.yearly : Subscription.monthly;
    final unit = yearly ? 'par an' : 'par mois';
    final caption = MuType.caption.copyWith(color: c.textSecondary);

    Widget step(
      IconData icon,
      String title,
      String text,
      String? value, {
      bool done = false,
      bool last = false,
    }) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: _dot,
                height: _dot,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? c.accent : c.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: MuSize.iconXs, color: done ? c.onAccent : c.textSecondary),
              ),
              if (!last) Expanded(child: Container(width: 1, color: c.border)),
            ],
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : MuSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: MuType.label.copyWith(color: c.text)),
                  Text(text, style: caption),
                ],
              ),
            ),
          ),
          if (value != null) Text(value, style: MuType.numS.copyWith(color: c.text)),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: 'Paiement',
            onBack: _busy ? null : () => goBack(context, Routes.subscriptionOffers),
            actions: [MuBarAction(icon: PhosphorIcons.lockSimple(), label: 'Sécurisé')],
          ),
          const TestRibbon(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s6),
              children: [
                const FlowTitle(
                  'Démarre ton essai Premium',
                  lead: '14 jours pour tout essayer. Tu ne paies rien aujourd’hui.',
                ),
                const SizedBox(height: MuSpace.s5),
                MuCardSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: _mark,
                            height: _mark,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.surfaceInverse,
                              borderRadius: MuRadius.smAll,
                            ),
                            child: Icon(
                              PhosphorIcons.crown(PhosphorIconsStyle.fill),
                              size: MuSize.iconM,
                              color: c.accent,
                            ),
                          ),
                          const SizedBox(width: MuSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MatchUp Premium',
                                  style: MuType.labelL.copyWith(color: c.text),
                                ),
                                Text('Joueur · sans engagement', style: caption),
                              ],
                            ),
                          ),
                          MuButton.tertiary(
                            label: 'Modifier',
                            size: MuButtonSize.s,
                            onPressed: () => goBack(context, Routes.subscriptionOffers),
                          ),
                        ],
                      ),
                      const SizedBox(height: MuSpace.s3),
                      MuSegmentedControl<MuBillingPeriod>(
                        semanticLabel: 'Période de facturation',
                        expand: true,
                        segments: [
                          MuSegment(
                            value: MuBillingPeriod.month,
                            label: 'Mensuel · ${formatDT(Subscription.monthly)}',
                          ),
                          MuSegment(
                            value: MuBillingPeriod.year,
                            label: 'Annuel · ${formatDT(Subscription.yearly)}',
                            badge: '−17 %',
                          ),
                        ],
                        value: period,
                        onChanged: (p) => ref.read(premiumPeriodProvider.notifier).set(p),
                      ),
                      const SizedBox(height: MuSpace.s4),
                      Divider(height: 1, thickness: 1, color: c.border),
                      const SizedBox(height: MuSpace.s4),
                      step(
                        PhosphorIcons.check(PhosphorIconsStyle.bold),
                        'Aujourd’hui · essai gratuit',
                        'Tout Premium débloqué pendant 14 jours',
                        formatDT(0),
                        done: true,
                      ),
                      step(
                        PhosphorIcons.bell(),
                        'mar. 27 oct. · rappel',
                        'On te prévient 3 jours avant, par notification et email',
                        null,
                      ),
                      step(
                        PhosphorIcons.creditCard(),
                        'ven. 30 oct. · 1er prélèvement',
                        yearly
                            ? 'Sur ta carte, puis chaque année le 30 oct.'
                            : 'Sur ta carte, puis chaque mois le 30',
                        formatDT(amount),
                        last: true,
                      ),
                      const SizedBox(height: MuSpace.s4),
                      Container(
                        padding: const EdgeInsets.all(MuSpace.s4),
                        decoration: BoxDecoration(
                          color: c.surfaceMuted,
                          borderRadius: MuRadius.smAll,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'À payer aujourd’hui',
                                style: MuType.labelL.copyWith(color: c.text),
                              ),
                            ),
                            Text(formatDT(0), style: MuType.numXl.copyWith(color: c.text)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s6),
                Semantics(
                  header: true,
                  child: Text('Carte pour après l’essai', style: MuType.h3.copyWith(color: c.text)),
                ),
                const SizedBox(height: MuSpace.s1),
                Text(
                  'Rien n’est débité aujourd’hui : ta banque peut juste afficher une vérification à 0 DT.',
                  style: MuType.body.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: MuSpace.s3),
                MuCardSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, x) in cards.indexed) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: c.border,
                            indent: MuSpace.s4,
                            endIndent: MuSpace.s4,
                          ),
                        CardRow(
                          card: x,
                          selected: _cardId == x.id,
                          onTap: () => setState(() => _cardId = x.id),
                        ),
                      ],
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: c.border,
                        indent: MuSpace.s4,
                        endIndent: MuSpace.s4,
                      ),
                      MuSettingsRow(
                        title: 'Ajouter une carte',
                        icon: PhosphorIcons.plus(),
                        onTap: () => showComingSoon(context),
                      ),
                    ],
                  ),
                ),
                if (card?.expiresSoon ?? false) ...[
                  const SizedBox(height: MuSpace.s3),
                  MuBanner(
                    tone: MuBannerTone.warning,
                    icon: PhosphorIcons.creditCard(),
                    title: 'Cette carte expire avant ton 2e prélèvement',
                    detail: 'Le 30 nov., le paiement échouerait. Choisis ta Visa ou mets cette carte à jour.',
                  ),
                ],
                const SizedBox(height: MuSpace.s5),
                const CheckLine(
                  span: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Résiliable à tout moment',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' en 2 étapes depuis ton compte, sans frais.'),
                    ],
                  ),
                ),
                const CheckLine(
                  span: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Rappel 3 jours avant',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' le premier prélèvement : tu as le temps de décider.'),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s4),
                Divider(height: 1, thickness: 1, color: c.border),
                const SizedBox(height: MuSpace.s4),
                MuCheckbox(
                  value: _agree,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                  label: 'J’accepte les conditions d’abonnement',
                  description:
                      'J’autorise MatchUp à prélever ${formatDT(amount)} $unit sur ma ${card?.label ?? 'carte'} à partir du ven. 30 oct. 2026, jusqu’à ce que je résilie.',
                  error: _tried && !_agree ? 'Coche cette case pour démarrer l’essai.' : null,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          MuButton.primary(
            label: 'Commencer l’essai gratuit',
            price: formatDT(0),
            size: MuButtonSize.xl,
            fullWidth: true,
            loading: _busy,
            onPressed: card == null || _busy ? null : () => _start(card, period),
          ),
          Text(
            'Puis ${perPeriod(amount, period)} dès le ven. 30 oct. · résiliable à tout moment',
            textAlign: TextAlign.center,
            style: caption,
          ),
          const SecureNote(),
        ],
      ),
    );
  }
}
