import 'package:dio/dio.dart';

/// Best-effort user-facing text from [DioException] and JSON error bodies.
String messageFromDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'The request timed out. Check your connection and try again.';
    case DioExceptionType.connectionError:
      return 'Could not reach the server. Check your internet connection.';
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      if (status == 413) {
        return 'Your attachments are larger than this server accepts (HTTP 413). '
            'Photos are shrunk automatically—try replacing very large PDFs with '
            'smaller scans, or fewer files. The server admin may need to raise '
            'nginx client_max_body_size.';
      }
      return _messageFromResponse(e) ??
          'Something went wrong (${e.response?.statusCode ?? ''}).'.trim();
    case DioExceptionType.cancel:
      return 'Request was cancelled.';
    case DioExceptionType.badCertificate:
      return 'Secure connection could not be verified.';
    case DioExceptionType.unknown:
      final err = e.error;
      if (err != null) {
        return err.toString();
      }
      return 'Something went wrong. Please try again.';
  }
}

String? _messageFromResponse(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    if (message is List && message.isNotEmpty) {
      final first = message.first;
      if (first != null && first.toString().trim().isNotEmpty) {
        return first.toString().trim();
      }
    }
    final error = data['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }
  }
  return null;
}
