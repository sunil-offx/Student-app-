// lib/core/providers/auth_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Could check stored token validity here
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> login(String username, String password, String role) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      if (!_api.isConfigured) {
        throw StateError(
          'Connect the app to your deployed backend before signing in.',
        );
      }
      final response = await _api.post(ApiConstants.login, data: {
        'username': username,
        'password': password,
        'role': role,
      });
      await _api.saveTokens(response['access_token'], response['refresh_token']);
      _user = UserModel.fromJson(response['user']);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStudentProfile({
    required String fullName,
    required String registerNumber,
    required String phoneNumber,
    required String email,
    required String dateOfBirth,
  }) async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final response = await _api.put('/student/profile', data: {
        'full_name': fullName,
        'register_number': registerNumber,
        'phone_number': phoneNumber,
        'email': email,
        'date_of_birth': dateOfBirth,
      });

      if (response['user'] != null) {
        _user = UserModel.fromJson(response['user']);
      } else if (_user != null) {
        _user = _user!.copyWith(
          fullName: fullName,
          registerNumber: registerNumber,
          phoneNumber: phoneNumber,
          email: email,
          dateOfBirth: dateOfBirth,
        );
      }
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiConstants.logout);
    } catch (_) {}
    await _api.clearTokens();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    if (e is StateError || e is FormatException) {
      return e.toString().replaceFirst('Bad state: ', '');
    }
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) {
        return data['detail'] as String;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'The backend took too long to respond. Please try again.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Cannot reach the backend. Check the server URL and internet connection.';
      }
    }
    if (e.toString().contains('401')) return 'Invalid username or password';
    if (e.toString().contains('403')) return 'Access denied for this role';
    return e.toString();
  }
}
