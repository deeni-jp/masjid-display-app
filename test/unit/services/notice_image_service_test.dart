// test/unit/services/notice_image_service_test.dart
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:prayer_app/services/notice_image_service.dart';

void main() {
  group('NoticeImageService.prepareSync', () {
    test('shrinks a large, noisy photo under the size and dimension caps', () {
      // Random noise is close to the worst case for JPEG compression.
      final rnd = Random(1);
      final source = img.Image(width: 3200, height: 2400);
      for (final p in source) {
        p.setRgb(rnd.nextInt(256), rnd.nextInt(256), rnd.nextInt(256));
      }
      final input = img.encodeJpg(source, quality: 95);

      final result = NoticeImageService.prepareSync(input);

      expect(
        result.bytes.length,
        lessThanOrEqualTo(NoticeImageService.maxBytes),
      );
      expect(
        max(result.width, result.height),
        lessThanOrEqualTo(NoticeImageService.maxDimension),
      );
      expect(result.width / result.height, closeTo(4 / 3, 0.01));

      final decoded = img.decodeJpg(result.bytes)!;
      expect(decoded.width, result.width);
      expect(decoded.height, result.height);
    });

    test('keeps small images at their size', () {
      final source = img.Image(width: 400, height: 300)
        ..clear(img.ColorRgb8(10, 120, 80));
      final result = NoticeImageService.prepareSync(img.encodePng(source));

      expect(result.width, 400);
      expect(result.height, 300);
    });

    test('flattens transparency onto white', () {
      final source = img.Image(width: 20, height: 20, numChannels: 4)
        ..clear(img.ColorRgba8(0, 0, 0, 0));
      final result = NoticeImageService.prepareSync(img.encodePng(source));

      final pixel = img.decodeJpg(result.bytes)!.getPixel(10, 10);
      expect(pixel.r, greaterThan(240));
      expect(pixel.g, greaterThan(240));
      expect(pixel.b, greaterThan(240));
    });

    test('rejects files that are not images', () {
      expect(
        () => NoticeImageService.prepareSync(
          Uint8List.fromList(List.filled(64, 7)),
        ),
        throwsA(isA<NoticeImageException>()),
      );
    });
  });
}
