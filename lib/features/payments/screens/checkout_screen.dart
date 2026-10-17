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
import '../../home/controllers/home_providers.dart';
import '../../settings/data/settings_repository.dart';
import '../controllers/checkout_controller.dart';
import '../data/payment_repository.dart';
import '../widgets/checkout_widgets.dart';
import '../widgets/secure_payment_takeover.dart';
import '../../../l10n/l10n.dart';

enum _Mode { cards, newCard, network }

/// PAY-01 to PAY-08 · the checkout as one flow: the order summary (« Voir le détail »), promo
/// code, balance, saved cards or a new card, express buttons, the total, the policy, the terms
/// and « Payer 15 DT ». Declined cards, input errors, the bank's 3-D Secure step and network
/// errors are states of this screen; success goes to PAY-09, repeated failures to PAY-10.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  _Mode _mode = _Mode.cards;
  bool _detail = false;
  bool _useBalance = false;
  bool _accepted = false;
  bool _saveCard = true;
  bool _busy = false;
  String? _cardId;
  PromoResult? _promo;
  bool _promoBusy = false;
  String? _declinedNote;
  String? _declinedCardId;
  int _attempts = 0;
  bool _timeout = false;
  DateTime? _attemptAt;
  final _promoCtrl = TextEditingController();
  final _name = TextEditingController(text: l10n.yassineBelhaj);
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();
  String _country = 'Tunisie';
  Map<String, String> _errors = const {};

  // PAY-08: the place is kept 15 min after a network error.
  static const _hold = Duration(minutes: 15);
  static const int _maxAttempts = 3;

  @override
  void dispose() {
    for (final c in [_promoCtrl, _name, _number, _expiry, _cvc]) {
      c.dispose();
    }
    super.dispose();
  }

  num get _discount => _promo?.valid == true ? (_request!.amount * _promo!.percent! / 100) : 0;
  num get _total => _request!.amount - _discount;
  num get _balance => ref.read(meProvider).value?.balance ?? 0;
  num get _fromBalance => _useBalance ? (_balance < _total ? _balance : _total) : 0;
  num get _due => _total - _fromBalance;
  CheckoutRequest? get _request => ref.read(checkoutRequestProvider);

  Future<void> _applyPromo() async {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _promoBusy = true);
    final r = await ref.read(paymentRepositoryProvider).applyPromo(code);
    if (!mounted) return;
    setState(() {
      _promo = r;
      _promoBusy = false;
      if (r.valid) _detail = true;
    });
  }

  Map<String, String> _validateCard() {
    final errors = <String, String>{};
    final digits = _number.text.replaceAll(' ', '');
    if (digits.length < 16 || !CardInputZone.luhn(digits)) {
      errors['number'] = l10n.numeroDeCarteInvalide;
    }
    final exp = _expiry.text.replaceAll(RegExp(r'\D'), '');
    final month = exp.length >= 2 ? int.tryParse(exp.substring(0, 2)) : null;
    final year = exp.length == 4 ? int.tryParse(exp.substring(2)) : null;
    if (month == null || year == null || month < 1 || month > 12) {
      errors['expiry'] = l10n.dateDExpirationInvalide;
    } else if (year < 26 || (year == 26 && month < 10)) {
      errors['expiry'] = l10n.carteExpiree;
    }
    if (_cvc.text.length < 3) errors['cvc'] = l10n.cvcIncorrect;
    return errors;
  }

  Future<void> _pay() async {
    final req = _request!;
    final repo = ref.read(paymentRepositoryProvider);
    final cards = ref.read(paymentCardsProvider).value ?? const <PaymentCard>[];
    PaymentCard? card;
    final method = _due == 0 && _useBalance ? PayWith.balance : PayWith.card;

    if (method == PayWith.card) {
      if (_mode == _Mode.newCard) {
        final errors = _validateCard();
        if (_promo?.valid == false) errors['promo'] = l10n.codePromoExpire;
        if (errors.isNotEmpty) {
          setState(() => _errors = errors);
          return;
        }
        final exp = _expiry.text.replaceAll(RegExp(r'\D'), '');
        final digits = _number.text.replaceAll(' ', '');
        card = await repo.addCard(
          brand: digits.startsWith('5') ? CardBrand.mastercard : CardBrand.visa,
          last4: digits.substring(digits.length - 4),
          expMonth: int.parse(exp.substring(0, 2)),
          expYear: 2000 + int.parse(exp.substring(2)),
          save: _saveCard,
        );
        ref.invalidate(paymentCardsProvider);
      } else {
        card = cards.where((c) => c.id == _cardId).firstOrNull ?? cards.firstOrNull;
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _errors = const {};
    });
    final overlay = MuLoadingOverlay.show(
      context,
      amount: formatDT(_due == 0 ? _total : _due),
      detail: '${req.sport.label} · ${req.title} · ${req.subtitle}',
    );
    var result = await repo.charge(
      amount: _due == 0 ? _total : _due,
      reason: req.title,
      method: method,
      card: card,
    );
    if (!mounted) return;

    if (result.status == PaymentStatus.needsAuthentication) {
      overlay.close();
      final phone = ref.read(accountSettingsProvider).maskedPhone;
      final approved = await showSecurePaymentTakeover(
        context,
        amount: _due,
        cardLabel: card?.label ?? l10n.carte,
        phone: phone,
      );
      if (!mounted) return;
      result = await repo.confirmAuthentication(approved: approved);
      if (!mounted) return;
      if (result.status == PaymentStatus.success) {
        final o = MuLoadingOverlay.show(context, amount: formatDT(_due));
        await _succeed(o, result.receipt!, req);
        return;
      }
      _declined(result, card);
      return;
    }
    switch (result.status) {
      case PaymentStatus.success:
        await _succeed(overlay, result.receipt!, req);
      case PaymentStatus.declined:
        overlay.close();
        _declined(result, card);
      case PaymentStatus.networkError || PaymentStatus.timeout:
        overlay.close();
        setState(() {
          _busy = false;
          _mode = _Mode.network;
          _timeout = result.status == PaymentStatus.timeout;
          _attemptAt = result.attemptAt ?? DateTime.now();
        });
      case PaymentStatus.needsAuthentication:
        break;
    }
  }

  void _declined(PaymentResult result, PaymentCard? card) {
    _attempts++;
    if (_attempts >= _maxAttempts) {
      ref.read(lastPaymentProvider.notifier);
      context.push(Routes.paymentFailed, extra: (card?.label ?? l10n.taCarte, result.reason));
      setState(() {
        _busy = false;
        _attempts = 0;
      });
      return;
    }
    setState(() {
      _busy = false;
      _mode = _Mode.cards;
      _declinedCardId = card?.id;
      _declinedNote =
          l10n.refuseeA(formatTime(result.attemptAt ?? DateTime.now()), result.reason ?? l10n.refusDeLaBanque);
      _cardId = null;
    });
    MuToast.show(
      context,
      tone: MuToastTone.error,
      title: l10n.paiementRefuse,
      description: l10n.rienNAEteDebite,
    );
  }

  Future<void> _succeed(MuLoadingOverlay overlay, PaymentReceipt receipt, CheckoutRequest req) async {
    overlay.success(detail: l10n.taPlaceEstConfirmeeRecu);
    final pause = MuMotion.durationOf(context, MuMotion.success);
    await req.onPaid(receipt, _fromBalance);
    ref.read(lastPaymentProvider.notifier).set(req, receipt);
    await Future<void>.delayed(pause);
    if (!mounted) return;
    overlay.close();
    ref.read(checkoutRequestProvider.notifier).clear();
    if (req.kind == CheckoutKind.share) {
      context.pushReplacement(Routes.paymentSuccess);
    } else {
      MuToast.show(context, tone: MuToastTone.success, title: l10n.paiementConfirme);
      if (req.successRoute != null) {
        context.go(req.successRoute!);
      } else {
        context.pop();
      }
    }
  }

  Future<void> _checkStatus() async {
    setState(() => _busy = true);
    final r = await ref.read(paymentRepositoryProvider).checkStatus();
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.status == PaymentStatus.success) {
      await _succeed(MuLoadingOverlay.show(context, amount: formatDT(_due)), r.receipt!, _request!);
    } else {
      MuToast.show(
        context,
        title: l10n.taPartNEstPas,
        description: l10n.rienNAEteDebite2,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final req = ref.watch(checkoutRequestProvider);
    if (req == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(
          child: MuEmptyState(
            title: l10n.rienAPayer,
            description: l10n.reviensDepuisUneReservationOu,
            actions: [MuButton.primary(label: l10n.accueil, onPressed: () => context.go(Routes.home))],
          ),
        ),
      );
    }
    final cards = ref.watch(paymentCardsProvider).value ?? const <PaymentCard>[];
    _cardId ??= cards.where((x) => x.isDefault).firstOrNull?.id ?? cards.firstOrNull?.id;
    final balance = ref.watch(meProvider).value?.balance ?? 0;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    final payWithBalance = _useBalance && _due == 0;

    final summary = _Summary(
      request: req,
      open: _detail,
      total: _total,
      promo: _promo,
      onToggle: () => setState(() => _detail = !_detail),
      onRemovePromo: () => setState(() {
        _promo = null;
        _promoCtrl.clear();
      }),
    );

    final discounts = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (req.promoAllowed) ...[
          Semantics(
            label: l10n.reductions,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: MuTextField(
                    label: l10n.codePromo,
                    optional: true,
                    controller: _promoCtrl,
                    placeholder: l10n.exBienvenue10,
                    leadingIcon: PhosphorIcons.tag(),
                    textCapitalization: TextCapitalization.characters,
                    error: _promo?.error ?? _errors['promo'],
                    success: _promo?.valid == true ? l10n.code2(_promo!.code, '${_promo!.percent}') : null,
                    onSubmitted: (_) => _applyPromo(),
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                MuButton.secondary(
                  label: l10n.appliquer,
                  size: MuButtonSize.l,
                  loading: _promoBusy,
                  onPressed: _promoBusy ? null : _applyPromo,
                ),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s3),
        ],
        if (req.balanceAllowed)
          MuCardSurface(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
            child: MuSwitch(
              value: _useBalance,
              icon: PhosphorIcons.wallet(),
              label: l10n.utiliserMonSolde,
              description: '${formatDT(balance)} disponibles',
              onChanged: balance <= 0 ? (_) {} : (v) => setState(() => _useBalance = v),
            ),
          ),
      ],
    );

    final methods = _mode == _Mode.newCard
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(l10n.nouvelleCarte, style: MuType.h2.copyWith(color: c.text)),
                    ),
                  ),
                  MuButton.link(
                    label: l10n.mesCartes,
                    onPressed: () => setState(() {
                      _mode = _Mode.cards;
                      _errors = const {};
                    }),
                  ),
                ],
              ),
              const SizedBox(height: MuSpace.s3),
              CardInputZone(
                name: _name,
                number: _number,
                expiry: _expiry,
                cvc: _cvc,
                country: _country,
                onCountry: (v) => setState(() => _country = v ?? _country),
                errors: _errors,
              ),
              const SizedBox(height: MuSpace.s4),
              MuCheckbox(
                value: _saveCard,
                label: l10n.enregistrerCetteCarte,
                description:
                    l10n.pourPayerEnUnGeste,
                onChanged: (v) => setState(() => _saveCard = v ?? true),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  _declinedNote != null ? l10n.paieAutrement : l10n.moyenDePaiement,
                  style: MuType.h2.copyWith(color: c.text),
                ),
              ),
              if (_declinedNote != null) ...[
                const SizedBox(height: MuSpace.s1),
                Text(l10n.taPlaceTAttendChoisis, style: caption),
              ],
              const SizedBox(height: MuSpace.s3),
              if (payWithBalance)
                MuBanner(
                  tone: MuBannerTone.info,
                  title: l10n.tonSoldeCouvreToutTa,
                )
              else
                MuCardSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_declinedNote != null && balance >= _total)
                        Semantics(
                          button: true,
                          selected: _useBalance,
                          label: l10n.soldeMatchupCouvreTaPart(formatDT(balance)),
                          excludeSemantics: true,
                          child: InkWell(
                            onTap: () => setState(() => _useBalance = true),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
                              child: Row(
                                children: [
                                  Icon(
                                    _useBalance ? PhosphorIcons.radioButton(PhosphorIconsStyle.fill) : PhosphorIcons.circle(),
                                    size: MuSize.iconS,
                                    color: _useBalance ? c.primary : c.borderStrong,
                                  ),
                                  const SizedBox(width: MuSpace.s3),
                                  Icon(PhosphorIcons.wallet(), size: MuSize.iconM, color: c.text),
                                  const SizedBox(width: MuSpace.s3),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l10n.soldeMatchup2(formatDT(balance)), style: MuType.label.copyWith(color: c.text)),
                                        Text(l10n.couvreTaPartDe(formatDT(_total)), style: MuType.caption.copyWith(color: c.successText)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      for (final (i, card) in cards.indexed) ...[
                        if (i > 0 || (_declinedNote != null && balance >= _total))
                          Divider(height: 1, thickness: 1, color: c.border, indent: MuSpace.s4, endIndent: MuSpace.s4),
                        CardRow(
                          card: card,
                          selected: !_useBalance && _cardId == card.id,
                          note: card.id == _declinedCardId ? _declinedNote : null,
                          noteError: card.id == _declinedCardId,
                          onTap: () => setState(() {
                            _cardId = card.id;
                            if (_due == 0) _useBalance = false;
                          }),
                        ),
                      ],
                      Divider(height: 1, thickness: 1, color: c.border, indent: MuSpace.s4, endIndent: MuSpace.s4),
                      MuSettingsRow(
                        title: l10n.ajouterUneCarte,
                        icon: PhosphorIcons.plus(),
                        onTap: () => setState(() => _mode = _Mode.newCard),
                      ),
                    ],
                  ),
                ),
              if (!payWithBalance) ...[
                const SizedBox(height: MuSpace.s3),
                Center(child: Text(l10n.ouEnUnGeste, style: caption)),
                const SizedBox(height: MuSpace.s3),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: l10n.payerAvecApplePay(formatDT(_due)),
                        child: _ExpressPay(label: l10n.applePay, onPressed: () => showComingSoon(context)),
                      ),
                    ),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: Semantics(
                        label: l10n.payerAvecGooglePay(formatDT(_due)),
                        child: _ExpressPay(label: l10n.googlePay, onPressed: () => showComingSoon(context)),
                      ),
                    ),
                  ],
                ),
                if (_declinedNote != null) ...[
                  const SizedBox(height: MuSpace.s3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(PhosphorIcons.info(), size: MuSize.iconXs, color: c.textSecondary),
                      const SizedBox(width: MuSpace.s1),
                      Expanded(
                        child: Text(
                          l10n.taCarteEstApprovisionneeTa,
                          style: caption,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          );

    final total = TotalCard(
      lineLabel: req.lineLabel,
      amount: req.amount,
      total: _total,
      discountLabel: _promo?.valid == true ? l10n.code2(_promo!.code, '${_promo!.percent}') : null,
      discount: _promo?.valid == true ? _discount : null,
      feeLabel: req.kind == CheckoutKind.topUp ? l10n.fraisDeRecharge : l10n.fraisDeService,
      note: _fromBalance > 0
          ? l10n.debiteDeTonSoldeMatchup(formatDT(balance - _fromBalance))
          : null,
    );

    final body = _mode == _Mode.network
        ? _NetworkError(
            request: req,
            amount: _due,
            card: cards.where((x) => x.id == _cardId).firstOrNull,
            attemptAt: _attemptAt ?? DateTime.now(),
            timeout: _timeout,
            busy: _busy,
            summary: summary,
            onCheck: _checkStatus,
            onRetry: () {
              setState(() => _mode = _Mode.cards);
              _pay();
            },
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s6),
            children: [
              if (_errors.isNotEmpty) ...[
                MuBanner(
                  tone: MuBannerTone.error,
                  title: l10n.pointACorrigerAvantDe(_errors.length, _errors.length > 1 ? 's' : ''),
                  detail:
                      '${_errors.values.join(' · ')}. Rien n’a été débité. Ce que tu as saisi est gardé.',
                ),
                const SizedBox(height: MuSpace.s4),
              ],
              if (_declinedNote != null) ...[
                MuBanner(
                  tone: MuBannerTone.error,
                  title: l10n.paiementRefuse,
                  detail: l10n.taBanqueARefuseLe(_declinedNote!.split(' · ').last),
                ),
                const SizedBox(height: MuSpace.s4),
              ],
              summary,
              const SizedBox(height: MuSpace.s5),
              discounts,
              const SizedBox(height: MuSpace.s6),
              methods,
              const SizedBox(height: MuSpace.s6),
              total,
              if (req.extraInfo.isNotEmpty) ...[
                const SizedBox(height: MuSpace.s6),
                Semantics(header: true, child: Text(l10n.bonASavoir, style: MuType.h3.copyWith(color: c.text))),
                const SizedBox(height: MuSpace.s3),
                MuCardSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, (title, text)) in req.extraInfo.indexed) ...[
                        if (i > 0) const SizedBox(height: MuSpace.s3),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), size: MuSize.iconXs, color: c.successText),
                            const SizedBox(width: MuSpace.s2),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: MuType.label.copyWith(color: c.text)),
                                  Text(text, style: caption),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (req.policy != null) ...[
                const SizedBox(height: MuSpace.s6),
                PolicyCard(freeUntil: req.policy!.$1, halfUntil: req.policy!.$2, venue: req.policyVenue ?? req.title),
              ],
              const SizedBox(height: MuSpace.s6),
              MuCheckbox(
                value: _accepted,
                onChanged: (v) => setState(() => _accepted = v ?? false),
                labelSpan: TextSpan(
                  children: [
                    TextSpan(text: l10n.jAccepteLes),
                    TextSpan(text: req.termsLabel ?? l10n.conditionsDeReservation, style: const TextStyle(decoration: TextDecoration.underline)),
                    TextSpan(text: req.termsSuffix ?? l10n.etLaPolitiqueDAnnulation2(elideDe(req.policyVenue ?? req.title))),
                  ],
                ),
              ),
            ],
          );

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.paiement,
            backLabel: l10n.retourAuRecapitulatif,
            onBack: _busy ? null : () => context.pop(),
            actions: [MuBarAction(icon: PhosphorIcons.lockSimple(), label: l10n.securise)],
          ),
          const TestRibbon(),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: _mode == _Mode.network
          ? null
          : StickyActionBar(
              children: [
                MuButton.primary(
                  label: l10n.payer,
                  price: formatDT(_due == 0 ? _total : _due),
                  size: MuButtonSize.xl,
                  fullWidth: true,
                  loading: _busy,
                  onPressed: _accepted && !_busy ? _pay : null,
                ),
                SecureNote(),
              ],
            ),
    );
  }
}

/// « TA PART · RÉSERVATION MU-48213 » card with « Voir le détail » and the rows when open.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.request,
    required this.open,
    required this.total,
    required this.promo,
    required this.onToggle,
    required this.onRemovePromo,
  });

  final CheckoutRequest request;
  final bool open;
  final num total;
  final PromoResult? promo;
  final VoidCallback onToggle;
  final VoidCallback onRemovePromo;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = request;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    return Semantics(
      label: l10n.taCommande,
      child: MuCardSurface(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(MuSpace.s4),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: MuSize.controlL,
                    child: ClipRRect(
                      borderRadius: MuRadius.smAll,
                      child: r.kind == CheckoutKind.topUp
                          ? Container(
                              color: c.surfaceMuted,
                              child: Icon(PhosphorIcons.wallet(), color: c.text),
                            )
                          : MuCourtArt(sport: r.sport, variant: MuCourtArtVariant.pattern),
                    ),
                  ),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.eyebrow.toUpperCase(), style: MuType.overline.copyWith(color: c.textSecondary)),
                        Text(r.title, style: MuType.labelL.copyWith(color: c.text)),
                        Text(r.subtitle, style: caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (r.detailRows.isNotEmpty) ...[
              Divider(height: 1, thickness: 1, color: c.border),
              Semantics(
                button: true,
                label: open ? l10n.masquerLeDetailDeLa : l10n.voirLeDetailDeLa,
                excludeSemantics: true,
                child: InkWell(
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
                    child: Row(
                      children: [
                        Expanded(child: Text(open ? l10n.masquerLeDetail : l10n.voirLeDetail, style: MuType.label.copyWith(color: c.text))),
                        Text(formatDT(total), style: MuType.numM.copyWith(color: c.text)),
                        const SizedBox(width: MuSpace.s2),
                        Icon(open ? PhosphorIcons.caretUp() : PhosphorIcons.caretDown(), size: MuSize.iconS, color: c.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
              if (open)
                Padding(
                  padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (label, value, sub) in r.detailRows)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 72, child: Text(label, style: caption)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(value, style: MuType.label.copyWith(color: c.text)),
                                    if (sub != null) Text(sub, style: caption),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (r.spotsLine != null) ...[
                        const SizedBox(height: MuSpace.s2),
                        Text(r.spotsLine!, style: MuType.label.copyWith(color: c.text)),
                      ],
                      if (promo?.valid == true) ...[
                        const SizedBox(height: MuSpace.s2),
                        Row(
                          children: [
                            Expanded(child: Text(l10n.code2(promo!.code, '${promo!.percent}'), style: MuType.label.copyWith(color: c.successText))),
                            Text(formatDT(total), style: MuType.numS.copyWith(color: c.text)),
                            const SizedBox(width: MuSpace.s2),
                            MuButton.tertiary(label: l10n.retirer3, size: MuButtonSize.s, onPressed: onRemovePromo),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// PAY-08 · Erreur réseau (and its « délai dépassé » variant).
class _NetworkError extends StatelessWidget {
  const _NetworkError({
    required this.request,
    required this.amount,
    required this.card,
    required this.attemptAt,
    required this.timeout,
    required this.busy,
    required this.summary,
    required this.onCheck,
    required this.onRetry,
  });

  final CheckoutRequest request;
  final num amount;
  final PaymentCard? card;
  final DateTime attemptAt;
  final bool timeout;
  final bool busy;
  final Widget summary;
  final VoidCallback onCheck;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    Widget line(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
      child: Row(children: [Expanded(child: Text(label, style: caption)), value]),
    );
    Widget step(int n, String title, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: MuSize.iconM,
            height: MuSize.iconM,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
            child: Text('$n', style: MuType.labelS.copyWith(color: c.text)),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '$title ', style: MuType.label.copyWith(color: c.text)),
                TextSpan(text: text, style: MuType.body.copyWith(color: c.textSecondary)),
              ]),
            ),
          ),
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s6),
      children: [
        MuBanner(
          tone: MuBannerTone.error,
          icon: PhosphorIcons.wifiSlash(),
          title: timeout ? l10n.taBanqueMetTropDe : l10n.connexionPerduePendantLePaiement,
          detail:
              l10n.rienNAEteDebite3,
        ),
        const SizedBox(height: MuSpace.s4),
        Semantics(
          label: l10n.taTentativeDePaiement,
          child: MuCardSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                line(l10n.montant, Text(formatDT(amount), style: MuType.numS.copyWith(color: c.text))),
                line(l10n.carte, Text(card?.label ?? l10n.carte, style: MuType.label.copyWith(color: c.text))),
                line(l10n.tentative, Text(formatDateTime(attemptAt), style: MuType.label.copyWith(color: c.text))),
                line(l10n.statut, MuStatusBadge(status: MuStatus.pending, label: l10n.aVerifier, size: MuBadgeSize.s)),
              ],
            ),
          ),
        ),
        const SizedBox(height: MuSpace.s4),
        summary,
        const SizedBox(height: MuSpace.s6),
        Semantics(header: true, child: Text(l10n.ceQuiSePasseMaintenant, style: MuType.h3.copyWith(color: c.text))),
        const SizedBox(height: MuSpace.s2),
        step(1, l10n.verifieLeStatut, l10n.onDemandeAStripeSi(formatDT(amount))),
        step(2, l10n.siElleEstPassee, l10n.tuRecoisTaConfirmationEt),
        step(3, l10n.sinonReessaie, l10n.unSeulPaiementSeraDebite),
        const SizedBox(height: MuSpace.s3),
        Row(
          children: [
            Icon(PhosphorIcons.hourglassMedium(), size: MuSize.iconXs, color: c.textSecondary),
            const SizedBox(width: MuSpace.s1),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: l10n.taPlaceEstGardeeJusqu),
                TextSpan(text: formatTime(attemptAt.add(_CheckoutScreenState._hold)), style: MuType.labelS.copyWith(color: c.text)),
                const TextSpan(text: '.'),
              ]),
              style: caption,
            ),
          ],
        ),
        const SizedBox(height: MuSpace.s6),
        MuButton.primary(
          label: l10n.verifierLeStatut,
          leading: PhosphorIcons.arrowsClockwise(),
          size: MuButtonSize.xl,
          fullWidth: true,
          loading: busy,
          onPressed: busy ? null : onCheck,
        ),
        const SizedBox(height: MuSpace.s3),
        MuButton.secondary(
          label: l10n.reessayer,
          price: formatDT(amount),
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: busy ? null : onRetry,
        ),
        const SizedBox(height: MuSpace.s3),
        SecureNote(),
      ],
    );
  }
}

/// Apple Pay / Google Pay: on the inverse surface (ink in Light, white in Night match, DRK-04),
/// never the Volt primary.
class _ExpressPay extends StatelessWidget {
  const _ExpressPay({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      child: Material(
        color: c.surfaceInverse,
        borderRadius: MuRadius.smAll,
        child: InkWell(
          borderRadius: MuRadius.smAll,
          onTap: onPressed,
          child: SizedBox(
            height: MuSize.controlL,
            child: Center(child: Text(label, style: MuType.label.copyWith(color: c.textInverse))),
          ),
        ),
      ),
    );
  }
}
