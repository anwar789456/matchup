import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide CardBrand;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import 'payment_repository.dart';

/// Stripe in test mode (free, fake money). The publishable key comes with the Supabase settings:
///
///     "STRIPE_PUBLISHABLE_KEY": "pk_test_…"   in supabase.json
///
/// and the secret key lives only in the `stripe-payment-intent` Edge Function. Without both, the
/// checkout keeps the simulated bank of the debug menu (CLAUDE.md rule 10).
abstract final class StripeConfig {
  static const publishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  static bool _ready = false;

  /// Stripe took the key: the checkout shows Stripe's card field for a new card.
  static bool get enabled => _ready && SupabaseConfig.configured;

  static Future<void> init() async {
    if (!publishableKey.startsWith('pk_test_') || !SupabaseConfig.configured || _ready) return;
    try {
      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
      _ready = true;
    } catch (e) {
      debugPrint('Stripe indisponible, paiement simulé : $e');
    }
  }
}

/// A PaymentIntent made by the Edge Function.
@immutable
class StripeIntent {
  const StripeIntent({required this.id, required this.clientSecret});

  /// « pi_3Q… ».
  final String id;
  final String clientSecret;
}

/// What Stripe answered after the card (and 3-D Secure, shown by Stripe itself).
@immutable
class StripeOutcome {
  const StripeOutcome.paid(this.intentId, {this.paymentMethodId}) : failure = null, cancelled = false;
  const StripeOutcome.failed(this.failure, {this.cancelled = false}) : intentId = null, paymentMethodId = null;

  /// « pi_… » for a payment, « seti_… » for a saved card.
  final String? intentId;

  /// The card Stripe used (« pm_… »), to save it.
  final String? paymentMethodId;

  /// Stripe's message, already in plain words (« Your card was declined. »).
  final String? failure;

  /// The player closed the bank's window.
  final bool cancelled;

  bool get paid => intentId != null;
}

/// A card saved on the user's Stripe customer.
@immutable
class StripeCard {
  const StripeCard({required this.id, required this.brand, required this.last4, required this.expMonth, required this.expYear});

  /// « pm_… ».
  final String id;

  /// « visa », « mastercard »…
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
}

/// Our card brands (the cards table knows Visa and Mastercard); null for another brand.
CardBrand? cardBrandOf(String? stripeBrand) => switch (stripeBrand?.toLowerCase()) {
  'visa' => CardBrand.visa,
  'mastercard' => CardBrand.mastercard,
  _ => null,
};

/// Saves a Stripe card in the cards table (synced to Supabase) under its « pm_… » id.
Future<PaymentCard?> saveStripeCard(PaymentRepository repo, StripeCard card) async {
  final brand = cardBrandOf(card.brand);
  if (brand == null) return null;
  return repo.addCard(id: card.id, brand: brand, last4: card.last4, expMonth: card.expMonth, expYear: card.expYear);
}

abstract interface class StripeGateway {
  /// A PaymentIntent; [save] keeps the card for later, [paymentMethodId] pays with a saved card.
  Future<StripeIntent> createIntent({
    required num amount,
    required String description,
    String? reference,
    bool save = false,
    String? paymentMethodId,
  });

  /// A SetupIntent: saves a card without charging it (Premium trial, « Ajouter une carte »).
  Future<StripeIntent> createSetup();

  /// Confirms with the card typed in Stripe's [CardField].
  Future<StripeOutcome> confirmCard(StripeIntent intent, {String? holderName});

  /// Confirms with a saved card.
  Future<StripeOutcome> confirmSaved(StripeIntent intent, String paymentMethodId);

  /// Saves the card typed in Stripe's [CardField].
  Future<StripeOutcome> confirmSetup(StripeIntent setup, {String? holderName});

  Future<StripeCard> card(String paymentMethodId);
}

class SupabaseStripeGateway implements StripeGateway {
  Future<Map<String, Object?>> _call(Map<String, Object?> body) async {
    final res = await Supabase.instance.client.functions.invoke('stripe-payment-intent', body: body);
    final data = Map<String, Object?>.from(res.data as Map);
    if (data['error'] != null) throw StateError('${data['error']}');
    return data;
  }

  StripeIntent _intent(Map<String, Object?> d) =>
      StripeIntent(id: d['id']! as String, clientSecret: d['clientSecret']! as String);

  static BillingDetails? _billing(String? name) =>
      name == null || name.trim().isEmpty ? null : BillingDetails(name: name.trim());

  static StripeOutcome _failure(StripeException e) => StripeOutcome.failed(
        e.error.localizedMessage ?? e.error.message ?? e.error.code.name,
        cancelled: e.error.code == FailureCode.Canceled,
      );

  @override
  Future<StripeIntent> createIntent({
    required num amount,
    required String description,
    String? reference,
    bool save = false,
    String? paymentMethodId,
  }) async =>
      _intent(await _call({
        'action': 'payment',
        'amount': amount,
        'description': description,
        'reference': reference,
        'save': save,
        'paymentMethodId': paymentMethodId,
      }));

  @override
  Future<StripeIntent> createSetup() async => _intent(await _call({'action': 'setup'}));

  Future<StripeOutcome> _confirm(StripeIntent intent, PaymentMethodParams params) async {
    try {
      final pi = await Stripe.instance.confirmPayment(paymentIntentClientSecret: intent.clientSecret, data: params);
      return pi.status == PaymentIntentsStatus.Succeeded
          ? StripeOutcome.paid(pi.id, paymentMethodId: pi.paymentMethodId)
          : StripeOutcome.failed(pi.status.name);
    } on StripeException catch (e) {
      return _failure(e);
    }
  }

  @override
  Future<StripeOutcome> confirmCard(StripeIntent intent, {String? holderName}) => _confirm(
        intent,
        PaymentMethodParams.card(paymentMethodData: PaymentMethodData(billingDetails: _billing(holderName))),
      );

  @override
  Future<StripeOutcome> confirmSaved(StripeIntent intent, String paymentMethodId) => _confirm(
        intent,
        PaymentMethodParams.cardFromMethodId(
          paymentMethodData: PaymentMethodDataCardFromMethod(paymentMethodId: paymentMethodId),
        ),
      );

  @override
  Future<StripeOutcome> confirmSetup(StripeIntent setup, {String? holderName}) async {
    try {
      final si = await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: setup.clientSecret,
        params: PaymentMethodParams.card(paymentMethodData: PaymentMethodData(billingDetails: _billing(holderName))),
      );
      return si.status.toLowerCase() == 'succeeded'
          ? StripeOutcome.paid(si.id, paymentMethodId: si.paymentMethodId)
          : StripeOutcome.failed(si.status);
    } on StripeException catch (e) {
      return _failure(e);
    }
  }

  @override
  Future<StripeCard> card(String paymentMethodId) async {
    final d = await _call({'action': 'card', 'paymentMethodId': paymentMethodId});
    return StripeCard(
      id: d['id']! as String,
      brand: '${d['brand']}',
      last4: '${d['last4']}',
      expMonth: (d['expMonth']! as num).toInt(),
      expYear: (d['expYear']! as num).toInt(),
    );
  }
}

final stripeGatewayProvider = Provider<StripeGateway>((ref) => SupabaseStripeGateway());
