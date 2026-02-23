import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:untitled1/features/orders/domain/models.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WaiterApiClient {
  WaiterApiClient({required this.baseUrl}) {
    debugPrint('[API] baseUrl=${_normalizedBase()}');
  }

  final String baseUrl;

  Future<List<MenuProduct>> getMenu() async {
    final json = await _request('GET', '/api/menu');
    if (json is! List<dynamic>) {
      throw const ApiException('Invalid menu response');
    }

    return json
        .whereType<Map<String, dynamic>>()
        .map(MenuProduct.fromApiJson)
        .where((item) => item != null)
        .cast<MenuProduct>()
        .toList();
  }

  Future<List<ApiOrderSummary>> getOrders() async {
    final json = await _request('GET', '/api/orders');
    if (json is! List<dynamic>) {
      throw const ApiException('Invalid orders response');
    }

    return json
        .whereType<Map<String, dynamic>>()
        .map(ApiOrderSummary.fromJson)
        .toList();
  }

  Future<void> createOrder({
    required String tableNumber,
    required List<OrderLine> lines,
    String? waiterName,
    bool isExtra = false,
    String? parentId,
  }) async {
    final payload = <String, dynamic>{
      'tableNumber': tableNumber,
      'items': lines
          .map(
            (line) => <String, dynamic>{
              'id': line.product.id,
              'name': line.product.name,
              'quantity': line.quantity,
              'category': line.product.category,
              'itemStatus': 'pending',
              'extraNotes': line.note,
            },
          )
          .toList(),
    };

    final waiter = waiterName?.trim();
    if (waiter != null && waiter.isNotEmpty) {
      payload['waiterName'] = waiter;
    }

    if (isExtra) {
      payload['isExtra'] = true;
      if (parentId != null && parentId.isNotEmpty) {
        payload['parentId'] = parentId;
      }
    }

    await _request('POST', '/api/orders', body: payload);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(_normalizedBase()).replace(path: path);
    final client = HttpClient();

    try {
      final request = await client.openUrl(method, uri);
      request.headers.contentType = ContentType.json;
      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final raw = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'API ${response.statusCode}: ${raw.isEmpty ? 'Request failed' : raw}',
        );
      }

      if (raw.isEmpty) {
        return null;
      }
      return jsonDecode(raw);
    } on SocketException {
      throw const ApiException('Could not connect to server');
    } on FormatException {
      throw const ApiException('Invalid JSON response');
    } finally {
      client.close(force: true);
    }
  }

  String _normalizedBase() {
    if (baseUrl.endsWith('/')) {
      return baseUrl.substring(0, baseUrl.length - 1);
    }
    return baseUrl;
  }
}
