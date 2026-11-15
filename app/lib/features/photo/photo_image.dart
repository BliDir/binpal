import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Longest side of the photo sent to the API. The API refuses more than
/// 1024 px or 150 KB.
const uploadLongSide = 512;

/// Shrinks a camera or gallery photo for upload: upright (EXIF rotation
/// applied, then dropped with the rest of the metadata, including any
/// location), at most [uploadLongSide] px on the long side, JPEG. A 512 px
/// photo at quality 80 is usually 30–60 KB; quality steps down if it is
/// still over [maxBytes]. Runs in a background isolate.
Future<Uint8List> resizeForUpload(
  Uint8List original, {
  int maxBytes = 100000,
}) => Isolate.run(() {
  final decoded = img.decodeImage(original);
  if (decoded == null) throw const FormatException('not an image');
  final upright = img.bakeOrientation(decoded);
  final scaled = upright.width >= upright.height
      ? (upright.width > uploadLongSide
            ? img.copyResize(upright, width: uploadLongSide)
            : upright)
      : (upright.height > uploadLongSide
            ? img.copyResize(upright, height: uploadLongSide)
            : upright);
  scaled.exif = img.ExifData();
  for (var quality = 80; ; quality -= 15) {
    final jpeg = img.encodeJpg(scaled, quality: quality);
    if (jpeg.length <= maxBytes || quality <= 35) return jpeg;
  }
});
