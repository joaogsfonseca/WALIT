import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';

class ApiService {
  // Para emulador Android: 10.0.2.2
  // Para iOS Simulator ou Web: localhost
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/auth';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/auth';
    }
    return 'http://localhost:3000/auth';
  }

  static String get walletUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/wallets';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/wallets';
    }
    return 'http://localhost:3000/wallets';
  }

  static String get userUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/users';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/users';
    }
    return 'http://localhost:3000/users';
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    debugPrint('Tentando login para: $email em $baseUrl/login');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      debugPrint('Login Status: ${response.statusCode}');
      debugPrint('Login Body: ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('Erro no Login: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    debugPrint('Tentando signup para: $email em $baseUrl/signup');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      debugPrint('Signup Status: ${response.statusCode}');
      debugPrint('Signup Body: ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('Erro no Signup: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'newPassword': newPassword}),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getWallets(String token) async {
    final response = await http.get(
      Uri.parse(walletUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to load wallets');
    }
  }

  static Future<Map<String, dynamic>> createWallet(String token, String name, String type, String currency) async {
    final response = await http.post(
      Uri.parse(walletUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'type': type,
        'currency': currency,
      }),
    );
    return _handleResponse(response);
  }

  static Future<void> deleteWallet(String token, String walletId) async {
    final response = await http.delete(
      Uri.parse('$walletUrl/$walletId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    // 204 No Content on success — no body to parse.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      throw Exception(error['error'] ?? 'Failed to delete wallet');
    }
  }

  static Future<void> leaveWallet(String token, String walletId) async {
    final response = await http.post(
      Uri.parse('$walletUrl/$walletId/leave'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      throw Exception(error['error'] ?? 'Failed to leave wallet');
    }
  }

  static Future<Map<String, dynamic>> inviteUser(String token, String walletId, String email) async {
    final response = await http.post(
      Uri.parse('$walletUrl/$walletId/invite'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'email': email}),
    );
    // 201 Created or 200 OK
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$userUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    debugPrint('Verifying email: $email with code: $code');
    final response = await http.post(
      Uri.parse('$baseUrl/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
     return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> resendVerification(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/refresh-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
     if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
       // If refresh fails (for any reason like expired/revoked), we throw.
       // The caller (AuthProvider) should handle this by logging out the user.
       throw Exception('Failed to refresh token');
    }
  }

  static Future<void> logout(String? refreshToken) async {
    // We try to notify server, but even if it fails, client logs out.
    if (refreshToken == null) return;
    try {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
    } catch (e) {
      // Ignore network errors on logout
      debugPrint("Logout error: $e");
    }
  }

  static Future<Map<String, dynamic>> updateSettings(String token, {String? theme, String? language}) async {
    final response = await http.put(
      Uri.parse('$userUrl/settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (theme != null) 'theme': theme,
        if (language != null) 'language': language,
      }),
    );
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro desconhecido');
    }
  }
}
