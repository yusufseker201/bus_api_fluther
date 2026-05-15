import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../models/bus_line.dart';
import '../models/bus_stop.dart';
import '../models/density_level.dart';
import '../models/density_report.dart';

class ApiService {
  static const _requestTimeout = Duration(seconds: 12);

  ApiService({
    http.Client? client,
    required String? Function() tokenProvider,
  })  : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider;

  final http.Client _client;
  final String? Function() _tokenProvider;

  Map<String, String> _headers({bool jsonBody = false}) {
    final headers = <String, String>{};
    if (jsonBody) headers['Content-Type'] = 'application/json';
    final token = _tokenProvider();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = '${_authSchemeFor(token)} $token';
    }
    return headers;
  }

  String _authSchemeFor(String token) {
    final configured = AppConfig.authHeaderScheme.trim();
    if (configured.isNotEmpty && configured.toLowerCase() != 'auto') {
      return configured;
    }

    final looksLikeJwt = token.split('.').length == 3;
    return looksLikeJwt ? 'Bearer' : 'Token';
  }

  Future<List<BusLine>> fetchBusLines() async {
    final url = '${AppConfig.apiBaseUrl}/bus-lines/';
    final list = await _getList(url);
    return list.whereType<Map<String, dynamic>>().map(BusLine.fromApi).toList();
  }

  Future<List<BusStop>> fetchBusStops({List<DensityReport>? reports}) async {
    final url = '${AppConfig.apiBaseUrl}/bus-stops/';
    final list = await _getList(url);

    final latestByStop = <int, DensityLevel>{};
    if (reports != null) {
      for (final report in reports) {
        latestByStop.putIfAbsent(report.busStopId, () => report.densityLevel);
      }
    }

    return list.whereType<Map<String, dynamic>>().map((json) {
      final id = (json['id'] as num).toInt();
      return BusStop.fromApi(json, currentDensity: latestByStop[id]);
    }).toList();
  }

  Future<List<DensityReport>> fetchReports() async {
    final url = '${AppConfig.apiBaseUrl}/reports/';
    final list = await _getList(url);
    final reports = list.whereType<Map<String, dynamic>>().map(DensityReport.fromApi).toList();
    reports.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    return reports;
  }

  Future<DensityReport> submitReport({
    required int busLineId,
    required int busStopId,
    required DensityLevel densityLevel,
    required double userLat,
    required double userLon,
  }) async {
    final url = '${AppConfig.apiBaseUrl}/reports/submit/';
    final payload = {
      'bus_line': busLineId,
      'bus_stop': busStopId,
      'density_level': densityLevel.apiValue,
      'user_lat': userLat,
      'user_lon': userLon,
    };

    try {
      final res = await _client
          .post(
            Uri.parse(url),
            headers: _headers(jsonBody: true),
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);
      final body = res.body.isEmpty ? null : jsonDecode(res.body);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (body is Map<String, dynamic>) {
          final detail = body['detail']?.toString();
          if (detail != null && detail.isNotEmpty) throw ApiException(detail);
          throw ApiException(body.toString());
        }
        throw ApiException('Rapor gönderilemedi (${res.statusCode}).');
      }
      if (body is! Map<String, dynamic>) {
        throw const ApiException('Sunucudan beklenmeyen yanıt alındı.');
      }
      return DensityReport.fromApi(body);
    } on TimeoutException {
      throw const ApiException(
        'Sunucu yanit vermedi. Baglantinizi kontrol edip tekrar deneyin.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(_friendlyConnectionError(url, e.message));
    } on FormatException {
      throw const ApiException('Sunucudan gelen veri okunamadi.');
    }
  }

  Future<List<dynamic>> _getList(String url) async {
    try {
      final res = await _client
          .get(Uri.parse(url), headers: _headers())
          .timeout(_requestTimeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException('Istek basarisiz (${res.statusCode}): $url');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      throw const ApiException('Sunucudan beklenmeyen yanit alindi.');
    } on TimeoutException {
      throw const ApiException(
        'Sunucu yanit vermedi. Baglantinizi kontrol edip tekrar deneyin.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(_friendlyConnectionError(url, e.message));
    } on FormatException {
      throw const ApiException('Sunucudan gelen veri okunamadi.');
    }
  }

  String _friendlyConnectionError(String url, String message) {
    final buffer = StringBuffer('Baglanti hatasi: $message');

    Uri? target;
    try {
      target = Uri.parse(url);
    } catch (_) {
      return buffer.toString();
    }

    final localApiTarget =
        (target.host == 'localhost' || target.host == '127.0.0.1') &&
        target.port == 8000;

    if (localApiTarget) {
      buffer.write(
        '\n\nAPI sunucusuna ulasilamadi: ${target.origin}${target.path}',
      );
      buffer.write(
        '\nBackend kapaliysa once su komutla calistirin: '
        'cd /home/ogrenci/Masaüstü/bus_api && ./venv/bin/python manage.py runserver 127.0.0.1:8000',
      );

      if (kIsWeb) {
        buffer.write(
          '\nWeb tarafinda backend acik oldugu halde ayni hata surerse, '
          'Django icin CORS izni vermeniz veya uygulamayi ayni origin altindan sunmaniz gerekir.',
        );
      }
    }

    return buffer.toString();
  }
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
