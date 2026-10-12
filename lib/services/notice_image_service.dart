// lib/services/notice_image_service.dart
//
// Picking, compressing and loading the optional image attached to a notice.
// Images are stored in Firestore (see FirebaseService), so they are resized
// and re-encoded as JPEG to stay well under Firestore's 1 MiB document limit.
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../models/notification_model.dart';
import 'firebase_service.dart';

/// A compressed JPEG ready to be saved with a notice.
class PreparedImage {
  final Uint8List bytes;
  final int width;
  final int height;

  const PreparedImage({
    required this.bytes,
    required this.width,
    required this.height,
  });
}

class NoticeImageService {
  /// Longest edge after resizing. Sharp enough for a flyer on a 1080p screen.
  static const int maxDimension = 1600;

  /// Upper bound for the encoded image (Firestore documents max out at 1 MiB).
  static const int maxBytes = 900 * 1024;

  static const String contentType = 'image/jpeg';

  /// Lets the user choose an image from the gallery / file system and
  /// compresses it. Returns null if they cancel.
  /// Throws [NoticeImageException] if the file can't be used.
  static Future<PreparedImage?> pickAndPrepare() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Let the platform downscale first where it can (mobile, web).
      maxWidth: maxDimension.toDouble(),
      maxHeight: maxDimension.toDouble(),
      imageQuality: 90,
    );
    if (file == null) return null;
    return prepare(await file.readAsBytes());
  }

  /// Decodes, orients, resizes and JPEG-encodes [input] so it is at most
  /// [maxDimension] px on its longest edge and [maxBytes] in size.
  static Future<PreparedImage> prepare(Uint8List input) =>
      compute(prepareSync, input);

  @visibleForTesting
  static PreparedImage prepareSync(Uint8List input) {
    final decoded = img.decodeImage(input);
    if (decoded == null) {
      throw NoticeImageException('This file is not a supported image.');
    }

    var image = img.bakeOrientation(decoded);

    // JPEG has no transparency: flatten onto white instead of black.
    if (image.hasAlpha) {
      final background = img.Image(width: image.width, height: image.height)
        ..clear(img.ColorRgb8(255, 255, 255));
      image = img.compositeImage(background, image);
    }

    image = _fitWithin(image, maxDimension);

    // Lower quality first, then size, until it fits.
    for (var attempt = 0; attempt < 4; attempt++) {
      for (final quality in const [85, 75, 65, 55]) {
        final bytes = img.encodeJpg(image, quality: quality);
        if (bytes.length <= maxBytes) {
          return PreparedImage(
            bytes: bytes,
            width: image.width,
            height: image.height,
          );
        }
      }
      final longest = image.width > image.height ? image.width : image.height;
      image = _fitWithin(image, (longest * 0.75).round());
    }

    throw NoticeImageException(
      'This image is too detailed to upload. Please choose a smaller one.',
    );
  }

  static img.Image _fitWithin(img.Image image, int max) {
    if (image.width <= max && image.height <= max) return image;
    return image.width >= image.height
        ? img.copyResize(
          image,
          width: max,
          interpolation: img.Interpolation.average,
        )
        : img.copyResize(
          image,
          height: max,
          interpolation: img.Interpolation.average,
        );
  }

  // ============ LOADING ============

  /// In-memory cache, keyed by notice id + image version, so rotating
  /// carousels don't download the same image again.
  static final Map<String, Future<Uint8List?>> _cache = {};

  static String _cacheKey(MosqueNotification n) =>
      '${n.id}@${n.imageUpdatedAt?.millisecondsSinceEpoch ?? 0}';

  /// The image bytes for [notification], or null if it has none.
  static Future<Uint8List?> fetch(MosqueNotification notification) {
    if (!notification.hasImage || notification.id.isEmpty) {
      return Future.value(null);
    }

    final key = _cacheKey(notification);
    final cached = _cache[key];
    if (cached != null) return cached;

    // Drop older versions of this notice's image.
    _cache.removeWhere((k, _) => k.startsWith('${notification.id}@'));

    final future = FirebaseService.getNotificationImage(
      notification.id,
    ).catchError((Object e) {
      _cache.remove(key); // allow a retry next time
      throw e;
    });
    _cache[key] = future;
    return future;
  }

  /// Seeds the cache right after saving, so the author sees the image
  /// without downloading it again.
  static void remember(MosqueNotification notification, Uint8List bytes) {
    if (!notification.hasImage || notification.id.isEmpty) return;
    _cache.removeWhere((k, _) => k.startsWith('${notification.id}@'));
    _cache[_cacheKey(notification)] = Future.value(bytes);
  }
}

class NoticeImageException implements Exception {
  final String message;

  NoticeImageException(this.message);

  @override
  String toString() => message;
}
