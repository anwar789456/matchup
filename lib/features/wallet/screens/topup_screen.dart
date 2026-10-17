import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../home/controllers/home_providers.dart';
import '../../payments/controllers/checkout_controller.dart';
import '../../payments/data/payment_repository.dart';
import '../../payments/widgets/checkout_widgets.dart';
import '../data/wallet_repository.dart';
import '../../../l10n/l10n.dart';

/// WAL-02 · Recharger mon solde: 20 / 50 / 100 DT or another amount, the card, why top up, then
/// « Continuer » to the top-up checkout (WAL-03 = the checkout with the top-up order).
class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  num _amount = 50;
  bool _other = false;
  final _otherCtrl = TextEditingController();

  static const _presets = [20, 50, 100];
  static const _min = 10;
  static const _max = 500;

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  bool get _valid => _amount >= _min && _amount <= _max;

  void _continue() {
    final balance = ref.read(meProvider).value?.balance ?? 0;
    ref.read(checkoutRequestProvider.notifier).start(
      CheckoutRequest(
        kind: CheckoutKind.topUp,
        eyebrow: l10n.portefeuilleMatchup,
        title: l10n.rechargeDuSolde(formatDT(_amount)),
        subtitle: l10n.crediteDesLePaiementSans,
        amount: _amount,
        lineLabel: l10n.rechargeDuSolde2,
        sport: MuSport.football,
        balanceAllowed: false,
        promoAllowed: false,
        detailRows: [
          (l10n.soldeActuel, formatDT(balance), null),
          (l10n.recharge, '+${formatDT(_amount)}', null),
          (l10n.nouveauSolde, formatDT(balance + _amount), null),
        ],
        extraInfo: [
          (l10n.disponibleToutDeSuite, l10n.tonSoldePasseDeA(formatDT(balance), formatDT(balance + _amount))),
          (l10n.tonSoldeNExpirePas, l10n.ilSertPourTesParts),
          (l10n.recuParEmail, l10n.envoyeAEtDisponibleDans(ref.read(meProvider).value?.email ?? l10n.tonAdresse)),
        ],
        termsLabel: l10n.conditionsDuSoldeMatchup,
        termsSuffix: '.',
        successRoute: Routes.wallet,
        onPaid: (receipt, _) => ref.read(walletActionsProvider).topUp(_amount, receipt),
      ),
    );
    context.push(Routes.checkout);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final balance = ref.watch(meProvider).value?.balance ?? 0;
    final card = (ref.watch(paymentCardsProvider).value ?? const <PaymentCard>[]).where((x) => x.isDefault).firstOrNull;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    Widget why(IconData icon, String title, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: MuSize.controlS, height: MuSize.controlS, decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll), child: Icon(icon, size: MuSize.iconXs, color: c.text)),
          const SizedBox(width: MuSpace.s3),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: MuType.label.copyWith(color: c.text)), Text(text, style: caption)])),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(title: l10n.rechargerMonSolde, backLabel: l10n.retourAuPortefeuille, onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                Semantics(header: true, child: Text(l10n.combienVeuxTuAjouter, style: MuType.h2.copyWith(color: c.text))),
                const SizedBox(height: MuSpace.s4),
                MuCardSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: formatAmount(_amount), style: MuType.numHero.copyWith(color: c.text)),
                            TextSpan(text: ' DT', style: MuType.numL.copyWith(color: c.textSecondary)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: MuSpace.s2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.solde, style: caption),
                          Text(formatDT(balance), style: MuType.numS.copyWith(color: c.text)),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2), child: Icon(PhosphorIcons.arrowRight(), size: MuSize.iconXs, color: c.textSecondary)),
                          Text(l10n.apresRecharge, style: caption),
                          Text(formatDT(balance + _amount), style: MuType.numS.copyWith(color: c.successText)),
                        ],
                      ),
                      const SizedBox(height: MuSpace.s4),
                      Semantics(
                        label: l10n.montant,
                        child: Wrap(
                          spacing: MuSpace.s2,
                          runSpacing: MuSpace.s2,
                          children: [
                            for (final p in _presets)
                              MuChip(label: formatDT(p), kind: MuChipKind.choice, selected: !_other && _amount == p, onSelected: (_) => setState(() { _other = false; _amount = p; })),
                            MuChip(label: l10n.autreMontant, kind: MuChipKind.choice, selected: _other, onSelected: (_) => setState(() => _other = true)),
                          ],
                        ),
                      ),
                      if (_other) ...[
                        const SizedBox(height: MuSpace.s3),
                        MuTextField(
                          label: l10n.montant,
                          controller: _otherCtrl,
                          suffixText: dtUnit,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                          helper: l10n.entreEtDt(_min, _max),
                          error: _otherCtrl.text.isNotEmpty && !_valid ? l10n.entreEtDt(_min, _max) : null,
                          autofocus: true,
                          onChanged: (v) => setState(() => _amount = num.tryParse(v) ?? 0),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s5),
                Text(l10n.payerAvec, style: MuType.labelS.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s2),
                MuCardSurface(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
                  child: Row(
                    children: [
                      BrandMark(card?.mark ?? l10n.visa2),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card?.label ?? l10n.carte, style: MuType.label.copyWith(color: c.text)),
                            Text(l10n.parDefautExpire2(card?.expiry ?? ''), style: caption),
                          ],
                        ),
                      ),
                      MuButton.tertiary(label: l10n.changer, size: MuButtonSize.s, onPressed: _continue),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s6),
                Semantics(header: true, child: Text(l10n.pourquoiRecharger, style: MuType.h3.copyWith(color: c.text))),
                why(PhosphorIcons.lightning(), l10n.taPartPayeeEnUn, l10n.sansRessortirTaCarteA),
                why(PhosphorIcons.arrowUUpLeft(), l10n.remboursementsPlusRapides, l10n.ilsArriventSurTonSolde),
                why(PhosphorIcons.sealCheck(), l10n.aucunFraisDeRecharge, l10n.tuPaiesExactementLeMontant),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          MuButton.primary(label: l10n.continuer, price: formatDT(_amount), size: MuButtonSize.xl, fullWidth: true, onPressed: _valid ? _continue : null),
        ],
      ),
    );
  }
}
