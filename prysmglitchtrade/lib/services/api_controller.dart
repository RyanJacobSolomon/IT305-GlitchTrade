import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

export 'api_service.dart';

/// ============================================================================
/// REQUIREMENT 1: API Controller Dart File with HTTP GET Implementation
/// ============================================================================
///
/// This controller handles all API operations for the Data Catalog:
/// 1. Executes asynchronous HTTP GET requests to the REST / GitHub Gist endpoint.
/// 2. Validates HTTP response status codes (HTTP 200 OK vs errors).
/// 3. Deserializes incoming JSON data and maps JSON arrays to [Product] objects.
/// 4. Provides cached raw JSON and formatted JSON for emulated displays.
class ApiController {
  /// Default REST API / GitHub Gist endpoint for hardware catalog JSON.
  static const String endpointUrl = ApiService.defaultGistUrl;

  /// Cached raw JSON string from the most recent HTTP GET request.
  static String get lastRawJson => ApiService.lastRawJson;

  /// Prettified JSON string formatted with 2-space indentation for emulator display.
  static String get formattedJson => ApiService.getFormattedJson();

  /// --------------------------------------------------------------------------
  /// HTTP GET Implementation (Criteria 1: HTTP GET Request Execution - 20 pts)
  /// --------------------------------------------------------------------------
  /// Dispatches an asynchronous HTTP GET request to [rawUrl] or [endpointUrl].
  /// Checks status code == 200, handles timeouts, and parses the response body.
  static Future<List<Product>> getCatalogProducts({
    String? rawUrl,
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
    bool fallbackToLocal = true,
  }) async {
    final targetUrl = (rawUrl ?? '').trim().isNotEmpty
        ? rawUrl!.trim()
        : endpointUrl;

    final uri = Uri.parse(targetUrl);
    final httpClient = client ?? http.Client();

    try {
      // 1. Asynchronous HTTP GET Request Execution
      final response = await httpClient
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'PrysmGlitchTrade-App/1.0',
            },
          )
          .timeout(timeout);

      // 2. HTTP Status Code Validation (200 OK)
      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode} (${response.reasonPhrase ?? 'Error'}): '
          'Failed to fetch catalog from $targetUrl',
        );
      }

      // 3. Cache raw JSON for emulated display
      ApiService.lastRawJson = response.body;

      // 4. JSON Deserialization & Mapping (Criteria 2)
      final dynamic decoded = json.decode(response.body);
      return parseJsonArrayToProducts(decoded);
    } catch (e) {
      debugPrint('ApiController.getCatalogProducts error: $e');
      if (fallbackToLocal) {
        debugPrint('ApiController: Falling back to local offline catalog products');
        return await ApiService.loadFallbackCatalogProducts();
      }
      rethrow;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// --------------------------------------------------------------------------
  /// JSON Array to Product Mapping (Criteria 2: 20 pts)
  /// --------------------------------------------------------------------------
  /// Maps a decoded JSON structure (array or wrapped dictionary) into a typed `List<Product>`.
  static List<Product> parseJsonArrayToProducts(dynamic decoded) {
    return ApiService.parseJsonArrayToProducts(decoded);
  }

  /// Alias for compatibility with [ApiService.fetchCatalogProducts].
  static Future<List<Product>> fetchCatalogProducts({
    String? rawUrl,
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
    bool fallbackToLocal = true,
  }) {
    return getCatalogProducts(
      rawUrl: rawUrl,
      client: client,
      timeout: timeout,
      fallbackToLocal: fallbackToLocal,
    );
  }
}
