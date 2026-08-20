import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';

class IceServer {
  const IceServer({required this.urls, this.username, this.credential});

  final List<String> urls;
  final String? username;
  final String? credential;

  factory IceServer.fromJson(Map<String, dynamic> json) {
    final rawUrls = json['urls'];
    return IceServer(
      urls: rawUrls is List ? rawUrls.cast<String>() : [rawUrls as String],
      username: json['username'] as String?,
      credential: json['credential'] as String?,
    );
  }
}

class CallService {
  CallService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<IceServer>> getIceServers() async {
    try {
      final response = await _apiClient.dio.get('/call/ice-servers');
      final data = response.data as Map<String, dynamic>;
      return (data['iceServers'] as List<dynamic>)
          .map((e) => IceServer.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
