import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' show CardField, CardFieldInputDetails;

import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/payment_repository.dart';
import '../data/stripe_gateway.dart';
import 'checkout_widgets.dart';

/// PAY-03 outside the checkout (« Ajouter une carte », « Mettre à jour la carte » in SUB-02 and
/// SUB-04): the same [CardInputZone] in a sheet; the card is saved and the lists refresh. With
/// Stripe, the card is typed in Stripe's field and saved on the player's Stripe customer (no
/// charge), so it can pay later.
Future<PaymentCard?> showAddCardSheet(BuildContext context) {
  final key = GlobalKey<_AddCardFormState>();
  return MuBottomSheet.show<PaymentCard>(
    context,
    title: l10n.nouvelleCarte,
    height: MuSheetHeight.full,
    snapPoints: const [MuSheetHeight.full],
    child: _AddCardForm(key: key),
    footer: MuButton.primary(
      label: l10n.enregistrer,
      size: MuButtonSize.l,
      fullWidth: true,
      onPressed: () => key.currentState?.save(),
    ),
  );
}

class _AddCardForm extends ConsumerStatefulWidget {
  const _AddCardForm({super.key});

  @override
  ConsumerState<_AddCardForm> createState() => _AddCardFormState();
}

class _AddCardFormState extends ConsumerState<_AddCardForm> {
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();
  String _country = CardInputZone.countries.first;
  Map<String, String> _errors = const {};
  bool _busy = false;
  CardFieldInputDetails? _stripeCard;

  @override
  void dispose() {
    for (final c in [_name, _number, _expiry, _cvc]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (_busy) return;
    if (StripeConfig.enabled) return _saveWithStripe();
    final errors = CardInputZone.validate(number: _number.text, expiry: _expiry.text, cvc: _cvc.text);
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    _busy = true;
    final digits = _number.text.replaceAll(' ', '');
    final exp = _expiry.text.replaceAll(RegExp(r'\D'), '');
    final card = await ref
        .read(paymentRepositoryProvider)
        .addCard(
          brand: digits.startsWith('5') ? CardBrand.mastercard : CardBrand.visa,
          last4: digits.substring(digits.length - 4),
          expMonth: int.parse(exp.substring(0, 2)),
          expYear: 2000 + int.parse(exp.substring(2)),
        );
    ref.invalidate(paymentCardsProvider);
    if (!mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    Navigator.of(context).pop(card);
    MuToast.show(context, overlay: overlay, tone: MuToastTone.success, title: l10n.carteAjoutee, description: card.label);
  }

  Future<void> _saveWithStripe() async {
    if (_stripeCard?.complete != true) {
      setState(() => _errors = {'stripe': l10n.numeroDeCarteInvalide});
      return;
    }
    setState(() {
      _busy = true;
      _errors = const {};
    });
    final gateway = ref.read(stripeGatewayProvider);
    try {
      final outcome = await gateway.confirmSetup(await gateway.createSetup(), holderName: _name.text);
      if (!outcome.paid || outcome.paymentMethodId == null) {
        if (mounted) setState(() => _errors = {'stripe': outcome.failure ?? l10n.numeroDeCarteInvalide});
        return;
      }
      final card = await saveStripeCard(ref.read(paymentRepositoryProvider), await gateway.card(outcome.paymentMethodId!));
      ref.invalidate(paymentCardsProvider);
      if (!mounted) return;
      final overlay = Overlay.of(context, rootOverlay: true);
      Navigator.of(context).pop(card);
      if (card != null) {
        MuToast.show(context, overlay: overlay, tone: MuToastTone.success, title: l10n.carteAjoutee, description: card.label);
      }
    } catch (e) {
      if (mounted) setState(() => _errors = {'stripe': '$e'});
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s4),
    child: CardInputZone(
      name: _name,
      number: _number,
      expiry: _expiry,
      cvc: _cvc,
      country: _country,
      onCountry: (v) => setState(() => _country = v ?? _country),
      errors: _errors,
      stripeField: StripeConfig.enabled
          ? CardField(
              countryCode: 'TN',
              style: MuType.body.copyWith(color: context.mu.text),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: MuRadius.smAll, borderSide: BorderSide(color: context.mu.borderControl)),
                contentPadding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s3),
              ),
              onCardChanged: (d) => setState(() => _stripeCard = d),
            )
          : null,
    ),
  );
}
