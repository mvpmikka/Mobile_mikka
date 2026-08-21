import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/post.dart';

class UploadedImage {
  const UploadedImage({required this.url, this.thumbnailUrl});

  final String url;
  final String? thumbnailUrl;
}

class PostService {
  PostService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Each picked image is uploaded through the existing generic
  /// `POST /uploads/image` (same endpoint Upload already exposes) — Post
  /// itself never touches file storage, it only stores the URLs handed
  /// back here.
  Future<UploadedImage> uploadImage(String filePath) async {
    try {
      final response = await _apiClient.dio.post(
        '/uploads/image',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath),
        }),
      );
      final data = response.data as Map<String, dynamic>;
      return UploadedImage(
        url: data['url'] as String,
        thumbnailUrl: data['thumbnailUrl'] as String?,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> create({
    String? caption,
    String? placeId,
    required List<UploadedImage> images,
  }) async {
    try {
      await _apiClient.dio.post(
        '/posts',
        data: {
          'caption': ?caption,
          'placeId': ?placeId,
          'images': images
              .map((image) => {
                    'url': image.url,
                    'thumbnailUrl': ?image.thumbnailUrl,
                  })
              .toList(),
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Post>> getForUser(
    String username, {
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/users/$username/posts',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Memory>> getMemories({int page = 1, int limit = 30}) async {
    try {
      final response = await _apiClient.dio.get(
        '/users/me/memories',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List<dynamic>)
          .map((e) => Memory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _apiClient.dio.delete('/posts/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
