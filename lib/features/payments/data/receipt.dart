import 'package:flutter/foundation.dart';

/// A payment receipt: the SUB-04 list and the A4 PDF (SUB-09).
@immutable
class ReceiptEntry {
  const ReceiptEntry({
    required this.number,
    required this.label,
    required this.date,
    required this.amount,
    required this.card,
    required this.lines,
    this.reference,
    this.policy,
  });

  /// « MU-R-2026-01482 ».
  final String number;

  /// « Part Arena Five · MU-48213 ».
  final String label;
  final DateTime date;
  final num amount;
  final String card;

  /// (designation, detail lines, quantity, unit price) of the receipt table.
  final List<ReceiptLine> lines;
  final String? reference;

  /// « Gratuite jusqu’au … Remboursement sur le solde MatchUp. ».
  final String? policy;
}

@immutable
class ReceiptLine {
  const ReceiptLine(this.title, this.amount, {this.details = const [], this.quantity = 1});

  final String title;
  final List<String> details;
  final int quantity;
  final num amount;
}
