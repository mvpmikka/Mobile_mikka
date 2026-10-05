import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/short.dart';

class ShortFeedPage {
  const ShortFeedPage({required this.items, required this.total});

  final List<Short> items;
  final int total;
}

class ShortService {
  ShortService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Raw video upload — no server-side processing, see UploadService.uploadVideo.
  Future<String> uploadVideo(String filePath) async {
    try {
      final response = await _apiClient.dio.post(
        '/uploads/video',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath),
        }),
      );
      final data = response.data as Map<String, dynamic>;
      return data['url'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// The thumbnail is just an extracted video frame uploaded through the
  /// existing generic image endpoint — no dedicated thumbnail pipeline.
  Future<String> uploadThumbnail(String filePath) async {
    try {
      final response = await _apiClient.dio.post(
        '/uploads/image',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath),
        }),
      );
      final data = response.data as Map<String, dynamic>;
      return data['url'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> create({
    String? caption,
    String? placeId,
    required String videoUrl,
    String? thumbnailUrl,
  }) async {
    try {
      await _apiClient.dio.post(
        '/shorts',
        data: {
          'caption': ?caption,
          'placeId': ?placeId,
          'videoUrl': videoUrl,
          'thumbnailUrl': ?thumbnailUrl,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ShortFeedPage> getFeed({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        '/shorts/feed',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      return ShortFeedPage(
        items: (data['items'] as List<dynamic>)
            .map((e) => Short.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: data['total'] as int,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> like(String id) async {
    try {
      await _apiClient.dio.post('/shorts/$id/like');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> unlike(String id) async {
    try {
      await _apiClient.dio.delete('/shorts/$id/like');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _apiClient.dio.delete('/shorts/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
