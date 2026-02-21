import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';

/// Base API service with shared error handling.
/// All module services extend this class.
abstract class BaseApiService {
  final DioClient _client;

  BaseApiService(this._client);

  Dio get dio => _client.dio;

  /// Handle DioException and return a user-friendly error message
  String handleError(DioException e) {
    // Network / timeout errors
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Please check your internet and try again.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server. Please check your connection.';
    }

    // Server response errors
    final data = e.response?.data;
    final statusCode = e.response?.statusCode;
    
    // Debug log for production-grade troubleshooting
    print('API Error: Status=$statusCode, Body=$data');

    if (data is Map<String, dynamic>) {
      // NestJS sends { message: string | string[], error?: string, statusCode: int }
      final dynamic rawMessage = data['message'];
      
      String extractedMessage = '';
      if (rawMessage is List) {
        extractedMessage = rawMessage.map((m) => m.toString()).join('\n');
      } else if (rawMessage != null && rawMessage.toString().isNotEmpty) {
        extractedMessage = rawMessage.toString();
      } else {
        // Sometimes NestJS wraps in 'error' instead if message is missing
        final dynamic rawError = data['error'];
        if (rawError != null && rawError.toString().isNotEmpty) {
          extractedMessage = rawError.toString();
        }
      }

      // Convert common technical validators into user-friendly messages
      if (extractedMessage.isNotEmpty) {
        if (extractedMessage.contains('must be a UUID')) {
          return 'Please select a valid option from the dropdown list.';
        }
        if (extractedMessage.contains('should not be empty')) {
          return 'Please fill in all required fields marked with an asterisk.';
        }
        if (extractedMessage.contains('must be a number conforming to the specified constraints')) {
          return 'Please enter a valid numeric value for price and stock.';
        }
        return extractedMessage;
      }
    }

    // Fallback by status code
    switch (statusCode) {
      case 400:
        return 'The data submitted is invalid. Please check your input.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You don\'t have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'A conflict occurred. This item may already exist.';
      case 422:
        return 'The data you submitted is invalid.';
      case 429:
        return 'Too many requests. Please wait a moment.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        final dioMessage = e.message;
        if (dioMessage != null && dioMessage.isNotEmpty) return dioMessage;
        return 'Something went wrong. Please try again.';
    }
  }

  /// Wrap an API call with consistent error handling
  Future<T> safeApiCall<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on DioException catch (e) {
      throw handleError(e);
    } catch (e) {
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }
}
