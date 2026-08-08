import 'package:dio/dio.dart';

import 'api_config.dart';
import 'token_storage.dart';

/// Thin wrapper around [Dio] that attaches the access token to every
/// request and transparently refreshes it once on a 401 before retrying.
///
/// REST is the only source of truth here — there's no WebSocket wiring on
/// the mobile side yet, matching how far the backend integration has gone
/// so far.
class ApiClient {
  ApiClient({required TokenStorage tokenStorage})
    : _tokenStorage = tokenStorage,
      _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;
  Future<String?>? _refreshInFlight;

  /// Invoked once a refresh attempt fails, so the app can drop the user
  /// back to the login screen. Set by the auth provider.
  void Function()? onUnauthenticated;

  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = error.response?.statusCode == 401;
    final isRefreshCall = error.requestOptions.path == '/auth/refresh';
    if (!isUnauthorized || isRefreshCall) {
      return handler.next(error);
    }

    final newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null) {
      await _tokenStorage.clear();
      onUnauthenticated?.call();
      return handler.next(error);
    }

    final retryOptions = error.requestOptions
      ..headers['Authorization'] = 'Bearer $newAccessToken';
    try {
      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Coalesces concurrent 401s (e.g. several widgets fetching at once)
  /// into a single `/auth/refresh` call.
  Future<String?> _refreshAccessToken() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return null;
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;
      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );
      return accessToken;
    } on DioException {
      return null;
    }
  }
}
