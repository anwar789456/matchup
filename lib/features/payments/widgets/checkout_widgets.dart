import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/payment_repository.dart';
import '../../../l10n/l10n.dart';

/// The hatched « MODE TEST · carte 4242 4242 4242 4242 » ribbon, debug builds only.
class TestRibbon extends StatelessWidget {
  const TestRibbon({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final c = context.mu;
    return CustomPaint(
      painter: _HatchPainter(c.warning, c.warningSoft),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MuSpace.s1 + 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.flask(), size: MuSize.iconXs, color: c.text),
            const SizedBox(width: MuSpace.s1),
            Text(l10n.modeTest, style: MuType.overline.copyWith(color: c.text)),
            Text(l10n.carte2, style: MuType.caption.copyWith(color: c.text)),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text('4242 4242 4242 4242', style: MuType.numXs.copyWith(color: c.text)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter(this.stripe, this.ground);

  final Color stripe;
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = 6;
    for (var x = -size.height; x < size.width + size.height; x += 18) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - 150, 0, 300, size.height),
      Paint()..color = ground.withValues(alpha: 0.92),
    );
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.stripe != stripe;
}

/// A saved card row: brand mark, « Visa •••• 4242 », « Expire 08/27 » and the radio.
class CardRow extends StatelessWidget {
  const CardRow({
    super.key,
    required this.card,
    required this.selected,
    required this.onTap,
    this.note,
    this.noteError = false,
  });

  final PaymentCard card;
  final bool selected;
  final VoidCallback onTap;

  /// Replaces the expiry: « Refusée à 18h02 · fonds insuffisants ».
  final String? note;
  final bool noteError;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final warn = card.expiresSoon;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: '${card.label}, ${note ?? 'expire ${card.expiry}'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
          child: Row(
            children: [
              Icon(
                selected ? PhosphorIcons.radioButton(PhosphorIconsStyle.fill) : PhosphorIcons.circle(),
                size: MuSize.iconS,
                color: selected ? c.primary : c.borderStrong,
              ),
              const SizedBox(width: MuSpace.s3),
              BrandMark(card.mark),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.label, style: MuType.label.copyWith(color: c.text)),
                    Row(
                      children: [
                        if (noteError || warn) ...[
                          Icon(
                            noteError
                                ? PhosphorIcons.xCircle(PhosphorIconsStyle.fill)
                                : PhosphorIcons.warning(PhosphorIconsStyle.fill),
                            size: MuSize.iconXs - 2,
                            color: noteError ? c.errorText : c.warningText,
                          ),
                          const SizedBox(width: MuSpace.s1),
                        ],
                        Flexible(
                          child: Text(
                            note ??
                                (warn
                                    ? l10n.expireLeMoisProchain(card.expiry)
                                    : l10n.expire(card.expiry)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MuType.caption.copyWith(
                              color: noteError
                                  ? c.errorText
                                  : warn
                                  ? c.warningText
                                  : c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (card.isDefault) ...[
                const SizedBox(width: MuSpace.s2),
                MuStatusBadge(status: MuStatus.neutral, label: l10n.parDefaut, size: MuBadgeSize.s),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// « VISA » / « MC » in a bordered box.
class BrandMark extends StatelessWidget {
  const BrandMark(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      width: 44,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: MuRadius.xsAll,
        border: Border.all(color: c.borderStrong),
      ),
      child: Text(text, style: MuType.overline.copyWith(color: c.text)),
    );
  }
}

/// The lines of the total: « Ta part · 1 joueur sur 10 · 15 DT », « Frais de service · Offerts »,
/// « Total à payer · 15 DT ».
class TotalCard extends StatelessWidget {
  TotalCard({
    super.key,
    required this.lineLabel,
    required this.amount,
    required this.total,
    this.discountLabel,
    this.discount,
    String? feeLabel,
    this.note,
  }) : feeLabel = feeLabel ?? l10n.fraisDeService;

  final String lineLabel;
  final num amount;
  final num total;
  final String? discountLabel;
  final num? discount;
  final String feeLabel;

  /// « Débité de ton solde MatchUp · il te restera 15 DT ».
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    Widget line(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s1),
      child: Row(
        children: [
          Expanded(child: Text(label, style: MuType.body.copyWith(color: c.textSecondary))),
          value,
        ],
      ),
    );
    return Semantics(
      label: l10n.total,
      child: Container(
        padding: const EdgeInsets.all(MuSpace.s4),
        decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            line(lineLabel, Text(formatDT(amount), style: MuType.numS.copyWith(color: c.text))),
            if (discount != null)
              line(
                discountLabel ?? l10n.reduction,
                Text('−${formatDT(discount!)}', style: MuType.numS.copyWith(color: c.successText)),
              ),
            line(feeLabel, Text(l10n.offerts, style: MuType.label.copyWith(color: c.successText))),
            const SizedBox(height: MuSpace.s2),
            Divider(height: 1, thickness: 1, color: c.border),
            const SizedBox(height: MuSpace.s2),
            Row(
              children: [
                Expanded(child: Text(l10n.totalAPayer, style: MuType.labelL.copyWith(color: c.text))),
                Text(formatDT(total), style: MuType.numXl.copyWith(color: c.text)),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: MuSpace.s2),
              Row(
                children: [
                  Icon(PhosphorIcons.wallet(), size: MuSize.iconXs, color: c.textSecondary),
                  const SizedBox(width: MuSpace.s1),
                  Expanded(
                    child: Text(note!, style: MuType.caption.copyWith(color: c.textSecondary)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// « Si tu annules » with the three tiers.
class PolicyCard extends StatelessWidget {
  const PolicyCard({super.key, required this.freeUntil, required this.halfUntil, required this.venue});

  final DateTime freeUntil;
  final DateTime halfUntil;
  final String venue;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    Widget tier(IconData icon, Color color, String title, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: MuSize.iconXs, color: color),
        const SizedBox(width: MuSpace.s2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: MuType.label.copyWith(color: c.text)),
              Text(text, style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      ],
    );
    Widget bar(Color color, int flex) => Expanded(
      flex: flex,
      child: Container(
        height: MuSpace.s1,
        decoration: BoxDecoration(color: color, borderRadius: MuRadius.fullAll),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(l10n.siTuAnnules, style: MuType.h3.copyWith(color: c.text)),
              ),
            ),
            Text(l10n.politique(elideDe(venue)), style: MuType.caption.copyWith(color: c.textSecondary)),
          ],
        ),
        const SizedBox(height: MuSpace.s3),
        MuCardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  bar(c.success, 13),
                  const SizedBox(width: MuSpace.s1),
                  bar(c.warning, 10),
                  const SizedBox(width: MuSpace.s1),
                  bar(c.error, 10),
                ],
              ),
              const SizedBox(height: MuSpace.s4),
              tier(
                PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                c.success,
                l10n.gratuiteJusquAu(formatDateTime(freeUntil)),
                l10n.rembourseSurTonSoldeMatchup2,
              ),
              const SizedBox(height: MuSpace.s3),
              tier(
                PhosphorIcons.clock(PhosphorIconsStyle.fill),
                c.warning,
                l10n.jusquAu(formatDateTime(halfUntil)),
                l10n.entreHEtHAvant2,
              ),
              const SizedBox(height: MuSpace.s3),
              tier(
                PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
                c.error,
                l10n.nonRemboursableEnsuite,
                l10n.saufSiAnnuleToutEst(venue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// « Paiement sécurisé par Stripe » under the pay button.
class SecureNote extends StatelessWidget {
  SecureNote({super.key, String? text}) : text = text ?? l10n.paiementSecuriseParStripe;

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(PhosphorIcons.lockSimple(), size: MuSize.iconXs, color: c.textSecondary),
        const SizedBox(width: MuSpace.s1),
        Text(text, style: MuType.caption.copyWith(color: c.textSecondary)),
      ],
    );
  }
}

/// The new card form inside the dashed « Zone sécurisée Stripe · Payment Element » box: it will
/// later host `flutter_stripe`'s `CardFormField` (design/payments/STRIPE-APPEARANCE.md); until
/// then our own fields validate like the designs (PAY-04).
class CardInputZone extends StatelessWidget {
  const CardInputZone({
    super.key,
    required this.name,
    required this.number,
    required this.expiry,
    required this.cvc,
    required this.country,
    required this.onCountry,
    this.errors = const {},
  });

  final TextEditingController name;
  final TextEditingController number;
  final TextEditingController expiry;
  final TextEditingController cvc;
  final String country;
  final ValueChanged<String?> onCountry;

  /// Field key → message (« number », « expiry », « cvc »).
  final Map<String, String> errors;

  static final countries = [l10n.tunisie, l10n.france, l10n.algerie, l10n.maroc, l10n.italie];

  /// Luhn check on the digits.
  static bool luhn(String digits) {
    var sum = 0;
    var alt = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return digits.length >= 13 && sum % 10 == 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuTextField(
          label: l10n.nomSurLaCarte,
          controller: name,
          helper: l10n.telQuIlEstEcrit,
          textCapitalization: TextCapitalization.characters,
          autofillHints: const [AutofillHints.creditCardName],
        ),
        const SizedBox(height: MuSpace.s4),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.only(top: MuSpace.s3),
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s6, MuSpace.s4, MuSpace.s4),
              decoration: BoxDecoration(
                borderRadius: MuRadius.mdAll,
                border: Border.all(color: c.borderStrong, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.cartesAcceptees,
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                      ),
                      BrandMark(l10n.visa2),
                      const SizedBox(width: MuSpace.s1),
                      const BrandMark('MC'),
                    ],
                  ),
                  const SizedBox(height: MuSpace.s4),
                  MuTextField(
                    label: l10n.numeroDeCarte,
                    controller: number,
                    leadingIcon: PhosphorIcons.creditCard(),
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      const _GroupFormatter(4),
                    ],
                    error: errors['number'],
                    autofillHints: const [AutofillHints.creditCardNumber],
                  ),
                  const SizedBox(height: MuSpace.s4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: MuTextField(
                          label: l10n.expiration,
                          controller: expiry,
                          placeholder: l10n.mmAa,
                          keyboardType: TextInputType.number,
                          textDirection: TextDirection.ltr,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            const _ExpiryFormatter(),
                          ],
                          error: errors['expiry'],
                          autofillHints: const [AutofillHints.creditCardExpirationDate],
                        ),
                      ),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: MuTextField(
                          label: l10n.cvc,
                          controller: cvc,
                          helper: l10n.chiffresAuDos,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          textDirection: TextDirection.ltr,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          error: errors['cvc'],
                          autofillHints: const [AutofillHints.creditCardSecurityCode],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MuSpace.s4),
                  MuSelect<String>(
                    label: l10n.pays,
                    value: country,
                    options: [for (final k in countries) MuSelectOption(value: k, label: k)],
                    onChanged: onCountry,
                  ),
                ],
              ),
            ),
            PositionedDirectional(
              start: MuSpace.s3,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: 2),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: MuRadius.fullAll,
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.lockSimple(), size: MuSize.iconXs - 2, color: c.textSecondary),
                    const SizedBox(width: MuSpace.s1),
                    Text(
                      l10n.zoneSecuriseeStripePaymentElement,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// « 4242 4242 4242 4242 ».
class _GroupFormatter extends TextInputFormatter {
  const _GroupFormatter(this.size);

  final int size;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % size == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// « 12 / 28 ».
class _ExpiryFormatter extends TextInputFormatter {
  const _ExpiryFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final text = digits.length <= 2 ? digits : '${digits.substring(0, 2)} / ${digits.substring(2)}';
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
