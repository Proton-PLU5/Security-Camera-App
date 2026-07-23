import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NetworkUtils {
  final String baseUrl;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  static final Map<String, Future<String>> pendingTokenRequests = {};
  static final Map<String, http.Client> _clients = {};

  NetworkUtils(this.baseUrl);

  http.Client _clientFor(String cameraId) =>
      _clients.putIfAbsent(cameraId, () => http.Client());

  Future<void> forgetCamera(String cameraId) async {
    _clients.remove(cameraId)?.close();
    await storage.delete(key: 'token_$cameraId');
    await storage.delete(key: 'pairing_$cameraId');
  }

  /// Called once during camera setup, while the camera is in pairing mode.
  /// Exchanges for a persistent pairing secret and stores it securely.
  /// This secret never expires (until the user re-pairs/removes the
  /// camera), and is what we use to mint session tokens later.
  Future<String> requestPairingToken(String cameraId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pair'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to pair with camera (HTTP ${response.statusCode}). '
          'Make sure the camera is in pairing mode.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secret = data['pairing_secret'] as String?;
    if (secret == null || secret.isEmpty) {
      throw Exception('Camera did not return a pairing secret.');
    }

    await storage.write(key: 'pairing_$cameraId', value: secret);
    return secret;
  }

  /// Returns a usable session token. If we already have one cached, it is
  /// returned immediately with no network round-trip. Only mints a new one
  /// (via the persistent pairing secret) if we don't have one cached yet.
  ///
  /// Use this for the "normal" case. Use [requestToken] directly only when
  /// you already know the cached token is bad (e.g. after a 401) and need
  /// to force a refresh.
  Future<String> getSessionToken(String cameraId) async {
    final cached = await storage.read(key: 'token_$cameraId');
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return requestToken(cameraId);
  }

  /// Forces a fresh session token to be minted from the persistent pairing
  /// secret and overwrites whatever was cached. Call this when a request
  /// has just failed with 401, meaning the previous session token expired.
  Future<String> requestToken(String cameraId) async {
    return pendingTokenRequests.putIfAbsent(cameraId, () async {
      try {
        return await doRequestToken(cameraId);
      } finally {
        pendingTokenRequests.remove(cameraId);
      }
    });
  }

  Future<String> doRequestToken(String cameraId) async {
    final pairingSecret = await storage.read(key: 'pairing_$cameraId') ?? '';
    if (pairingSecret.isEmpty) {
      throw Exception(
          'No pairing secret stored for this camera. Please re-pair it.');
    }

    final response = await _clientFor(cameraId).post(
      Uri.parse('$baseUrl/pair/token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $pairingSecret',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) {
      throw Exception(
          'Pairing secret was rejected by the camera. Please re-pair it.');
    }
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to obtain session token (HTTP ${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Token not found in the response.');
    }

    await storage.write(key: 'token_$cameraId', value: token);
    return token;
  }

  Future<http.Response> get(String endpoint, String cameraId,
      {bool isRetry = false}) async {
    final token = isRetry
        ? await requestToken(cameraId) // force refresh after a 401
        : await getSessionToken(cameraId); // cached token if we have one

    final response = await _clientFor(cameraId)
        .get(Uri.parse('$baseUrl$endpoint'),
            headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) {
      if (isRetry) {
        throw Exception('Reauthentication failed. Please check your credentials.');
      }
      return get(endpoint, cameraId, isRetry: true);
    }

    return response;
  }
}