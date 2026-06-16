import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:image/image.dart' as img;

/// Target size per raster once we decide re-encoding helps (six files in one POST).
const _kTargetBytesPerRaster = 380 * 1024;

const _rasterExtensions = [
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
  '.bmp',
  '.gif',
];

img.Image _resizeToMaxSide(img.Image src, int maxSide) {
  if (src.width <= maxSide && src.height <= maxSide) {
    return src;
  }
  return src.width >= src.height
      ? img.copyResize(src, width: maxSide)
      : img.copyResize(src, height: maxSide);
}

bool _hasRasterExtension(String nameLower) {
  return _rasterExtensions.any(nameLower.endsWith);
}

bool _isGenericUploadName(String name) {
  final lower = name.trim().toLowerCase();
  return name.trim().isEmpty || lower == 'upload.bin';
}

/// Sniff common raster formats when [img.decodeImage] fails (e.g. some gallery JPEGs).
String? _sniffRasterUploadName(Uint8List bytes) {
  if (bytes.length < 2) return null;
  if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
    return 'image.jpg';
  }
  if (bytes.length < 3) return null;
  if (bytes.length >= 4 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'image.png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46) {
    return 'image.gif';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image.webp';
  }
  return null;
}

String? _basenameFromPath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return null;
  final parts = trimmed.split(RegExp(r'[/\\]'));
  final base = parts.isEmpty ? trimmed : parts.last;
  if (base.isEmpty || !_hasRasterExtension(base.toLowerCase())) {
    return null;
  }
  return base;
}

img.Image? _tryDecodeRaster(Uint8List bytes) {
  return img.decodeImage(bytes) ??
      img.decodeJpg(bytes) ??
      img.decodePng(bytes) ??
      img.decodeGif(bytes) ??
      img.decodeWebP(bytes);
}

/// Multipart filename the API accepts for raster uploads.
String _rasterOutputName(String rawName, {String? sniffedName}) {
  if (sniffedName != null && sniffedName.isNotEmpty) {
    return sniffedName;
  }
  final trimmed = rawName.trim();
  if (_isGenericUploadName(trimmed)) {
    return 'image.jpg';
  }
  final lower = trimmed.toLowerCase();
  if (!_hasRasterExtension(lower)) {
    return 'image.jpg';
  }
  if (lower.endsWith('.png') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.bmp') ||
      lower.endsWith('.gif')) {
    return trimmed.replaceAll(RegExp(r'\.[^.]*$'), '.jpg');
  }
  return trimmed;
}

XFile _xFileWithName(XFile file, Uint8List bytes, String name) {
  final path = file.path.trim();
  if (path.isNotEmpty) {
    return XFile(path, name: name);
  }
  return XFile.fromData(bytes, name: name);
}

/// Resolves a server-acceptable multipart filename (reads file bytes if needed).
Future<String> resolveRegisterMultipartFilename(XFile file) async {
  final current = file.name.trim();
  if (current.isNotEmpty && !_isGenericUploadName(current)) {
    return _rasterOutputName(current);
  }

  final fromPath = _basenameFromPath(file.path);
  if (fromPath != null) {
    return fromPath;
  }

  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) {
    return current.isNotEmpty ? current : 'upload.bin';
  }

  final sniffed = _sniffRasterUploadName(bytes);
  if (sniffed != null) {
    return sniffed;
  }

  if (_tryDecodeRaster(bytes) != null) {
    return 'image.jpg';
  }

  return current.isNotEmpty ? current : 'upload.bin';
}

/// Optionally shrinks raster images before multipart upload.
///
/// PDF/Word/Excel are unchanged.
///
/// Gallery/camera picks often have an empty [XFile.name] (logged as `upload.bin`).
/// We detect rasters by decoding bytes (and magic-byte sniffing as fallback) so
/// multipart filenames get a real extension the API accepts.
///
/// Logos saved as PNG are often **smaller than a JPEG version** — Postman uploads
/// the original file; we must never replace it with a **larger** blob or total
/// request size grows and nginx can return 413.
Future<XFile> prepareRegisterAttachmentForUpload(XFile file) async {
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) {
    return file;
  }

  final rawName = file.name.trim().isEmpty ? 'upload.bin' : file.name.trim();
  final pathName = _basenameFromPath(file.path);
  final sniffed = _sniffRasterUploadName(bytes);
  final decoded = _tryDecodeRaster(bytes);

  if (decoded == null) {
    final fixedName = _rasterOutputName(
      pathName ?? rawName,
      sniffedName: sniffed,
    );
    if (sniffed != null || pathName != null) {
      if (fixedName == rawName && pathName == null) {
        return file;
      }
      return _xFileWithName(file, bytes, fixedName);
    }
    return file;
  }

  final outName = _rasterOutputName(pathName ?? rawName, sniffedName: sniffed);

  if (decoded.width <= 720 &&
      decoded.height <= 720 &&
      bytes.length < 100 * 1024) {
    if (outName == rawName && pathName == null) {
      return file;
    }
    return _xFileWithName(file, bytes, outName);
  }

  var maxSide = 1280;
  var quality = 66;
  late Uint8List best;
  late img.Image canvas;

  for (var pass = 0; pass < 10; pass++) {
    canvas = _resizeToMaxSide(decoded, maxSide);
    best = Uint8List.fromList(img.encodeJpg(canvas, quality: quality));
    if (best.isEmpty) {
      return _xFileWithName(file, bytes, outName);
    }
    if (best.length <= _kTargetBytesPerRaster || maxSide <= 480) {
      break;
    }
    maxSide = (maxSide * 0.8).floor().clamp(480, 2000);
    quality = (quality - 5).clamp(38, 90);
  }

  /// Match Postman: never upload processed bytes heavier than what the user picked.
  /// (PNG logos especially become larger when forced through JPEG.)
  if (best.length >= bytes.length) {
    return _xFileWithName(file, bytes, outName);
  }

  return XFile.fromData(best, name: outName);
}
