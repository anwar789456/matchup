import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../connectivity.dart';

/// The MatchUp backend, given at build time:
/// `flutter run --dart-define=API_URL=http://localhost:3001/api/utilisateur`.
/// Empty (the default, and in tests): the app keeps everything on the phone.
const apiUrl = String.fromEnvironment('API_URL');

/// The server answered 4xx: [status] and the decoded JSON [body] (`message`, `essaisRestants`…).
class ApiError implements Exception {
  const ApiError(this.status, this.body);

  final int status;
  final Map<String, Object?> body;

  @override
  String toString() => 'ApiError($status, $body)';
}

/// JSON over HTTP to one module of the backend. No connection or a timeout throws
/// [OfflineException]; a 5xx throws [ServerException]; any other non-2xx throws [ApiError].
class ApiClient {
  ApiClient(this.baseUrl, {http.Client? client}) : _http = client ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  static const timeout = Duration(seconds: 20);

  Future<Map<String, Object?>> post(String path, Map<String, Object?> body) => _send(
        () => _http.post(
          Uri.parse('$baseUrl$path'),
          headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode(body),
        ),
      );

  Future<Map<String, Object?>> _send(Future<http.Response> Function() request) async {
    final http.Response res;
    try {
      res = await request().timeout(timeout);
    } on TimeoutException {
      throw const OfflineException();
    } on http.ClientException {
      throw const OfflineException();
    }
    final body = _decode(res.body);
    if (res.statusCode >= 500) throw ServerException(status: res.statusCode, reference: 'HTTP ${res.statusCode}');
    if (res.statusCode >= 400) throw ApiError(res.statusCode, body);
    return body;
  }

  static Map<String, Object?> _decode(String text) {
    if (text.isEmpty) return const {};
    try {
      final value = jsonDecode(text);
      return value is Map<String, Object?> ? value : {'data': value};
    } on FormatException {
      return {'message': text};
    }
  }
}

/// Null when [apiUrl] is empty.
final apiClientProvider = Provider<ApiClient?>((ref) => apiUrl.isEmpty ? null : ApiClient(apiUrl));
