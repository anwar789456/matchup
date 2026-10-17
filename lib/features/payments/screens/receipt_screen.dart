import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:printing/printing.dart';

import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../../settings/data/settings_repository.dart';
import '../controllers/checkout_controller.dart';
import '../data/payment_repository.dart';
import '../data/receipt.dart';
import '../data/receipt_pdf.dart';
import '../../../l10n/l10n.dart';

/// The receipt of a checkout payment (PAY-09 « Voir le reçu »).
ReceiptEntry receiptFromPayment(CheckoutRequest req, PaymentReceipt receipt) => ReceiptEntry(
  number: receipt.number,
  label: '${req.eyebrow.split(' · ').first} · ${req.title}',
  date: receipt.paidAt,
  amount: receipt.amount,
  card: receipt.methodLabel,
  reference: req.reference,
  lines: [
    ReceiptLine(
      req.reference == null ? req.lineLabel : l10n.partDeReservation2('${req.reference}'),
      receipt.amount,
      details: [req.title, req.subtitle, if (req.reference != null) req.lineLabel],
    ),
    ReceiptLine(l10n.fraisDeService, 0, details: [l10n.offerts]),
  ],
  policy: req.policy == null
      ? null
      : l10n.gratuiteJusquAuPuisJusqu(formatDateTime(req.policy!.$1), formatDateTime(req.policy!.$2)),
);

/// SUB-09 · Reçu PDF: the A4 receipt rendered from [buildReceiptPdf], with « Partager » and
/// « Imprimer ou enregistrer » (the system print sheet saves it as a PDF).
class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.entry});

  final ReceiptEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final account = ref.watch(accountSettingsProvider);
    final client = ReceiptClient(
      name: '${account.firstName} ${account.lastName}',
      city: l10n.laMarsaTunisie,
      email: account.email,
      phone: formatPhone(account.phone),
    );
    Future<Uint8List> build() => buildReceiptPdf(entry, client);
    final file = '${entry.number}.pdf';

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(
            title: l10n.recu2(entry.number),
            onBack: () => goBack(context, Routes.wallet),
          ),
          Expanded(
            child: PdfPreview(
              build: (_) => build(),
              useActions: false,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              pdfFileName: file,
              scrollViewDecoration: BoxDecoration(color: c.surfaceMuted),
              pdfPreviewPageDecoration: BoxDecoration(
                color: c.surface,
                boxShadow: MuElevation.of(context).level2,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyActionBar(
        children: [
          Row(
            children: [
              Expanded(
                child: MuButton.secondary(
                  label: l10n.partager,
                  leading: PhosphorIcons.shareNetwork(),
                  size: MuButtonSize.l,
                  fullWidth: true,
                  onPressed: () async => Printing.sharePdf(bytes: await build(), filename: file),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: MuButton.primary(
                  label: l10n.imprimerOuEnregistrer,
                  leading: PhosphorIcons.downloadSimple(),
                  size: MuButtonSize.l,
                  fullWidth: true,
                  onPressed: () => Printing.layoutPdf(name: file, onLayout: (_) => build()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
