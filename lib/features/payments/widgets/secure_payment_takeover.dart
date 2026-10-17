import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';

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
      title: 'Paiement sécurisé',
      body: ListView(
        padding: const EdgeInsets.all(MuSpace.s4),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.lockSimple(), size: MuSize.iconXs, color: c.textSecondary),
              const SizedBox(width: MuSpace.s1),
              Text('Paiement sécurisé par Stripe', style: caption),
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
                      Text('MatchUp', style: MuType.label.copyWith(color: c.text)),
                      Text('Ta part · ${widget.cardLabel}', style: caption),
                    ],
                  ),
                ),
                Text(formatDT(widget.amount), style: MuType.numL.copyWith(color: c.text)),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s4),
          Text('Fenêtre de ta banque', style: MuType.labelS.copyWith(color: c.textSecondary)),
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
                          Text('Ta banque', style: MuType.labelL.copyWith(color: c.text)),
                          Text('Paiement en ligne sécurisé', style: caption),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s4),
                Text('Confirme ce paiement', style: MuType.h3.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s2),
                row('Marchand', 'MATCHUP'),
                row('Montant', '${formatAmount(widget.amount)},000 TND'.replaceAll(',000,000', ',000')),
                row('Carte', widget.cardLabel.toUpperCase()),
                const SizedBox(height: MuSpace.s3),
                Text('Code envoyé par SMS au ${widget.phone}', style: caption),
                const SizedBox(height: MuSpace.s2),
                MuTextField(
                  label: 'Code',
                  hideLabel: true,
                  controller: _code,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: MuSpace.s3),
                MuButton.primary(
                  label: 'Valider',
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: MuSpace.s2),
                MuButton.tertiary(
                  label: 'Annuler',
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(height: MuSpace.s2),
                Text(
                  'Service client de ta banque · 24 h/24',
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
                    'Ne ferme pas cette page. Tu reviendras automatiquement sur MatchUp. Pour '
                    'annuler, utilise « Annuler » dans la fenêtre de ta banque : rien ne sera débité.',
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
