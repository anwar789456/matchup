import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/format.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../l10n/l10n.dart';
import '../../settings/data/settings_repository.dart';
import 'receipt.dart';
import 'receipt_pdf.dart';

/// Payment emails (EML-05 receipt, EML-07 Premium, refund done), sent by the `send-email`
/// Supabase Edge Function over the team's SMTP account. CLAUDE.md rule 11: the templates live on
/// the server; the app only says which email and with what data, and attaches the receipt PDF.
///
/// Never blocks a screen and never fails one: without Supabase, or offline, nothing is sent.
abstract interface class Mailer {
  Future<void> receipt(ReceiptEntry r);
  /// [invoiceUrl]: Stripe's PDF of the invoice, behind the email's « Voir le reçu ».
  Future<void> premiumRenewed(ReceiptEntry r, {DateTime? next, String? invoiceUrl});
  Future<void> refund({required String number, required String label, required num amount, required bool toCard, required String card});
}

class SupabaseMailer implements Mailer {
  SupabaseMailer(this._ref);

  final Ref _ref;

  Future<void> _send(String template, Map<String, Object?> data, {ReceiptEntry? pdf}) async {
    if (!SupabaseConfig.configured || !await SupabaseConfig.ensureSession()) return;
    try {
      Map<String, Object?>? attachment;
      if (pdf != null) {
        final account = _ref.read(accountSettingsProvider);
        final bytes = await buildReceiptPdf(
          pdf,
          ReceiptClient(
            name: '${account.firstName} ${account.lastName}',
            city: l10n.laMarsaTunisie,
            email: account.email,
            phone: formatPhone(account.phone),
          ),
        );
        attachment = {'filename': '${pdf.number}.pdf', 'base64': base64Encode(bytes)};
      }
      final res = await Supabase.instance.client.functions.invoke(
        'send-email',
        body: {'template': template, 'data': data, 'attachment': ?attachment},
      );
      if (res.data is Map && (res.data as Map)['error'] != null) debugPrint('Email non envoyé : ${(res.data as Map)['error']}');
    } catch (e) {
      debugPrint('Email non envoyé : $e');
    }
  }

  @override
  Future<void> receipt(ReceiptEntry r) => _send('receipt', {
    'number': r.number,
    'label': r.label,
    'amount': r.amount,
    'card': r.card,
    'date': formatDateTime(r.date),
  }, pdf: r);

  @override
  Future<void> premiumRenewed(ReceiptEntry r, {DateTime? next, String? invoiceUrl}) => _send('premium_renewed', {
    'number': r.number,
    'amount': r.amount,
    'card': r.card,
    'date': formatDay(r.date),
    'next': next == null ? null : formatDay(next),
    'url': invoiceUrl,
  }, pdf: r);

  @override
  Future<void> refund({required String number, required String label, required num amount, required bool toCard, required String card}) =>
      _send('refund', {'number': number, 'label': label, 'amount': amount, 'target': toCard ? 'card' : 'balance', 'card': card});
}

final mailerProvider = Provider<Mailer>(SupabaseMailer.new);
