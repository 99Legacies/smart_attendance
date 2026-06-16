// One-off script: crop white/transparent border from icon assets and
// repad so the logo fills ~83 % of the canvas.
// Run from project root:  dart run tool/resize_icons.dart
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() async {
  await _process(
    'assets/icon/app_icon.png',
    fill: img.ColorRgba8(255, 255, 255, 255), // white background
    logoFraction: 0.83,
    transparent: false,
  );

  await _process(
    'assets/icon/adaptive_icon_foreground.png',
    fill: img.ColorRgba8(0, 0, 0, 0), // transparent background
    logoFraction: 0.60, // fits inside adaptive icon safe zone
    transparent: true,
  );
}

Future<void> _process(
  String path, {
  required img.Color fill,
  required double logoFraction,
  required bool transparent,
}) async {
  final file = File(path);
  final source = img.decodeImage(await file.readAsBytes())!;

  final trimmed = _trim(source, transparent: transparent);

  const canvas = 1024;
  final target = (canvas * logoFraction).round();

  final scale = min(target / trimmed.width, target / trimmed.height);
  final sw = (trimmed.width * scale).round();
  final sh = (trimmed.height * scale).round();
  final scaled = img.copyResize(trimmed, width: sw, height: sh);

  final out = img.Image(width: canvas, height: canvas);
  img.fill(out, color: fill);

  final dx = (canvas - scaled.width) ~/ 2;
  final dy = (canvas - scaled.height) ~/ 2;
  img.compositeImage(out, scaled, dstX: dx, dstY: dy);

  await file.writeAsBytes(img.encodePng(out));
  stderr.writeln('✓ $path  (logo ${sw}x$sh on ${canvas}x$canvas canvas)');
}

// Returns a tight crop around non-white / non-transparent content.
img.Image _trim(img.Image src, {required bool transparent}) {
  int left = src.width, right = 0, top = src.height, bottom = 0;

  for (final p in src) {
    final r = p.r.toInt();
    final g = p.g.toInt();
    final b = p.b.toInt();
    final a = p.a.toInt();

    final skip = transparent
        ? a < 16
        : (a < 16 || (r > 240 && g > 240 && b > 240));

    if (!skip) {
      if (p.x < left) left = p.x;
      if (p.x > right) right = p.x;
      if (p.y < top) top = p.y;
      if (p.y > bottom) bottom = p.y;
    }
  }

  if (left > right || top > bottom) return src;

  return img.copyCrop(
    src,
    x: left,
    y: top,
    width: right - left + 1,
    height: bottom - top + 1,
  );
}
