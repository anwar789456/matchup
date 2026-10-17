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
import '../../payments/data/payment_repository.dart';
import '../../payments/widgets/checkout_widgets.dart';
import '../controllers/subscription_controller.dart';
import '../data/subscription_repository.dart';
import '../widgets/subscription_widgets.dart';
import 'offers_screen.dart';

/// SUB-04 · Abonnement: the plan card (trial days left, next charge, card), « Changer d’offre »,
/// the reminder, the payment methods, the PDF receipts and « Résilier l’abonnement ». Cancelled,
/// the card says until when Premium stays and offers « Réactiver Premium ».
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  // SUB-04: the plan mark is 40.
  static const double _mark = 40;
  static const double _glow = 0.7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final sub = ref.watch(subscriptionProvider).value;
    if (sub == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: const Center(child: MuSpinner()),
      );
    }
    if (!sub.premium) return const OffersScreen();
    final now = ref.read(clockProvider)();
    final cancelled = sub.status == PremiumStatus.cancelled;
    final left = sub.trialEnds.difference(DateTime(now.year, now.month, now.day)).inDays;
    final cards = ref.watch(paymentCardsProvider).value ?? const <PaymentCard>[];
    final receipts = ref.watch(receiptsProvider).value ?? const <ReceiptEntry>[];
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inverse = c.textInverse;
    final soft = inverse.withValues(alpha: _glow);
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    final end = formatDay(sub.trialEnds);

    final (String nextValue, String thenValue) = cancelled
        ? ('Aucun', 'Offre Gratuit après le ${sub.trialEnds.day} ${formatMonth(sub.trialEnds)}')
        : sub.offerAccepted
        ? (
            '${formatDT(Subscription.offerMonthly)} · $end',
            '${formatDT(Subscription.monthly)}/mois dès le 30 déc.',
          )
        : (
            '${formatDT(sub.price)} · $end',
            sub.yearlyPlan
                ? '${perPeriod(Subscription.yearly, sub.period)}, le 30 oct.'
                : '${perPeriod(Subscription.monthly, sub.period)}, le 30',
          );

    Widget overline(String s) => Padding(
      padding: const EdgeInsetsDirectional.only(start: MuSpace.s4, bottom: MuSpace.s2),
      child: Text(s.toUpperCase(), style: MuType.overline.copyWith(color: c.textSecondary)),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(title: 'Abonnement', onBack: () => goBack(context, Routes.home)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s8),
              children: [
                Container(
                  padding: const EdgeInsets.all(MuSpace.s4),
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
                          Container(
                            width: _mark,
                            height: _mark,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.accent,
                              borderRadius: MuRadius.smAll,
                            ),
                            child: Icon(
                              PhosphorIcons.crown(PhosphorIconsStyle.fill),
                              size: MuSize.iconM,
                              color: c.onAccent,
                            ),
                          ),
                          const SizedBox(width: MuSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Premium', style: MuType.h3.copyWith(color: inverse)),
                                Text(
                                  'Joueur · ${sub.yearlyPlan ? 'annuel' : 'mensuel'}',
                                  style: MuType.caption.copyWith(color: soft),
                                ),
                              ],
                            ),
                          ),
                          MuStatusBadge(
                            status: cancelled ? MuStatus.cancelled : MuStatus.confirmed,
                            label: cancelled ? 'Résilié' : 'Essai gratuit',
                            size: MuBadgeSize.s,
                          ),
                        ],
                      ),
                      const SizedBox(height: MuSpace.s4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cancelled ? 'Premium actif' : '$left jours d’essai restants',
                              style: MuType.label.copyWith(color: inverse),
                            ),
                          ),
                          Text('jusqu’au $end', style: MuType.caption.copyWith(color: soft)),
                        ],
                      ),
                      const SizedBox(height: MuSpace.s2),
                      // On the ink card the bar takes the Night match primary (Volt).
                      MuNightTheme(
                        child: MuProgressBar(
                          value: (Subscription.trialDays - left)
                              .clamp(1, Subscription.trialDays)
                              .toDouble(),
                          max: Subscription.trialDays.toDouble(),
                          size: MuProgressSize.s,
                          showValue: false,
                        ),
                      ),
                      const SizedBox(height: MuSpace.s2),
                      SubLine('Prochain prélèvement', nextValue, inverse: true),
                      Divider(height: 1, thickness: 1, color: inverse.withValues(alpha: 0.12)),
                      SubLine('Ensuite', thenValue, inverse: true),
                      Divider(height: 1, thickness: 1, color: inverse.withValues(alpha: 0.12)),
                      SubLine('Carte', sub.cardLabel, inverse: true),
                      const SizedBox(height: MuSpace.s3),
                      MuNightTheme(
                        child: Row(
                          children: [
                            Expanded(
                              child: cancelled
                                  ? MuButton.primary(
                                      label: 'Réactiver Premium',
                                      leading: PhosphorIcons.arrowCounterClockwise(),
                                      fullWidth: true,
                                      onPressed: () =>
                                          ref.read(subscriptionProvider.notifier).reactivate(),
                                    )
                                  : MuButton.secondary(
                                      label: 'Changer d’offre',
                                      fullWidth: true,
                                      onPressed: () => context.push(Routes.subscriptionChange),
                                    ),
                            ),
                            const SizedBox(width: MuSpace.s3),
                            Expanded(
                              child: MuButton.tertiary(
                                label: 'Voir les avantages',
                                fullWidth: true,
                                onPressed: () => context.push(Routes.subscriptionOffers),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!cancelled) ...[
                  const SizedBox(height: MuSpace.s5),
                  MuBanner(
                    tone: MuBannerTone.info,
                    icon: PhosphorIcons.bellRinging(PhosphorIconsStyle.fill),
                    title: 'Rappel le ${formatDay(sub.reminder)}',
                    detail: 'On te prévient 3 jours avant le premier prélèvement, par notification et email.',
                  ),
                ],
                const SizedBox(height: MuSpace.s6),
                overline('Moyens de paiement'),
                MuCardSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, card) in cards.indexed) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: c.border,
                            indent: MuSpace.s4,
                            endIndent: MuSpace.s4,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(MuSpace.s4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BrandMark(card.mark),
                              const SizedBox(width: MuSpace.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: MuSpace.s2,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          card.label,
                                          style: MuType.label.copyWith(color: c.text),
                                        ),
                                        if (card.isDefault)
                                          const MuStatusBadge(
                                            status: MuStatus.neutral,
                                            label: 'Par défaut',
                                            size: MuBadgeSize.s,
                                          ),
                                      ],
                                    ),
                                    if (card.expiresSoon) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            PhosphorIcons.warning(PhosphorIconsStyle.fill),
                                            size: MuSize.iconXs,
                                            color: c.warningText,
                                          ),
                                          const SizedBox(width: MuSpace.s1),
                                          Text(
                                            'Expire le mois prochain (${card.expiry})',
                                            style: MuType.caption.copyWith(color: c.warningText),
                                          ),
                                        ],
                                      ),
                                      MuButton.link(
                                        label: 'Mettre à jour la carte',
                                        onPressed: () => showComingSoon(context),
                                      ),
                                    ] else
                                      Text(
                                        'Expire ${card.expiry}${card.label == sub.cardLabel ? ' · utilisée pour Premium' : ''}',
                                        style: caption,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                const SizedBox(height: MuSpace.s6),
                overline('Factures et reçus'),
                MuCardSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, r) in receipts.indexed) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: c.border,
                            indent: MuSpace.s4,
                            endIndent: MuSpace.s4,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(MuSpace.s4),
                          child: Row(
                            children: [
                              Container(
                                width: MuSize.controlL,
                                height: MuSize.controlL,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: c.surfaceMuted,
                                  borderRadius: MuRadius.smAll,
                                ),
                                child: Icon(
                                  PhosphorIcons.receipt(),
                                  size: MuSize.iconS,
                                  color: c.text,
                                ),
                              ),
                              const SizedBox(width: MuSpace.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.label, style: MuType.label.copyWith(color: c.text)),
                                    Text(
                                      'Reçu · ${r.date.day} ${formatMonth(r.date)} · ${r.card}',
                                      style: caption,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: MuSpace.s2),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatDT(r.amount),
                                    style: MuType.numS.copyWith(color: c.text),
                                  ),
                                  const SizedBox(height: MuSpace.s1),
                                  Semantics(
                                    label:
                                        'Télécharger le reçu PDF, ${r.label}, ${r.date.day} ${formatMonth(r.date)}',
                                    excludeSemantics: true,
                                    child: MuButton.secondary(
                                      label: 'PDF',
                                      leading: PhosphorIcons.downloadSimple(),
                                      size: MuButtonSize.s,
                                      onPressed: () => context.push(Routes.receipt, extra: r),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                  child: Text(
                    'Ta première facture Premium arrivera le $end, avec le prélèvement.',
                    style: caption,
                  ),
                ),
                if (!cancelled) ...[
                  const SizedBox(height: MuSpace.s6),
                  MuCardSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Résilier Premium', style: MuType.h3.copyWith(color: c.text)),
                        const SizedBox(height: MuSpace.s1),
                        Text(
                          'En 2 étapes, sans frais. Si tu résilies pendant l’essai, tu gardes Premium jusqu’au $end et rien n’est prélevé.',
                          style: MuType.body.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: MuSpace.s4),
                        MuButton(
                          variant: MuButtonVariant.destructiveOutline,
                          label: 'Résilier l’abonnement',
                          leading: PhosphorIcons.xCircle(),
                          size: MuButtonSize.l,
                          fullWidth: true,
                          onPressed: () => context.push(Routes.subscriptionCancel),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
