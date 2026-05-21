import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

String? _versionName;

/// Loads `version` from bundled [pubspec.yaml] (name segment before `+`).
Future<void> initAppVersion() async {
  try {
    final raw = await rootBundle.loadString('pubspec.yaml');
    final doc = loadYaml(raw);
    if (doc is YamlMap) {
      final full = doc['version']?.toString() ?? '';
      final name = full.split('+').first.trim();
      if (name.isNotEmpty) _versionName = name;
    }
  } catch (e, st) {
    debugPrint('App version load failed: $e');
    debugPrint('$st');
  }
}

String get appVersionLabel {
  final v = _versionName;
  if (v != null && v.isNotEmpty) return 'Version $v';
  return 'Version';
}
