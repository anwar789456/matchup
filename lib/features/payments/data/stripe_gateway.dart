import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';

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
  const StripeOutcome.paid(this.intentId) : failure = null, cancelled = false;
  const StripeOutcome.failed(this.failure, {this.cancelled = false}) : intentId = null;

  final String? intentId;

  /// Stripe's message, already in plain words (« Your card was declined. »).
  final String? failure;

  /// The player closed the bank's window.
  final bool cancelled;

  bool get paid => intentId != null;
}

abstract interface class StripeGateway {
  Future<StripeIntent> createIntent({required num amount, required String description, String? reference});

  /// Confirms with the card typed in Stripe's [CardField].
  Future<StripeOutcome> confirmCard(StripeIntent intent, {String? holderName});
}

class SupabaseStripeGateway implements StripeGateway {
  @override
  Future<StripeIntent> createIntent({required num amount, required String description, String? reference}) async {
    final res = await Supabase.instance.client.functions.invoke(
      'stripe-payment-intent',
      body: {'amount': amount, 'description': description, 'reference': reference},
    );
    final data = Map<String, Object?>.from(res.data as Map);
    if (data['clientSecret'] == null) throw StateError('${data['error'] ?? 'Stripe indisponible'}');
    return StripeIntent(id: data['id']! as String, clientSecret: data['clientSecret']! as String);
  }

  @override
  Future<StripeOutcome> confirmCard(StripeIntent intent, {String? holderName}) async {
    try {
      final pi = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: intent.clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(name: holderName?.trim().isEmpty ?? true ? null : holderName!.trim()),
          ),
        ),
      );
      return pi.status == PaymentIntentsStatus.Succeeded
          ? StripeOutcome.paid(pi.id)
          : StripeOutcome.failed(pi.status.name);
    } on StripeException catch (e) {
      return StripeOutcome.failed(
        e.error.localizedMessage ?? e.error.message ?? e.error.code.name,
        cancelled: e.error.code == FailureCode.Canceled,
      );
    }
  }
}

final stripeGatewayProvider = Provider<StripeGateway>((ref) => SupabaseStripeGateway());
