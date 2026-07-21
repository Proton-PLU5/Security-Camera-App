import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NetworkUtils {
  final String baseUrl;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  static final Map<String, Future<String>> pendingTokenRequests = {};

  NetworkUtils(
    this.baseUrl
  );

  Future<String> requestToken(String cameraId) async {
    // If there's already a pending token request for this camera, return that Future
    if (pendingTokenRequests.containsKey(cameraId)) {
      return pendingTokenRequests[cameraId]!;
    }

    // Create a new token request and store it in the map
    final Future<String> tokenRequest = doRequestToken(cameraId);
    pendingTokenRequests[cameraId] = tokenRequest;

    try {
      return await tokenRequest;
    } finally {
      // Remove the completed request from the map
      pendingTokenRequests.remove(cameraId);
    }
  }

  Future<String> doRequestToken(String cameraId) async {
    final url = Uri.parse('$baseUrl/authenticate');

    final username = await storage.read(key: 'username');
    final password = await storage.read(key: 'password');

    if (username == null || password == null) {
      throw Exception('Username or password not found in secure storage.');
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) {
      throw Exception('Authentication failed. Please check your credentials.');
    }

    // Store the 'token' in secure storage
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    final token = responseData['token'];
    if (token != null) {
      await storage.write(key: 'token_$cameraId', value: token);
      return token;
    } else {
      throw Exception('Token not found in the response.');
    }
  }

  Future<http.Response> get(String endpoint, String cameraId, {bool isRetry = false}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    
    // Find the corresponding token to the Camera ID from secure storage
    final token = await storage.read(key: 'token_$cameraId');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
    
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