import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  
  // Public getter for token to ensure validity check
  Future<String?> getValidToken() async {
    if (_token == null) return null;

    if (JwtDecoder.isExpired(_token!)) {
      // Token expired, try refreshing
      return await _tryRefreshToken();
    }
    return _token;
  }
  
  // Internal access only for UI checks vs Logic checks
  String? get token => _token;

  Future<void> loadToken() async {
    _token = await _storage.read(key: 'jwt_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
    
    // Optional: Validate token on load or just trust it until next API call
    if (_token != null && JwtDecoder.isExpired(_token!)) {
       // If loaded token is already expired, try refresh immediately
       await _tryRefreshToken();
    }
    notifyListeners();
  }
  
  Future<String?> _tryRefreshToken() async {
    if (_refreshToken == null) {
      // No refresh token available, session invalid
      await logout(); 
      return null;
    }
    
    try {
      final response = await ApiService.refreshToken(_refreshToken!);
      _token = response['token'];
      _refreshToken = response['refreshToken'];
      _user = response['user']; // Update user if returned
      
      await _storage.write(key: 'jwt_token', value: _token);
      await _storage.write(key: 'refresh_token', value: _refreshToken);
      notifyListeners();
      return _token;
    } catch (e) {
      debugPrint("Refresh failed: $e");
      await logout(); // Refresh failed (revoked/expired), force logout
      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await ApiService.login(email, password);
      _token = response['token'];
      _refreshToken = response['refreshToken'];
      _user = response['user'];

      await _storage.write(key: 'jwt_token', value: _token);
      if (_refreshToken != null) {
        await _storage.write(key: 'refresh_token', value: _refreshToken);
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    _setLoading(true);
    try {
      await ApiService.signup(name, email, password);
      // No token is set here anymore. User must verify email.
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    _setLoading(true);
    try {
      final response = await ApiService.verifyEmail(email, code);
      _token = response['token'];
      _refreshToken = response['refreshToken'];
      _user = response['user'];

      await _storage.write(key: 'jwt_token', value: _token);
      if (_refreshToken != null) {
        await _storage.write(key: 'refresh_token', value: _refreshToken);
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchProfile() async {
    // Ensure we have a valid token before fetching
    final validToken = await getValidToken();
    if (validToken == null) return;
    
    try {
      final userProfile = await ApiService.getProfile(validToken);
      _user = userProfile;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao buscar perfil: $e');
    }
  }

  Future<void> logout() async {
    // Notify backend to revoke refresh token
    if (_refreshToken != null) {
      await ApiService.logout(_refreshToken);
    }
    
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
    _token = null;
    _refreshToken = null;
    _user = null;
    notifyListeners();
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      await ApiService.forgotPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
     _setLoading(true);
    try {
      await ApiService.resetPassword(token, newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  } 

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
