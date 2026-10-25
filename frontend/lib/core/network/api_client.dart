import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String> query = const {},
  }) => _request('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) =>
      _request('PUT', path, body: body);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, String> query = const {},
    Map<String, dynamic>? body,
  }) async {
    final isTransfer = method == 'POST' && path == '/transfers';
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);

    try {
      final request = http.Request(method, uri);
      request.headers['Content-Type'] = 'application/json';

      if (body != null) {
        request.body = jsonEncode(body);
      }

      // Stock-changing requests are sent once. A timeout may follow a commit.
      final response = await (() async {
        final streamed = await _client.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(const Duration(seconds: 30));

      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = decoded['error'] as Map<String, dynamic>? ?? {};
        final fields = error['fields'] as Map<String, dynamic>? ?? {};

        throw ApiException(
          code: error['code'] as String? ?? 'REQUEST_FAILED',
          message: error['message'] as String? ?? 'Permintaan gagal diproses.',
          statusCode: response.statusCode,
          fields: fields.map((key, value) => MapEntry(key, value.toString())),
          outcomeUncertain:
              isTransfer &&
              response.statusCode >= 500 &&
              response.statusCode != 503,
        );
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        code: 'TIMEOUT',
        message: 'Waktu koneksi habis. Periksa koneksi lalu coba lagi.',
        outcomeUncertain: isTransfer,
      );
    } on http.ClientException {
      throw ApiException(
        code: 'CONNECTION_FAILED',
        message: 'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
        outcomeUncertain: isTransfer,
      );
    } on FormatException {
      throw ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Respons server tidak dapat dibaca. Silakan muat ulang.',
        outcomeUncertain: isTransfer,
      );
    }
  }

  void close() => _client.close();
}
