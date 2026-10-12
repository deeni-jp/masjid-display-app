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
// mosque.png is small, so the 1024px icons are upscaled and look soft.
// Replace mosque.png with higher-resolution artwork and re-run for crisp icons.
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

  final logo = _trimTransparent(decoded);
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
