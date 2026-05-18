import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:image/image.dart' as img;

/// Target size per raster once we decide re-encoding helps (six files in one POST).
const _kTargetBytesPerRaster = 380 * 1024;

img.Image _resizeToMaxSide(img.Image src, int maxSide) {
  if (src.width <= maxSide && src.height <= maxSide) {
    return src;
  }
  return src.width >= src.height
      ? img.copyResize(src, width: maxSide)
      : img.copyResize(src, height: maxSide);
}

/// Optionally shrinks raster images before multipart upload.
///
/// PDF/Word/Excel are unchanged.
///
/// Logos saved as PNG are often **smaller than a JPEG version** — Postman uploads
/// the original file; we must never replace it with a **larger** blob or total
/// request size grows and nginx can return 413.
Future<XFile> prepareRegisterAttachmentForUpload(XFile file) async {
  final rawName = file.name.trim().isEmpty ? 'upload.bin' : file.name.trim();
  final nameLower = rawName.toLowerCase();

  const rasterExt = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.bmp',
    '.gif',
  ];
  final isRaster = rasterExt.any((e) => nameLower.endsWith(e));
  if (!isRaster) {
    return file;
  }

  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) {
    return file;
  }

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return file;
  }

  if (decoded.width <= 720 &&
      decoded.height <= 720 &&
      bytes.length < 100 * 1024) {
    return file;
  }

  final outName = nameLower.endsWith('.png') ||
          nameLower.endsWith('.webp') ||
          nameLower.endsWith('.bmp') ||
          nameLower.endsWith('.gif')
      ? rawName.replaceAll(RegExp(r'\.[^.]*$'), '.jpg')
      : rawName;

  var maxSide = 1280;
  var quality = 66;
  late Uint8List best;
  late img.Image canvas;

  for (var pass = 0; pass < 10; pass++) {
    canvas = _resizeToMaxSide(decoded, maxSide);
    best = Uint8List.fromList(img.encodeJpg(canvas, quality: quality));
    if (best.isEmpty) {
      return file;
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
    return file;
  }

  return XFile.fromData(best, name: outName);
}
