import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/token_storage.dart';
import '../models/user.dart';

class AuthService {
  AuthService({required ApiClient apiClient, required TokenStorage tokenStorage})
    : _apiClient = apiClient,
      _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) {
    return _issueAndStoreTokens(
      () => _apiClient.dio.post(
        '/auth/register',
        data: {'email': email, 'username': username, 'password': password},
      ),
    );
  }

  Future<void> login({required String email, required String password}) {
    return _issueAndStoreTokens(
      () => _apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      ),
    );
  }

  Future<void> loginWithGoogle(String idToken) {
    return _issueAndStoreTokens(
      () => _apiClient.dio.post('/auth/google', data: {'idToken': idToken}),
    );
  }

  Future<void> _issueAndStoreTokens(
    Future<Response> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data as Map<String, dynamic>;
      await _tokenStorage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AppUser> fetchCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AppUser> updateProfile({String? fullName, String? username}) async {
    try {
      final response = await _apiClient.dio.patch(
        '/users/me',
        data: {
          'fullName': ?fullName,
          'username': ?username,
        },
      );
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken != null) {
      try {
        await _apiClient.dio.post(
          '/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      } on DioException {
        // Best-effort — local tokens are cleared below regardless, so the
        // device always ends up logged out even if the server call fails.
      }
    }
    await _tokenStorage.clear();
  }

  Future<bool> hasStoredSession() async {
    return await _tokenStorage.readRefreshToken() != null;
  }

  Future<void> verifyEmail(String token) async {
    try {
      await _apiClient.dio.post('/auth/verify-email', data: {'token': token});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> resendVerification(String email) async {
    try {
      await _apiClient.dio.post(
        '/auth/resend-verification',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
