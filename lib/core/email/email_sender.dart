import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../l10n/l10n.dart';

/// The EmailJS settings, given at build time so they never land in git:
/// `--dart-define=EMAILJS_SERVICE_ID=… --dart-define=EMAILJS_TEMPLATE_ID=…
/// --dart-define=EMAILJS_PUBLIC_KEY=…` (and `EMAILJS_PRIVATE_KEY` when the account requires it).
const emailJsServiceId = String.fromEnvironment('EMAILJS_SERVICE_ID');
const emailJsTemplateId = String.fromEnvironment('EMAILJS_TEMPLATE_ID');
const emailJsPublicKey = String.fromEnvironment('EMAILJS_PUBLIC_KEY');
const emailJsPrivateKey = String.fromEnvironment('EMAILJS_PRIVATE_KEY');

/// The email could not be sent (network, quota, or EmailJS refused it).
class EmailNotSent implements Exception {
  const EmailNotSent(this.reason);
  final String reason;

  @override
  String toString() => 'EmailNotSent: $reason';
}

/// Why a code is emailed.
enum EmailCodePurpose {
  /// AUTH-04: confirm the address after sign-up.
  confirmation,

  /// AUTH-06: choose a new password.
  reset,
}

/// Sends the 6-digit codes by email (AUTH-04, AUTH-06). There is no server: the app calls the
/// mail service itself, and the codes are checked against the phone's database.
abstract interface class EmailSender {
  /// False without settings: no email leaves the phone and every code is `123456`.
  bool get live;

  /// Throws [EmailNotSent].
  Future<void> sendCode({required String to, required String code, required EmailCodePurpose purpose});
}

/// EmailJS (https://www.emailjs.com/docs/rest-api/send/): one template whose « To Email » is
/// `{{to_email}}`, subject `{{subject}}`, and body using `{{message}}` and `{{code}}`.
class EmailJsSender implements EmailSender {
  EmailJsSender({
    required this.serviceId,
    required this.templateId,
    required this.publicKey,
    this.privateKey = '',
    http.Client? client,
  }) : _http = client ?? http.Client();

  final String serviceId;
  final String templateId;
  final String publicKey;
  final String privateKey;
  final http.Client _http;

  static final endpoint = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

  @override
  bool get live => serviceId.isNotEmpty && templateId.isNotEmpty && publicKey.isNotEmpty;

  /// What the template receives for [purpose].
  static Map<String, String> params(String to, String code, EmailCodePurpose purpose) => {
        'to_email': to,
        'code': code,
        'subject': switch (purpose) {
          EmailCodePurpose.confirmation => l10n.emailSujetConfirmation(code),
          EmailCodePurpose.reset => l10n.emailSujetReinitialisation(code),
        },
        'message': switch (purpose) {
          EmailCodePurpose.confirmation => l10n.emailTexteConfirmation,
          EmailCodePurpose.reset => l10n.emailTexteReinitialisation,
        },
      };

  @override
  Future<void> sendCode({
    required String to,
    required String code,
    required EmailCodePurpose purpose,
  }) async {
    if (!live) {
      debugPrint('Email simulé à $to : code $code (${purpose.name})');
      return;
    }
    final http.Response res;
    try {
      res = await _http
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'service_id': serviceId,
              'template_id': templateId,
              'user_id': publicKey,
              if (privateKey.isNotEmpty) 'accessToken': privateKey,
              'template_params': params(to, code, purpose),
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on Object catch (e) {
      throw EmailNotSent('$e');
    }
    // EmailJS answers 200 « OK »; anything else carries the reason as text.
    if (res.statusCode != 200) throw EmailNotSent('EmailJS ${res.statusCode}: ${res.body}');
  }
}

final emailSenderProvider = Provider<EmailSender>(
  (ref) => EmailJsSender(
    serviceId: emailJsServiceId,
    templateId: emailJsTemplateId,
    publicKey: emailJsPublicKey,
    privateKey: emailJsPrivateKey,
  ),
);
