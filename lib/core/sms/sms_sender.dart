import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// The textbee.dev key, given at build time so it never lands in git:
/// `flutter run --dart-define=TEXTBEE_API_KEY=txb_…`.
const textbeeApiKey = String.fromEnvironment('TEXTBEE_API_KEY');

/// The SMS could not be sent (network or textbee refused it).
class SmsNotSent implements Exception {
  const SmsNotSent(this.reason);
  final String reason;

  @override
  String toString() => 'SmsNotSent: $reason';
}

/// Sends the codes by SMS (AUTH-02, AUTH-06).
abstract interface class SmsSender {
  /// False without a key: no SMS leaves the phone and every code is `123456`.
  bool get live;

  /// [to] in international format, « +21698123456 ». Throws [SmsNotSent].
  Future<void> send(String to, String message);
}

/// textbee.dev: the team's Android phone (the account's default device) sends the SMS from its
/// SIM. https://textbee.dev/docs/api-reference
class TextbeeSmsSender implements SmsSender {
  TextbeeSmsSender({required this.apiKey, http.Client? client}) : _http = client ?? http.Client();

  final String apiKey;
  final http.Client _http;

  static final endpoint = Uri.parse('https://api.textbee.dev/api/v1/gateway/send-sms');

  @override
  bool get live => apiKey.isNotEmpty;

  @override
  Future<void> send(String to, String message) async {
    if (!live) {
      debugPrint('SMS simulé à $to : $message');
      return;
    }
    final http.Response res;
    try {
      res = await _http
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
            body: jsonEncode({
              'recipients': [to],
              'message': message,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on Object catch (e) {
      throw SmsNotSent('$e');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw SmsNotSent('textbee ${res.statusCode}: ${res.body}');
    }
  }
}

final smsSenderProvider = Provider<SmsSender>((ref) => TextbeeSmsSender(apiKey: textbeeApiKey));
