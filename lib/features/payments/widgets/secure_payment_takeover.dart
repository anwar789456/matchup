import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../../l10n/l10n.dart';

/// PAY-07 · 3-D Secure: our frame around the bank's window — no X, « Paiement sécurisé par
/// Stripe », the summary, the dashed « Fenêtre de ta banque » with a fake SMS code form, and the
/// « Ne ferme pas cette page » strip. Resolves true when the bank approves.
Future<bool> showSecurePaymentTakeover(
  BuildContext context, {
  required num amount,
  required String cardLabel,
  required String phone,
}) async {
  final result = await MuTakeover.show<bool>(
    context,
    closable: false,
    builder: (ctx) => _SecurePayment(amount: amount, cardLabel: cardLabel, phone: phone),
  );
  return result ?? false;
}

class _SecurePayment extends StatefulWidget {
  const _SecurePayment({required this.amount, required this.cardLabel, required this.phone});

  final num amount;
  final String cardLabel;
  final String phone;

  @override
  State<_SecurePayment> createState() => _SecurePaymentState();
}

class _SecurePaymentState extends State<_SecurePayment> {
  final _code = TextEditingController(text: '482');

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
      child: Row(
        children: [
          Expanded(child: Text(label, style: caption)),
          Text(value, style: MuType.label.copyWith(color: c.text)),
        ],
      ),
    );
    return MuTakeover(
      closable: false,
      title: l10n.paiementSecurise,
      body: ListView(
        padding: const EdgeInsets.all(MuSpace.s4),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.lockSimple(), size: MuSize.iconXs, color: c.textSecondary),
              const SizedBox(width: MuSpace.s1),
              Text(l10n.paiementSecuriseParStripe, style: caption),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          MuCardSurface(
            padding: const EdgeInsets.all(MuSpace.s3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.matchup, style: MuType.label.copyWith(color: c.text)),
                      Text(l10n.taPart2(widget.cardLabel), style: caption),
                    ],
                  ),
                ),
                Text(formatDT(widget.amount), style: MuType.numL.copyWith(color: c.text)),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s4),
          Text(l10n.fenetreDeTaBanque, style: MuType.labelS.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s2),
          Container(
            constraints: const BoxConstraints(minHeight: 240),
            padding: const EdgeInsets.all(MuSpace.s4),
            decoration: BoxDecoration(
              borderRadius: MuRadius.mdAll,
              border: Border.all(color: c.borderStrong, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIcons.bank(), size: MuSize.iconM, color: c.text),
                    const SizedBox(width: MuSpace.s2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.taBanque, style: MuType.labelL.copyWith(color: c.text)),
                          Text(l10n.paiementEnLigneSecurise, style: caption),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s4),
                Text(l10n.confirmeCePaiement, style: MuType.h3.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s2),
                row(l10n.marchand, l10n.matchup2),
                row(l10n.montant, l10n.tnd(formatAmount(widget.amount)).replaceAll(',000,000', ',000')),
                row(l10n.carte, widget.cardLabel.toUpperCase()),
                const SizedBox(height: MuSpace.s3),
                Text(l10n.codeEnvoyeParSmsAu(widget.phone), style: caption),
                const SizedBox(height: MuSpace.s2),
                MuTextField(
                  label: l10n.code,
                  hideLabel: true,
                  controller: _code,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: MuSpace.s3),
                MuButton.primary(
                  label: l10n.valider,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: MuSpace.s2),
                MuButton.tertiary(
                  label: l10n.annuler,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(height: MuSpace.s2),
                Text(
                  l10n.serviceClientDeTaBanque,
                  textAlign: TextAlign.center,
                  style: caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s4),
          Container(
            padding: const EdgeInsets.all(MuSpace.s3),
            decoration: BoxDecoration(color: c.warningSoft, borderRadius: MuRadius.smAll),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill), size: MuSize.iconXs, color: c.warningText),
                const SizedBox(width: MuSpace.s2),
                Expanded(
                  child: Text(
                    l10n.neFermePasCettePage,
                    style: MuType.caption.copyWith(color: c.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
