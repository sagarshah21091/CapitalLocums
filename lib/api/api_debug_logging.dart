import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Attaches verbose HTTP logging in debug/profile tooling builds only.
///
/// Passwords and password hashes are redacted; auth tokens are logged in full.
void attachApiDebugLogging(Dio dio) {
  if (!kDebugMode) {
    return;
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.extra['__api_req_start_ms'] =
            DateTime.now().millisecondsSinceEpoch;
        developer.log(
          '--> ${options.method} ${options.uri}',
          name: 'CapitalLocums.API',
        );
        developer.log(
          'Headers: ${_sanitizeHeaders(Map<String, dynamic>.from(options.headers))}',
          name: 'CapitalLocums.API',
        );
        final bodyPreview = _summarizeBodyForLog(options.data);
        developer.log(
          bodyPreview.detail != null && bodyPreview.summary != bodyPreview.detail
              ? '${bodyPreview.summary}\n${bodyPreview.detail}'
              : bodyPreview.summary,
          name: 'CapitalLocums.API',
        );
        handler.next(options);
      },
      onResponse: (response, handler) {
        final start = response.requestOptions.extra['__api_req_start_ms'];
        final elapsedMs = start is int
            ? DateTime.now().millisecondsSinceEpoch - start
            : null;
        developer.log(
          '<-- ${response.statusCode} ${response.requestOptions.uri}'
          '${elapsedMs != null ? ' (${elapsedMs}ms)' : ''}',
          name: 'CapitalLocums.API',
        );
        developer.log(
          'Data: ${_sanitizeJson(response.data)}',
          name: 'CapitalLocums.API',
        );
        handler.next(response);
      },
      onError: (error, handler) {
        final req = error.requestOptions;
        developer.log(
          'xx ${req.method} ${req.uri} type=${error.type} ${error.message}',
          name: 'CapitalLocums.API',
          level: 1000,
        );
        final body = error.response?.data;
        if (body != null) {
          developer.log(
            'Error body: ${_sanitizeJson(body)}',
            name: 'CapitalLocums.API',
            level: 1000,
          );
        }
        handler.next(error);
      },
    ),
  );
}

class _BodyLogPreview {
  const _BodyLogPreview({required this.summary, this.detail});
  final String summary;
  final String? detail;
}

_BodyLogPreview _summarizeBodyForLog(Object? raw) {
  if (raw is FormData) {
    final fd = raw;
    final fieldOrder = fd.fields.map((e) => e.key).join(' → ');
    final fieldKv = fd.fields.map((e) {
      final preview = _previewFieldValue(e.key, e.value);
      return '${e.key}=${preview ?? '<empty>'}';
    }).join('; ');
    final filesOrder =
        fd.files.map((e) => '${e.key}(${e.value.filename ?? '?'})').join(', ');
    return _BodyLogPreview(
      summary: 'Body: multipart — ${fd.fields.length} text fields / '
          '${fd.files.length} files',
      detail: 'Text field keys (order): $fieldOrder\n'
          'Text fields (preview): $fieldKv\n'
          'File parts (order): $filesOrder',
    );
  }
  return _BodyLogPreview(summary: 'Body: ${_sanitizeJson(raw)}');
}

/// Short preview for debug logs; hides password-style fields.
String? _previewFieldValue(String key, String value) {
  final lowerKey = key.toLowerCase();
  if (lowerKey == 'password' || lowerKey.endsWith('_password')) {
    return '***redacted***';
  }
  final t = value.trim();
  if (t.isEmpty) return null;
  if (t.length <= 64) {
    return t;
  }
  return '${t.substring(0, 61)}…';
}

Object? _sanitizeJson(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is FormData) {
    return '(multipart/form-data — ${raw.fields.length} fields, '
        '${raw.files.length} files; see detailed multipart log lines above)';
  }
  if (raw is List) {
    return raw.map(_sanitizeJson).toList();
  }
  if (raw is Map) {
    final copy = <String, dynamic>{};
    for (final e in raw.entries) {
      copy[e.key.toString()] = _sanitizeJson(e.value);
    }
    _redactPasswordFieldsInPlace(copy);
    return copy;
  }
  return raw;
}

void _redactPasswordFieldsInPlace(Map<String, dynamic> map) {
  if (map.containsKey('password')) {
    map['password'] = '***redacted***';
  }
  if (map.containsKey('password_hash')) {
    map['password_hash'] = '***redacted***';
  }
}

Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
  return Map<String, dynamic>.from(headers);
}
