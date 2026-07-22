import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NetworkUtils {
  final String baseUrl;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  static final Map<String, Future<String>> pendingTokenRequests = {};

  // Cache one pinned http.Client per camera so we don't rebuild the
  // SecurityContext/HttpClient on every request.
  static final Map<String, http.Client> _pinnedClients = {};

  NetworkUtils(this.baseUrl);

  /// Fetches the camera's self-signed certificate over an UNVERIFIED
  /// connection (trust-on-first-use) and stores it for later pinning.
  Future<void> getCertificate(String cameraId) async {
    final bootstrapClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // TODO: verify cert fingerprint against a known-good value from
        // the pairing flow before trusting it, if possible.
        return true;
      };

    try {
      final request = await bootstrapClient
          .getUrl(Uri.parse('$baseUrl/pair/cert'))
          .timeout(const Duration(seconds: 10));
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        final pem = utf8.decode(bytes);
        await storage.write(key: 'certificate_$cameraId', value: pem);

        // Drop any previously cached pinned client for this camera since
        // the trusted cert has changed.
        _pinnedClients.remove(cameraId)?.close();
      } else {
        throw Exception(
            'Failed to fetch certificate. Status code: ${response.statusCode}');
      }
    } finally {
      bootstrapClient.close();
    }
  }

  /// Reads bytes from an HttpClientResponse without pulling in dart:io's
  /// higher-level helpers that aren't exposed by default.
  Future<List<int>> consolidateHttpClientResponseBytes(
      HttpClientResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
    }
    return bytes;
  }

  /// Returns a cached pinned client for [cameraId], building one from the
  /// stored certificate if it doesn't exist yet. Throws if no certificate
  /// has been fetched/stored for this camera (call [getCertificate] first).
  Future<http.Client> _clientFor(String cameraId) async {
    final cached = _pinnedClients[cameraId];
    if (cached != null) {
      return cached;
    }

    final pem = await storage.read(key: 'certificate_$cameraId');
    if (pem == null || pem.isEmpty) {
      throw Exception(
          'No pinned certificate found for $cameraId. Call getCertificate() first.');
    }

    final context = SecurityContext(withTrustedRoots: false);
    context.setTrustedCertificatesBytes(utf8.encode(pem));

    final httpClient = HttpClient(context: context)
      // Only trust connections that chain to the pinned cert; reject
      // everything else (including real CA-signed certs from other hosts).
      ..badCertificateCallback = (cert, host, port) => false;

    final client = IOClient(httpClient);
    _pinnedClients[cameraId] = client;
    return client;
  }

  /// Call this if a camera is unpaired/removed, to free the cached client
  /// and drop the stored certificate/token.
  Future<void> forgetCamera(String cameraId) async {
    _pinnedClients.remove(cameraId)?.close();
    await storage.delete(key: 'certificate_$cameraId');
    await storage.delete(key: 'token_$cameraId');
    await storage.delete(key: cameraId);
  }

  Future<String> requestToken(String cameraId) async {
    if (pendingTokenRequests.containsKey(cameraId)) {
      return pendingTokenRequests[cameraId]!;
    }

    final Future<String> tokenRequest = doRequestToken(cameraId);
    pendingTokenRequests[cameraId] = tokenRequest;

    try {
      return await tokenRequest;
    } finally {
      pendingTokenRequests.remove(cameraId);
    }
  }

  Future<String> doRequestToken(String cameraId) async {
    final client = await _clientFor(cameraId);
    final url = Uri.parse('$baseUrl/pair/token');
    final pairingToken = await storage.read(key: cameraId) ?? '';

    if (pairingToken.isEmpty) {
      throw Exception('Pairing token is empty. Please provide a valid pairing token.');
    }

    final response = await client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $pairingToken',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) {
      throw Exception('Authentication failed. Please check your credentials.');
    }

    final Map<String, dynamic> responseData = jsonDecode(response.body);
    final token = responseData['token'];
    if (token != null) {
      await storage.write(key: 'token_$cameraId', value: token);
      return token;
    } else {
      throw Exception('Token not found in the response.');
    }
  }

  /// Note: this call happens BEFORE a certificate is necessarily pinned
  /// (pairing mode), so it intentionally uses the plain `http` package.
  /// It only succeeds if the server's cert is otherwise trusted (or if
  /// you've already pinned it via getCertificate for this baseUrl/camera).
  /// If pairing happens over an untrusted TLS cert too, route this through
  /// the same bootstrap HttpClient pattern used in getCertificate().
  Future<String> requestPairingToken(String cameraId) async {
    String url = '$baseUrl/pair';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      await storage.write(key: cameraId, value: responseData['token']);
      return responseData['token'];
    } else {
      throw Exception('Failed to request pairing token.');
    }
  }

  Future<http.Response> get(String endpoint, String cameraId, {bool isRetry = false}) async {
    final client = await _clientFor(cameraId);
    final url = Uri.parse('$baseUrl$endpoint');

    final token = await storage.read(key: 'token_$cameraId');
    final response = await client
        .get(url, headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) {
      // Token has expired or is invalid, request reauthentication
      await requestToken(cameraId);

      // Retry the request with the new token
      if (!isRetry) {
        return get(endpoint, cameraId, isRetry: true);
      } else {
        throw Exception('Reauthentication failed. Please check your credentials.');
      }
    }

    return response;
  }
}