import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import 'base_api_service.dart';

/// Storage API Service — handles file uploads to the backend.
class StorageService extends BaseApiService {
  StorageService(super.client);

  /// Upload a single file and return its URL.
  /// [filePath] is the local file path on device.
  /// [folder] is the target folder on the server (e.g. 'pets', 'products', 'avatars').
  Future<String> uploadFile(String filePath, {String folder = 'general'}) async {
    return safeApiCall(() async {
      final fileName = filePath.split('/').last.split('\\').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'folder': folder,
      });

      final response = await dio.post(
        ApiEndpoints.storageUpload,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      // Backend returns { url: '...' } or { path: '...' }
      final data = response.data;
      return (data['url'] ?? data['path'] ?? '') as String;
    });
  }

  /// Upload multiple files and return their URLs.
  /// [filePaths] is a list of local file paths.
  /// [folder] is the target folder on the server.
  Future<List<String>> uploadMultiple(List<String> filePaths, {String folder = 'general'}) async {
    return safeApiCall(() async {
      final multipartFiles = <MultipartFile>[];
      for (final path in filePaths) {
        final fileName = path.split('/').last.split('\\').last;
        multipartFiles.add(await MultipartFile.fromFile(path, filename: fileName));
      }

      final formData = FormData.fromMap({
        'files': multipartFiles,
        'folder': folder,
      });

      final response = await dio.post(
        ApiEndpoints.storageUploadMultiple,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      // Backend returns array of { url: '...' } or list of URLs
      final data = response.data;
      if (data is List) {
        return data.map<String>((item) {
          if (item is String) return item;
          if (item is Map) return (item['url'] ?? item['path'] ?? '') as String;
          return '';
        }).where((url) => url.isNotEmpty).toList();
      }
      // Or { urls: [...] } or { files: [...] }
      if (data is Map) {
        final urls = data['urls'] ?? data['files'] ?? data['data'] ?? [];
        if (urls is List) {
          return urls.map<String>((item) {
            if (item is String) return item;
            if (item is Map) return (item['url'] ?? item['path'] ?? '') as String;
            return '';
          }).where((url) => url.isNotEmpty).toList();
        }
      }
      return [];
    });
  }
}
