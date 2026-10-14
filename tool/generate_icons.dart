// tool/generate_icons.dart
//
// Builds the logo and app-icon source images from assets/images/mosque.png:
//   assets/images/masjid_logo.png         in-app logo, transparent, trimmed
//   assets/icon/app_icon.png              1024x1024, logo on white
//   assets/icon/app_icon_foreground.png   1024x1024, transparent, logo sized
//                                         for Android's adaptive-icon safe zone
//
// Usage (then regenerate the platform icons):
//   dart run tool/generate_icons.dart
//   dart run flutter_launcher_icons
//
// If mosque.png has no real transparency (e.g. a "transparent" checkerboard
// painted into the image), the light background around the badge is removed
// first: see _removeLightBackground.
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const _source = 'assets/images/mosque.png';
const _iconSize = 1024;

void main() {
  final decoded = img.decodePng(File(_source).readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('Could not read $_source as a PNG');
    exit(1);
  }

  final source =
      _hasTransparency(decoded)
          ? decoded
          : _removeLightBackground(decoded.convert(numChannels: 4));
  final logo = _trimTransparent(source);
  stdout.writeln(
    'Source ${decoded.width}x${decoded.height}, '
    'logo ${logo.width}x${logo.height}',
  );

  _write('assets/images/masjid_logo.png', logo);

  // Logo fills 80% of the icon, on white (iOS icons can't be transparent).
  _write(
    'assets/icon/app_icon.png',
    _onCanvas(logo, fill: 0.80, background: img.ColorRgba8(255, 255, 255, 255)),
  );

  // Android adaptive icons crop to a circle/squircle of ~66% of the canvas;
  // keep the logo inside that.
  _write(
    'assets/icon/app_icon_foreground.png',
    _onCanvas(logo, fill: 0.60, background: img.ColorRgba8(0, 0, 0, 0)),
  );
}

bool _hasTransparency(img.Image image) {
  if (!image.hasAlpha) return false;
  for (final p in image) {
    if (p.a < 250) return true;
  }
  return false;
}

/// White or light grey (a checkerboard square), not a colour from the logo.
bool _isLightGrey(img.Pixel p) {
  final hi = max(p.r, max(p.g, p.b));
  final lo = min(p.r, min(p.g, p.b));
  return lo >= 185 && hi - lo <= 30;
}

/// Makes the light, grey background transparent: flood-fills from the image
/// edges through white/grey pixels, so it stops at the logo's coloured
/// border and white areas inside the logo are kept. Edge pixels next to the
/// removed area get partial transparency to avoid a light halo.
img.Image _removeLightBackground(img.Image image) {
  final w = image.width, h = image.height;
  final removed = List<bool>.filled(w * h, false);
  final queue = Queue<int>();

  void visit(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    final i = y * w + x;
    if (removed[i] || !_isLightGrey(image.getPixel(x, y))) return;
    removed[i] = true;
    queue.add(i);
  }

  for (var x = 0; x < w; x++) {
    visit(x, 0);
    visit(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    visit(0, y);
    visit(w - 1, y);
  }
  while (queue.isNotEmpty) {
    final i = queue.removeFirst();
    final x = i % w, y = i ~/ w;
    visit(x + 1, y);
    visit(x - 1, y);
    visit(x, y + 1);
    visit(x, y - 1);
  }

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      final p = image.getPixel(x, y);
      if (removed[i]) {
        p.a = 0;
        continue;
      }
      // Anti-aliased edge: fade pixels that touch the background by how
      // light they are (light = mostly background colour).
      final touches =
          (x > 0 && removed[i - 1]) ||
          (x < w - 1 && removed[i + 1]) ||
          (y > 0 && removed[i - w]) ||
          (y < h - 1 && removed[i + w]);
      if (touches) {
        final lo = min(p.r, min(p.g, p.b)).toDouble();
        final fade = ((lo - 90) / (185 - 90)).clamp(0.0, 1.0);
        p.a = (255 * (1 - fade)).round();
      }
    }
  }
  return image;
}

/// Crops away fully (or almost fully) transparent borders.
img.Image _trimTransparent(img.Image image) {
  var minX = image.width, minY = image.height, maxX = -1, maxY = -1;
  for (final p in image) {
    if (p.a > 10) {
      minX = min(minX, p.x);
      minY = min(minY, p.y);
      maxX = max(maxX, p.x);
      maxY = max(maxY, p.y);
    }
  }
  if (maxX < 0) return image; // fully transparent: leave as is
  return img.copyCrop(
    image,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}

/// Centres [logo] on a square canvas, scaled so its longer side is
/// [fill] of the canvas.
img.Image _onCanvas(
  img.Image logo, {
  required double fill,
  required img.Color background,
}) {
  final target = (_iconSize * fill).round();
  final scaled =
      logo.width >= logo.height
          ? img.copyResize(
            logo,
            width: target,
            interpolation: img.Interpolation.cubic,
          )
          : img.copyResize(
            logo,
            height: target,
            interpolation: img.Interpolation.cubic,
          );

  final canvas = img.Image(width: _iconSize, height: _iconSize, numChannels: 4)
    ..clear(background);
  return img.compositeImage(
    canvas,
    scaled,
    dstX: (_iconSize - scaled.width) ~/ 2,
    dstY: (_iconSize - scaled.height) ~/ 2,
  );
}

void _write(String path, img.Image image) {
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(image));
  stdout.writeln('Wrote $path (${image.width}x${image.height})');
}
