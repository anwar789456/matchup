import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import 'receipt.dart';

/// Who the receipt is for (SUB-09 « Client »).
class ReceiptClient {
  const ReceiptClient({
    required this.name,
    required this.city,
    required this.email,
    required this.phone,
  });

  final String name;
  final String city;
  final String email;
  final String phone;
}

/// SUB-09 · Reçu de paiement: a real A4 PDF built from a [ReceiptEntry], in the Light tokens.
Future<Uint8List> buildReceiptPdf(ReceiptEntry r, ReceiptClient client) async {
  const c = MuColors.light;
  PdfColor col(Color x) => PdfColor.fromInt(x.toARGB32());
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/google_fonts/PlusJakartaSans-Regular.ttf'),
  );
  final semi = pw.Font.ttf(
    await rootBundle.load('assets/google_fonts/PlusJakartaSans-SemiBold.ttf'),
  );
  final bold = pw.Font.ttf(await rootBundle.load('assets/google_fonts/PlusJakartaSans-Bold.ttf'));
  final numbers = pw.Font.ttf(
    await rootBundle.load('assets/google_fonts/BarlowCondensed-SemiBold.ttf'),
  );
  String? logo;
  try {
    logo = await rootBundle.loadString('assets/logo/matchup-logo-light.svg');
  } catch (_) {
    logo = null;
  }

  // The PDF fonts have no narrow no-break space: plain spaces keep « 1 490 » readable.
  String plain(String s) => s.replaceAll(' ', ' ').replaceAll(' ', ' ');
  String dt3(num v) {
    final fixed = v.toStringAsFixed(3).split('.');
    return plain('${formatInt(int.parse(fixed[0]))},${fixed[1]} DT');
  }

  String day(DateTime d) => '${formatDay(d)} ${d.year}';

  final text = col(c.text);
  final secondary = col(c.textSecondary);
  final border = col(c.border);
  pw.TextStyle st(double size, {pw.Font? font, PdfColor? color}) =>
      pw.TextStyle(font: font ?? regular, fontSize: size, color: color ?? text);
  pw.Widget overline(String s, {pw.TextAlign align = pw.TextAlign.left}) => pw.Text(
    s.toUpperCase(),
    textAlign: align,
    style: pw.TextStyle(font: semi, fontSize: 7.5, color: secondary, letterSpacing: 0.8),
  );

  final ht = r.amount / 1.19;
  final vat = r.amount - ht;

  final doc = pw.Document(title: 'Reçu ${r.number}', author: 'MatchUp');
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Ink band with the Volt end.
          pw.Row(
            children: [
              pw.Expanded(child: pw.Container(height: 6, color: col(c.ink900))),
              pw.Container(width: 120, height: 6, color: col(c.accent)),
            ],
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(44, 28, 44, 0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (logo != null)
                            pw.SvgImage(svg: logo, height: 26)
                          else
                            pw.Text('MatchUp', style: st(22, font: bold)),
                          pw.SizedBox(height: 10),
                          pw.Text('Joue. Réserve. Progresse.', style: st(8.5, color: secondary)),
                        ],
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Reçu de paiement', style: st(18, font: semi)),
                        pw.SizedBox(height: 8),
                        pw.Text('N° ${r.number}', style: st(10.5, font: semi)),
                        pw.SizedBox(height: 4),
                        pw.Text('Émis le ${day(r.date)}', style: st(8.5, color: secondary)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(color: border, thickness: 0.8),
                pw.SizedBox(height: 14),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          overline('Émis par'),
                          pw.SizedBox(height: 6),
                          pw.Text('MatchUp', style: st(8.5, font: semi)),
                          pw.Text('Tunis, Tunisie', style: st(8.5)),
                          pw.Text('contact@matchup.tn', style: st(8.5)),
                          pw.Text(
                            'Matricule fiscal : 0000000/X/A/M/000 (exemple)',
                            style: st(8, color: secondary),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          overline('Client'),
                          pw.SizedBox(height: 6),
                          pw.Text(client.name, style: st(8.5, font: semi)),
                          pw.Text(client.city, style: st(8.5)),
                          pw.Text(client.email, style: st(8.5)),
                          pw.Text(plain(client.phone), style: st(8.5)),
                        ],
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        overline('Statut', align: pw.TextAlign.right),
                        pw.SizedBox(height: 6),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: col(c.successSoft),
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          child: pw.Text(
                            'Payé',
                            style: st(9, font: semi, color: col(c.successText)),
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(day(r.date), style: st(8, color: secondary)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
                pw.Divider(color: border, thickness: 0.8),
                pw.SizedBox(height: 14),
                pw.Table(
                  columnWidths: const {
                    0: pw.FlexColumnWidth(5),
                    1: pw.FlexColumnWidth(0.8),
                    2: pw.FlexColumnWidth(1.8),
                    3: pw.FlexColumnWidth(2),
                  },
                  border: pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: border, width: 0.8),
                  ),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: col(c.surfaceMuted),
                        border: pw.Border(bottom: pw.BorderSide(color: border, width: 0.8)),
                      ),
                      children: [
                        for (final (i, h) in [
                          'Désignation',
                          'Qté',
                          'P.U. TTC',
                          'Montant TTC',
                        ].indexed)
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: overline(
                              h,
                              align: i == 0 ? pw.TextAlign.left : pw.TextAlign.right,
                            ),
                          ),
                      ],
                    ),
                    for (final l in r.lines)
                      pw.TableRow(
                        verticalAlignment: pw.TableCellVerticalAlignment.top,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(l.title, style: st(10, font: semi)),
                                for (final d in l.details)
                                  pw.Text(d, style: st(8, color: secondary)),
                              ],
                            ),
                          ),
                          for (final v in [
                            '${l.quantity}',
                            dt3(l.amount),
                            dt3(l.amount * l.quantity),
                          ])
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text(
                                v,
                                textAlign: pw.TextAlign.right,
                                style: st(10.5, font: numbers),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 14),
                pw.Row(
                  children: [
                    pw.Spacer(),
                    pw.SizedBox(
                      width: 240,
                      child: pw.Column(
                        children: [
                          for (final (label, value) in [
                            ('Total HT', dt3(ht)),
                            ('TVA incluse (19 %)', dt3(vat)),
                          ])
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: pw.Row(
                                children: [
                                  pw.Expanded(
                                    child: pw.Text(label, style: st(9, color: secondary)),
                                  ),
                                  pw.Text(value, style: st(10.5, font: numbers)),
                                ],
                              ),
                            ),
                          pw.SizedBox(height: 6),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: pw.BoxDecoration(
                              color: col(c.surfaceInverse),
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                  child: pw.Text(
                                    'Total payé',
                                    style: st(11, font: semi, color: col(c.textInverse)),
                                  ),
                                ),
                                pw.Text(
                                  dt3(r.amount),
                                  style: st(18, font: numbers, color: col(c.textInverse)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 18),
                pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: col(c.surfaceMuted),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            overline('Moyen de paiement'),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              '${r.card} · débitée le ${day(r.date)}',
                              style: st(8.5, font: semi),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Paiement sécurisé par Stripe · mode test',
                              style: st(8, color: secondary),
                            ),
                            if (r.policy != null) ...[
                              pw.SizedBox(height: 10),
                              overline('Annulation'),
                              pw.SizedBox(height: 4),
                              pw.Text(r.policy!, style: st(8, color: secondary)),
                            ],
                          ],
                        ),
                      ),
                      if (r.reference != null) ...[
                        pw.SizedBox(width: 16),
                        pw.Column(
                          children: [
                            pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data: 'https://matchup.tn/r/${r.reference}',
                              width: 76,
                              height: 76,
                              color: text,
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text('Réservation', style: st(7.5, color: secondary)),
                            pw.Text(r.reference!, style: st(7.5, color: secondary)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(44, 0, 44, 28),
            child: pw.Column(
              children: [
                pw.Divider(color: border, thickness: 0.8),
                pw.SizedBox(height: 8),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'MatchUp · Tunis, Tunisie · contact@matchup.tn',
                            style: st(7.5, color: secondary),
                          ),
                          pw.Text(
                            'Reçu généré automatiquement · données d’exemple, sans valeur fiscale.',
                            style: st(7.5, color: secondary),
                          ),
                        ],
                      ),
                    ),
                    pw.Text('Page 1/1', style: st(7.5, color: secondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  return doc.save();
}
