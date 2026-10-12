// lib/widgets/notice_image.dart
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/notice_image_service.dart';

/// The image attached to a notice, sized to fit the space it's given.
///
/// The box keeps the image's aspect ratio and is never wider than the
/// available width or taller than [maxHeight] / the available height, so it
/// can't overflow or overlap its neighbours. A same-sized placeholder is
/// shown while it loads, so layouts don't jump.
class NoticeImage extends StatefulWidget {
  final MosqueNotification notification;

  /// Height cap. If null, the incoming height constraint is used.
  final double? maxHeight;
  final double borderRadius;
  final Alignment alignment;

  const NoticeImage({
    super.key,
    required this.notification,
    this.maxHeight,
    this.borderRadius = 12,
    this.alignment = Alignment.center,
  });

  @override
  State<NoticeImage> createState() => _NoticeImageState();
}

class _NoticeImageState extends State<NoticeImage> {
  late Future<Uint8List?> _image;

  @override
  void initState() {
    super.initState();
    _image = NoticeImageService.fetch(widget.notification);
  }

  @override
  void didUpdateWidget(NoticeImage old) {
    super.didUpdateWidget(old);
    final a = old.notification, b = widget.notification;
    if (a.id != b.id ||
        a.hasImage != b.hasImage ||
        a.imageUpdatedAt != b.imageUpdatedAt) {
      _image = NoticeImageService.fetch(b);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Before the real size is known (older data), assume a 4:3 photo.
    final ratio = widget.notification.imageAspectRatio ?? 4 / 3;

    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth.isFinite ? c.maxWidth : 320.0;
        final maxH = math.min(widget.maxHeight ?? double.infinity, c.maxHeight);

        var width = maxW;
        var height = width / ratio;
        if (maxH.isFinite && height > maxH) {
          height = maxH;
          width = height * ratio;
        }

        return Align(
          alignment: widget.alignment,
          heightFactor: 1,
          child: SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: FutureBuilder<Uint8List?>(
                future: _image,
                builder: (context, snapshot) {
                  final bytes = snapshot.data;
                  if (bytes != null) {
                    return Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.medium,
                      semanticLabel:
                          widget.notification.title.isNotEmpty
                              ? widget.notification.title
                              : 'Notice image',
                    );
                  }
                  final failed =
                      snapshot.hasError ||
                      snapshot.connectionState == ConnectionState.done;
                  return _Placeholder(failed: failed);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  final bool failed;

  const _Placeholder({required this.failed});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.grey.withValues(alpha: 0.15),
      child: Center(
        child: Icon(
          failed ? Icons.broken_image_outlined : Icons.image_outlined,
          color: Colors.grey,
        ),
      ),
    );
  }
}
