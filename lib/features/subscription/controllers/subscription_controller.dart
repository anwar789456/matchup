import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui.dart';
import '../../payments/data/payment_repository.dart';
import '../../payments/data/stripe_gateway.dart';
import '../data/subscription_repository.dart';

/// The player's Premium, shared by SUB-01 to SUB-08 and the account menu.
///
/// With Stripe (test mode), Premium is a Stripe subscription: Stripe charges the saved card at
/// the end of the 14-day trial and every period after, and keeps an invoice each time. Every
/// change goes to Stripe first; [refreshFromStripe] brings back its state and the invoices
/// (kept as receipts and payments, so they sync to Supabase). Without Stripe, the phone alone.
class SubscriptionController extends AsyncNotifier<Subscription> {
  SubscriptionRepository get _repo => ref.read(subscriptionRepositoryProvider);
  StripeGateway get _stripe => ref.read(stripeGatewayProvider);

  @override
  Future<Subscription> build() async {
    final local = await ref.watch(subscriptionRepositoryProvider).current();
    if (StripeConfig.enabled) Future.microtask(refreshFromStripe);
    return local;
  }

  Future<void> _run(Future<Subscription> Function() change) async {
    state = AsyncData(await change());
  }

  /// [card]: a Stripe card (« pm_… ») makes it a real Stripe subscription.
  Future<void> startTrial(MuBillingPeriod period, PaymentCard card) => _run(() async {
    if (StripeConfig.enabled && card.isStripe) {
      final sub = await _stripe.subscribe(yearly: period == MuBillingPeriod.year, amount: _price(period), paymentMethodId: card.id);
      if (sub != null) return _apply(sub, cardLabel: card.label);
    }
    return _repo.startTrial(period: period, cardLabel: card.label);
  });

  Future<void> changePeriod(MuBillingPeriod period) => _run(() async {
    if (StripeConfig.enabled) {
      final sub = await _stripe.subscription('change', period == MuBillingPeriod.year, _price(period));
      if (sub != null) return _apply(sub);
    }
    return _repo.changePeriod(period);
  });

  Future<void> cancel({CancelReason? reason, String? note}) => _run(() async {
    if (StripeConfig.enabled) {
      final sub = await _stripe.subscription('cancel');
      if (sub != null) {
        await _repo.cancel(reason: reason, note: note);
        return _apply(sub);
      }
    }
    return _repo.cancel(reason: reason, note: note);
  });

  Future<void> acceptOffer() => _run(() async {
    if (StripeConfig.enabled) {
      final sub = await _stripe.subscription('discount');
      if (sub != null) return _apply(sub);
    }
    return _repo.acceptOffer();
  });

  Future<void> reactivate() => _run(() async {
    if (StripeConfig.enabled) {
      final sub = await _stripe.subscription('resume');
      if (sub != null) return _apply(sub, clearReason: true);
    }
    return _repo.reactivate();
  });

  /// Debug menu: ends the trial now, so Stripe charges the first period at once (test mode).
  Future<void> endTrialNow() => _run(() async {
    final sub = await _stripe.subscription('end_trial');
    return sub == null ? _repo.current() : _apply(sub);
  });

  /// Stripe's state and invoices (at start, after a change, from the debug menu).
  Future<void> refreshFromStripe() async {
    try {
      final sub = await _stripe.subscription();
      if (sub == null) return;
      state = AsyncData(await _apply(sub));
    } catch (e) {
      debugPrint('Abonnement Stripe non lu : $e');
    }
  }

  static num _price(MuBillingPeriod p) => p == MuBillingPeriod.year ? Subscription.yearly : Subscription.monthly;

  /// Keeps Stripe's state on the phone and every paid invoice as a receipt and a payment.
  Future<Subscription> _apply(StripeSubscription sub, {String? cardLabel, bool clearReason = false}) async {
    final local = await _repo.current();
    final next = local.copyWith(
      status: sub.ended
          ? PremiumStatus.free
          : sub.cancelAtPeriodEnd
          ? PremiumStatus.cancelled
          : sub.trialing
          ? PremiumStatus.trial
          : PremiumStatus.active,
      period: sub.yearly ? MuBillingPeriod.year : MuBillingPeriod.month,
      cardLabel: cardLabel,
      offerAccepted: sub.discount,
      trialEnds: sub.nextDate,
      reminder: sub.nextDate.subtract(const Duration(days: 3)),
      cancelReason: clearReason ? () => null : null,
    );
    await _repo.save(next);
    await _keepInvoices(sub.invoices);
    return next;
  }

  Future<void> _keepInvoices(List<StripeInvoice> invoices) async {
    if (invoices.isEmpty) return;
    final kept = {for (final r in await _repo.receipts()) r.number};
    final payments = ref.read(paymentRepositoryProvider);
    for (final i in invoices.where((i) => !kept.contains(i.number))) {
      final card = i.last4 == null ? 'Carte · Stripe' : '${i.brand == 'mastercard' ? 'Mastercard' : 'Visa'} •••• ${i.last4} · Stripe';
      await _repo.addReceipt(ReceiptEntry(
        number: i.number,
        label: 'MatchUp Premium',
        date: i.paidAt,
        amount: i.amount,
        card: card,
        reference: i.paymentIntentId,
        lines: [ReceiptLine('MatchUp Premium', i.amount, details: [card])],
      ));
      if (i.paymentIntentId != null) {
        await payments.recordStripe(
          amount: i.amount,
          reason: 'MatchUp Premium',
          intentId: i.paymentIntentId!,
          reference: i.number,
          brand: cardBrandOf(i.brand),
          last4: i.last4,
        );
      }
    }
    ref.invalidate(receiptsProvider);
  }
}

final subscriptionProvider = AsyncNotifierProvider<SubscriptionController, Subscription>(
  SubscriptionController.new,
);

/// The cancel flow's answer (SUB-06), read by SUB-07.
class CancelReasonController extends Notifier<CancelReason?> {
  @override
  CancelReason? build() => CancelReason.price;

  void set(CancelReason? r) => state = r;
}

final cancelReasonProvider = NotifierProvider<CancelReasonController, CancelReason?>(
  CancelReasonController.new,
);
