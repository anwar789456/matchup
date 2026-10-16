import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// The team's backend (backend/ in this repo, served by the OVH server). Override with
/// `flutter run --dart-define=API_URL=http://localhost:3001/api` to try a module you run locally.
const apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://minolingo.online/api');

/// An error answer from the API (status code + the message of the NestJS error body).
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message, [this.data]);

  final int statusCode;
  final String message;

  /// The decoded error body (extra fields such as `essaisRestants`).
  final Object? data;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin JSON client: `get('reservation/terrains', query: {'ville': 'La Marsa'})`.
class ApiClient {
  ApiClient({http.Client? client, this.baseUrl = apiBaseUrl}) : _http = client ?? http.Client();

  final http.Client _http;
  final String baseUrl;

  static const _timeout = Duration(seconds: 15);
  static const _json = {'Content-Type': 'application/json'};

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl/$path').replace(queryParameters: query);

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send(() => _http.get(_uri(path, query)));

  Future<dynamic> post(String path, Object body) =>
      _send(() => _http.post(_uri(path), headers: _json, body: jsonEncode(body)));

  Future<dynamic> patch(String path, Object body) =>
      _send(() => _http.patch(_uri(path), headers: _json, body: jsonEncode(body)));

  Future<dynamic> delete(String path) => _send(() => _http.delete(_uri(path)));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final res = await request().timeout(_timeout);
    final body = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final message = switch (body) {
      {'message': final List<dynamic> list} => list.join(' '),
      {'message': final String text} => text,
      _ => res.reasonPhrase ?? 'Erreur ${res.statusCode}',
    };
    throw ApiException(res.statusCode, message, body);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
