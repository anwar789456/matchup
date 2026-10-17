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
import '../../../l10n/l10n.dart';

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
    final unit = yearly ? l10n.parAn : l10n.parMois;
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
            title: l10n.paiement,
            onBack: _busy ? null : () => goBack(context, Routes.subscriptionOffers),
            actions: [MuBarAction(icon: PhosphorIcons.lockSimple(), label: l10n.securise)],
          ),
          const TestRibbon(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s6),
              children: [
                FlowTitle(
                  l10n.demarreTonEssaiPremium,
                  lead: l10n.joursPourToutEssayerTu,
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
                                  l10n.matchupPremium,
                                  style: MuType.labelL.copyWith(color: c.text),
                                ),
                                Text(l10n.joueurSansEngagement, style: caption),
                              ],
                            ),
                          ),
                          MuButton.tertiary(
                            label: l10n.modifier,
                            size: MuButtonSize.s,
                            onPressed: () => goBack(context, Routes.subscriptionOffers),
                          ),
                        ],
                      ),
                      const SizedBox(height: MuSpace.s3),
                      MuSegmentedControl<MuBillingPeriod>(
                        semanticLabel: l10n.periodeDeFacturation,
                        expand: true,
                        segments: [
                          MuSegment(
                            value: MuBillingPeriod.month,
                            label: l10n.mensuel2(formatDT(Subscription.monthly)),
                          ),
                          MuSegment(
                            value: MuBillingPeriod.year,
                            label: l10n.annuel2(formatDT(Subscription.yearly)),
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
                        l10n.aujourdHuiEssaiGratuit,
                        l10n.toutPremiumDebloquePendantJours,
                        formatDT(0),
                        done: true,
                      ),
                      step(
                        PhosphorIcons.bell(),
                        l10n.marOctRappel,
                        l10n.onTePrevientJoursAvant,
                        null,
                      ),
                      step(
                        PhosphorIcons.creditCard(),
                        l10n.venOct1erPrelevement,
                        yearly
                            ? l10n.surTaCartePuisChaque
                            : l10n.surTaCartePuisChaque2,
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
                                l10n.aPayerAujourdHui,
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
                  child: Text(l10n.cartePourApresLEssai, style: MuType.h3.copyWith(color: c.text)),
                ),
                const SizedBox(height: MuSpace.s1),
                Text(
                  l10n.rienNEstDebiteAujourd,
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
                        title: l10n.ajouterUneCarte,
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
                    title: l10n.cetteCarteExpireAvantTon,
                    detail: l10n.leNovLePaiementEchouerait,
                  ),
                ],
                const SizedBox(height: MuSpace.s5),
                CheckLine(
                  span: TextSpan(
                    children: [
                      TextSpan(
                        text: l10n.resiliableAToutMoment,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: l10n.enEtapesDepuisTonCompte),
                    ],
                  ),
                ),
                CheckLine(
                  span: TextSpan(
                    children: [
                      TextSpan(
                        text: l10n.rappelJoursAvant,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: l10n.lePremierPrelevementTuAs),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s4),
                Divider(height: 1, thickness: 1, color: c.border),
                const SizedBox(height: MuSpace.s4),
                MuCheckbox(
                  value: _agree,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                  label: l10n.jAccepteLesConditionsD2,
                  description:
                      l10n.jAutoriseMatchupAPrelever(formatDT(amount), unit, card?.label ?? 'carte'),
                  error: _tried && !_agree ? l10n.cocheCetteCasePourDemarrer : null,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          MuButton.primary(
            label: l10n.commencerLEssaiGratuit,
            price: formatDT(0),
            size: MuButtonSize.xl,
            fullWidth: true,
            loading: _busy,
            onPressed: card == null || _busy ? null : () => _start(card, period),
          ),
          Text(
            l10n.puisDesLeVenOct(perPeriod(amount, period)),
            textAlign: TextAlign.center,
            style: caption,
          ),
          SecureNote(),
        ],
      ),
    );
  }
}
