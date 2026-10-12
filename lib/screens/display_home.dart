// lib/screens/display_home.dart
//
// Large-screen masjid display (design/screens/1 · Home display).
// Used by HomeTab when the window is at least [kDisplayBreakpoint] wide.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../models/hijri_date.dart';
import '../models/notification_model.dart';
import '../models/prayer_time.dart';
import '../utils/design.dart';
import '../widgets/notice_image.dart';
import '../widgets/masjid_logo.dart';

class DisplayHome extends StatelessWidget {
  final PrayerSchedule? prayerSchedule;
  final PrayerTime? nextPrayer;
  final Duration timeToNext;
  final List<MosqueNotification> notifications;
  final HijriDate? hijriDate;
  final VoidCallback? onOpenSettings;
  final void Function(MosqueNotification)? onNotificationTap;
  final bool darkMode;

  const DisplayHome({
    super.key,
    required this.prayerSchedule,
    required this.nextPrayer,
    required this.timeToNext,
    required this.notifications,
    this.hijriDate,
    this.onOpenSettings,
    this.onNotificationTap,
    this.darkMode = false,
  });

  /// Reference size of the design canvas; everything scales from it.
  static const double _designWidth = 2000;
  static const double _designHeight = 1125;

  /// Height of the footer row (ticker + donate tile).
  static const double _footerHeight = 146;

  @override
  Widget build(BuildContext context) {
    final active = notifications.activeOnly.sortedByPriorityThenExpiry;
    // Image-only notices have nothing to scroll in the footer ticker.
    final tickerNotices = active.where((n) => n.hasMessage).toList();
    final p = DesignPalette.of(darkMode);

    return ColoredBox(
      color: p.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final s = (constraints.maxWidth / _designWidth).clamp(
            0.0,
            constraints.maxHeight / _designHeight,
          );
          final gap = 26 * s;

          return Padding(
            padding: EdgeInsets.fromLTRB(50 * s, 44 * s, 50 * s, 44 * s),
            child: Column(
              children: [
                SizedBox(
                  height: 136 * s,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 1155,
                        child: _MasjidHeader(
                          s: s,
                          p: p,
                          onOpenSettings: onOpenSettings,
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        flex: 718,
                        child: _ClockCard(s: s, p: p, hijriDate: hijriDate),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: gap),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 1155,
                        // Bigger type in the main section.
                        child: _PrayerTable(
                          s: s * 1.35,
                          p: p,
                          schedule: prayerSchedule,
                          nextPrayer: nextPrayer,
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        flex: 718,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // With notices showing, the next-prayer countdown
                            // moves to a strip under the clock; otherwise the
                            // carousel shows it.
                            if (active.isNotEmpty) ...[
                              SizedBox(
                                height: 96 * s,
                                child: _NextPrayerStrip(
                                  s: s,
                                  p: p,
                                  nextPrayer: nextPrayer,
                                  timeToNext: timeToNext,
                                ),
                              ),
                              SizedBox(height: gap),
                            ],
                            Expanded(
                              child: _NoticeCarousel(
                                s: s,
                                p: p,
                                notices: active,
                                nextPrayer: nextPrayer,
                                timeToNext: timeToNext,
                                onTap: onNotificationTap,
                              ),
                            ),
                            // No ticker: the donate tile sits here instead
                            // of alone in an otherwise empty footer.
                            if (tickerNotices.isEmpty) ...[
                              SizedBox(height: gap),
                              SizedBox(
                                height: _footerHeight * s,
                                child: _DonateTile(s: s, p: p),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (tickerNotices.isNotEmpty) ...[
                  SizedBox(height: gap),
                  SizedBox(
                    height: _footerHeight * s,
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 92 * s,
                            child: _NoticeTicker(
                              s: s,
                              p: p,
                              notices: tickerNotices,
                              onTap: onNotificationTap,
                            ),
                          ),
                        ),
                        SizedBox(width: gap),
                        _DonateTile(s: s, p: p),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

BoxDecoration _cardDecoration(double s, DesignPalette p) {
  return BoxDecoration(
    color: p.surface,
    borderRadius: BorderRadius.circular(34 * s),
    border: Border.all(color: p.border, width: 1.5),
  );
}

// ───────────────────────────── Header ─────────────────────────────

class _MasjidHeader extends StatelessWidget {
  final double s;
  final DesignPalette p;
  final VoidCallback? onOpenSettings;

  const _MasjidHeader({required this.s, required this.p, this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22 * s),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: p.border, width: 1.5),
      ),
      child: Row(
        children: [
          MasjidLogo(size: 104 * s),
          SizedBox(width: 28 * s),
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                MasjidInfo.name,
                style: DesignText.latin(
                  size: 46 * s,
                  weight: FontWeight.w700,
                  color: p.title,
                  height: 1.1,
                ),
              ),
            ),
          ),
          if (onOpenSettings != null)
            Material(
              color: p.accentSurfaceSoft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18 * s),
                side: BorderSide(color: p.border),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18 * s),
                onTap: onOpenSettings,
                child: SizedBox(
                  width: 72 * s,
                  height: 72 * s,
                  child: Icon(
                    Icons.settings_outlined,
                    color: p.title,
                    size: 38 * s,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClockCard extends StatelessWidget {
  final double s;
  final DesignPalette p;
  final HijriDate? hijriDate;

  const _ClockCard({required this.s, required this.p, this.hijriDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 42 * s),
      decoration: BoxDecoration(
        color: p.accentSurface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: p.border, width: 1.5),
      ),
      child: Row(
        children: [
          TimeWithPeriod(
            time: now,
            seconds: true,
            size: 70 * s,
            weight: FontWeight.w800,
            color: p.title,
            periodScale: 0.36,
          ),
          SizedBox(width: 16 * s),
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerRight,
              fit: BoxFit.scaleDown,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(now),
                    style: DesignText.latin(
                      size: 22 * s,
                      weight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                  if (hijriDate != null) ...[
                    Text(
                      Bilingual.hijriEnglish(hijriDate),
                      style: DesignText.latin(
                        size: 19 * s,
                        weight: FontWeight.w500,
                        color: p.inkMuted,
                      ),
                    ),
                    Text(
                      Bilingual.hijriArabic(hijriDate),
                      textDirection: TextDirection.rtl,
                      style: DesignText.arabic(
                        size: 17 * s,
                        color: p.inkMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact next-prayer countdown shown under the clock while notices take
/// the carousel.
class _NextPrayerStrip extends StatelessWidget {
  final double s;
  final DesignPalette p;
  final PrayerTime? nextPrayer;
  final Duration timeToNext;

  const _NextPrayerStrip({
    required this.s,
    required this.p,
    required this.nextPrayer,
    required this.timeToNext,
  });

  @override
  Widget build(BuildContext context) {
    final name = nextPrayer?.name ?? '';
    final iqamah = nextPrayer?.getIqamaTime();
    const muted = Color(0xFFBFDCCD);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 34 * s),
      decoration: BoxDecoration(
        color: DesignColors.green,
        borderRadius: BorderRadius.circular(100),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT PRAYER',
                  style: DesignText.latin(
                    size: 15 * s,
                    weight: FontWeight.w700,
                    color: muted,
                    letterSpacing: 1.2,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      name.isEmpty ? '—' : name,
                      style: DesignText.latin(
                        size: 32 * s,
                        weight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                        features: const [],
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    Text(
                      Bilingual.prayerArabic(name),
                      textDirection: TextDirection.rtl,
                      style: DesignText.arabic(
                        size: 24 * s,
                        weight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(width: 36 * s),
            Text(
              DesignTime.hms(timeToNext),
              style: DesignText.latin(
                size: 48 * s,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            if (iqamah != null) ...[
              SizedBox(width: 28 * s),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'IQAMAH',
                    style: DesignText.latin(
                      size: 15 * s,
                      weight: FontWeight.w700,
                      color: muted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TimeWithPeriod(
                    time: iqamah,
                    size: 26 * s,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────── Notices ─────────────────────────────

String _noticeLabel(NotificationType type) {
  switch (type) {
    case NotificationType.event:
      return 'EVENT';
    case NotificationType.alert:
      return 'ALERT';
    case NotificationType.announcement:
      return 'COMMUNITY NOTICE';
  }
}

final _arabicScript = RegExp(r'[؀-ۿ]');

class _NoticeCarousel extends StatefulWidget {
  final double s;
  final DesignPalette p;
  final List<MosqueNotification> notices;
  final PrayerTime? nextPrayer;
  final Duration timeToNext;
  final void Function(MosqueNotification)? onTap;

  const _NoticeCarousel({
    required this.s,
    required this.p,
    required this.notices,
    required this.nextPrayer,
    required this.timeToNext,
    this.onTap,
  });

  @override
  State<_NoticeCarousel> createState() => _NoticeCarouselState();
}

class _NoticeCarouselState extends State<_NoticeCarousel> {
  static const _interval = Duration(seconds: 10);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_interval, (_) {
      if (widget.notices.length > 1) {
        setState(() => _index = (_index + 1) % widget.notices.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final p = widget.p;
    final notices = widget.notices;
    if (_index >= notices.length) _index = 0;
    final current = notices.isEmpty ? null : notices[_index];
    // Image-only notices get tighter padding so the image can be larger.
    final imageOnly =
        current != null && current.hasImage && !current.hasMessage;
    final inset = imageOnly ? 22 * s : 42 * s;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(s, p),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: RingsPainter(
                center: const Offset(0.88, 0.15),
                radii: const [0.27, 0.33],
                color: p.divider,
                strokeWidth: 2.5,
              ),
            ),
          ),
          Padding(
            // Extra bottom room when the dots are shown, so content (e.g. an
            // image) never sits underneath them.
            padding: EdgeInsets.fromLTRB(
              inset,
              imageOnly ? 22 * s : 34 * s,
              inset,
              notices.length > 1
                  ? (imageOnly ? 54 * s : 66 * s)
                  : (imageOnly ? 22 * s : 30 * s),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child:
                  notices.isEmpty
                      ? _buildNextPrayerSlide(s)
                      : _buildNoticeSlide(s, notices[_index]),
            ),
          ),
          if (notices.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 30 * s,
              child: _Dots(s: s, p: p, count: notices.length, index: _index),
            ),
        ],
      ),
    );
  }

  Widget _buildNoticeSlide(double s, MosqueNotification n) {
    if (n.hasImage) return _buildImageSlide(s, n);

    final label = _noticeLabel(n.type);
    final isArabicMessage = _arabicScript.hasMatch(n.message);

    return GestureDetector(
      key: ValueKey(n.id),
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null ? null : () => widget.onTap!(n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chip(s, label),
          const Spacer(),
          Text(
            n.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DesignText.latin(
              size: 54 * s,
              weight: FontWeight.w800,
              color: widget.p.title,
              height: 1.08,
              features: const [],
            ),
          ),
          SizedBox(height: 22 * s),
          Container(width: 110 * s, height: 3 * s, color: DesignColors.gold),
          SizedBox(height: 22 * s),
          Text(
            n.message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textDirection:
                isArabicMessage ? TextDirection.rtl : TextDirection.ltr,
            style:
                isArabicMessage
                    ? DesignText.arabic(size: 26 * s, color: widget.p.ink)
                    : DesignText.latin(
                      size: 29 * s,
                      weight: FontWeight.w700,
                      color: widget.p.ink,
                    ),
          ),
          if (n.isEvent && n.eventTime != null) ...[
            SizedBox(height: 10 * s),
            Text(
              DateFormat('EEEE · h:mm a').format(n.eventTime!),
              style: DesignText.latin(
                size: 23 * s,
                weight: FontWeight.w600,
                color: widget.p.inkMuted,
              ),
            ),
          ],
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  /// A notice with an image: the image takes the place of the description
  /// and fills whatever height is left, keeping its proportions.
  Widget _buildImageSlide(double s, MosqueNotification n) {
    if (!n.hasMessage) return _buildImageOnlySlide(s, n);

    final label = _noticeLabel(n.type);

    return GestureDetector(
      key: ValueKey('${n.id}-image'),
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null ? null : () => widget.onTap!(n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chip(s, label),
          if (n.title.trim().isNotEmpty) ...[
            SizedBox(height: 16 * s),
            Text(
              n.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DesignText.latin(
                size: 40 * s,
                weight: FontWeight.w800,
                color: widget.p.title,
                height: 1.1,
                features: const [],
              ),
            ),
          ],
          SizedBox(height: 18 * s),
          Expanded(child: NoticeImage(notification: n, borderRadius: 18 * s)),
          if (n.isEvent && n.eventTime != null) ...[
            SizedBox(height: 12 * s),
            Text(
              DateFormat('EEEE · h:mm a').format(n.eventTime!),
              style: DesignText.latin(
                size: 23 * s,
                weight: FontWeight.w600,
                color: widget.p.inkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// A notice with only an image: 20% of the card for the header (chip,
  /// title, event time) and 80% for the image.
  Widget _buildImageOnlySlide(double s, MosqueNotification n) {
    final label = _noticeLabel(n.type);

    return GestureDetector(
      key: ValueKey('${n.id}-image-only'),
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null ? null : () => widget.onTap!(n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 20,
            // Shrinks to fit if a long title doesn't fit in the band; the
            // width cap keeps titles wrapping instead of shrinking to a line.
            child: LayoutBuilder(
              builder:
                  (context, c) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: c.maxWidth),
                      // Chip and title side by side to keep the band short.
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 18 * s,
                              vertical: 8 * s,
                            ),
                            decoration: BoxDecoration(
                              color: widget.p.chip,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              label,
                              style: DesignText.latin(
                                size: 18 * s,
                                weight: FontWeight.w700,
                                color: widget.p.chipText,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(width: 16 * s),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (n.title.trim().isNotEmpty)
                                  Text(
                                    n.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: DesignText.latin(
                                      size: 32 * s,
                                      weight: FontWeight.w800,
                                      color: widget.p.title,
                                      height: 1.1,
                                      features: const [],
                                    ),
                                  ),
                                if (n.isEvent && n.eventTime != null)
                                  Text(
                                    DateFormat(
                                      'EEEE · h:mm a',
                                    ).format(n.eventTime!),
                                    style: DesignText.latin(
                                      size: 20 * s,
                                      weight: FontWeight.w600,
                                      color: widget.p.inkMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
          SizedBox(height: 12 * s),
          Expanded(
            flex: 80,
            child: NoticeImage(notification: n, borderRadius: 18 * s),
          ),
        ],
      ),
    );
  }

  /// Shown when there are no active notices.
  Widget _buildNextPrayerSlide(double s) {
    final next = widget.nextPrayer;
    final iqamah = next?.getIqamaTime();
    return Column(
      key: const ValueKey('next-prayer'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chip(s, 'NEXT PRAYER', 'الصلاة القادمة'),
        const Spacer(),
        Text(
          next?.name ?? '—',
          style: DesignText.latin(
            size: 76 * s,
            weight: FontWeight.w800,
            color: widget.p.title,
            height: 1,
          ),
        ),
        Text(
          Bilingual.prayerArabic(next?.name ?? ''),
          textDirection: TextDirection.rtl,
          style: DesignText.arabic(size: 42 * s, color: widget.p.inkMuted),
        ),
        SizedBox(height: 20 * s),
        Container(width: 110 * s, height: 3 * s, color: DesignColors.gold),
        SizedBox(height: 20 * s),
        Text(
          DesignTime.hms(widget.timeToNext),
          style: DesignText.latin(
            size: 64 * s,
            weight: FontWeight.w800,
            color: widget.p.ink,
          ),
        ),
        if (iqamah != null) ...[
          Text(
            'Iqamah ${DateFormat('h:mm a').format(iqamah)}',
            style: DesignText.latin(
              size: 26 * s,
              weight: FontWeight.w600,
              color: widget.p.inkMuted,
            ),
          ),
          Text(
            'الإقامة ${Bilingual.timeArabic(iqamah)}',
            textDirection: TextDirection.rtl,
            style: DesignText.arabic(size: 22 * s, color: widget.p.inkMuted),
          ),
        ],
        const Spacer(flex: 2),
      ],
    );
  }

  /// Label chip, with an optional Arabic label beside it.
  Widget _chip(double s, String label, [String? labelAr]) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 9 * s),
          decoration: BoxDecoration(
            color: widget.p.chip,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            style: DesignText.latin(
              size: 19 * s,
              weight: FontWeight.w700,
              color: widget.p.chipText,
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (labelAr != null) ...[
          SizedBox(width: 16 * s),
          Flexible(
            child: Text(
              labelAr,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              style: DesignText.arabic(size: 20 * s, color: widget.p.chipText),
            ),
          ),
        ],
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final double s;
  final DesignPalette p;
  final int count;
  final int index;

  const _Dots({
    required this.s,
    required this.p,
    required this.count,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Too many dots won't fit; show a counter instead.
    if (count > 10) {
      return Text(
        '${index + 1} / $count',
        textAlign: TextAlign.center,
        style: DesignText.latin(
          size: 18 * s,
          weight: FontWeight.w700,
          color: p.inkMuted,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: 6 * s),
            width: (i == index ? 54 : 18) * s,
            height: 18 * s,
            decoration: BoxDecoration(
              color: i == index ? DesignColors.green : p.dotInactive,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
      ],
    );
  }
}

class _NoticeTicker extends StatefulWidget {
  final double s;
  final DesignPalette p;
  final List<MosqueNotification> notices;
  final void Function(MosqueNotification)? onTap;

  const _NoticeTicker({
    required this.s,
    required this.p,
    required this.notices,
    this.onTap,
  });

  @override
  State<_NoticeTicker> createState() => _NoticeTickerState();
}

class _NoticeTickerState extends State<_NoticeTicker> {
  static const _interval = Duration(seconds: 6);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_interval, (_) {
      if (widget.notices.length > 1) {
        setState(() => _index = (_index + 1) % widget.notices.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final p = widget.p;
    if (_index >= widget.notices.length) _index = 0;
    final n = widget.notices[_index];
    final text = n.getPreview(maxLength: 120);
    final isArabic = _arabicScript.hasMatch(text);

    return GestureDetector(
      onTap: widget.onTap == null ? null : () => widget.onTap!(n),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16 * s),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: p.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 28 * s,
                vertical: 14 * s,
              ),
              decoration: BoxDecoration(
                color: DesignColors.green,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Text(
                    'NOTICE',
                    style: DesignText.latin(
                      size: 22 * s,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 28 * s),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Align(
                  key: ValueKey(n.id),
                  alignment:
                      isArabic ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection:
                        isArabic ? TextDirection.rtl : TextDirection.ltr,
                    style:
                        isArabic
                            ? DesignText.arabic(size: 28 * s, color: p.ink)
                            : DesignText.latin(
                              size: 32 * s,
                              weight: FontWeight.w700,
                              color: p.ink,
                            ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16 * s),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Prayer table ──────────────────────────

Widget _prayerIcon(String name, double size, Color color) {
  final IconData icon;
  switch (name) {
    case 'Fajr':
      icon = Icons.wb_twilight;
    case 'Dhuhr':
      icon = Icons.light_mode_outlined;
    case 'Jummah':
      icon = Icons.groups_outlined;
    case 'Asr':
      icon = Icons.wb_cloudy_outlined;
    case 'Maghrib':
      return SunsetIcon(size: size, color: color);
    case 'Isha':
      icon = Icons.dark_mode_outlined;
    default:
      icon = Icons.access_time;
  }
  return Icon(icon, size: size, color: color);
}

/// Rows for the prayer tables. Jummah takes Dhuhr's place on Fridays and
/// is listed as an extra row on the other days.
List<PrayerTime> displayPrayers(PrayerSchedule? schedule) {
  if (schedule == null) return const [];
  final isFriday = DateTime.now().weekday == DateTime.friday;
  final all = schedule.getMainPrayers();
  PrayerTime? find(String name) {
    for (final p in all) {
      if (p.name == name) return p;
    }
    return null;
  }

  return [
    find('Fajr'),
    isFriday ? (find('Jummah') ?? find('Dhuhr')) : find('Dhuhr'),
    find('Asr'),
    find('Maghrib'),
    find('Isha'),
    if (!isFriday) find('Jummah'),
  ].whereType<PrayerTime>().toList();
}

class _PrayerTable extends StatelessWidget {
  final double s;
  final DesignPalette p;
  final PrayerSchedule? schedule;
  final PrayerTime? nextPrayer;

  const _PrayerTable({
    required this.s,
    required this.p,
    required this.schedule,
    required this.nextPrayer,
  });

  static const _nameFlex = 330;
  static const _timeFlex = 175;

  @override
  Widget build(BuildContext context) {
    final prayers = displayPrayers(schedule);

    return Container(
      padding: EdgeInsets.fromLTRB(24 * s, 20 * s, 24 * s, 20 * s),
      decoration: _cardDecoration(s, p),
      child: Column(
        children: [
          SizedBox(
            height: 68 * s,
            child: Row(
              children: [
                const Spacer(flex: _nameFlex),
                Expanded(
                  flex: _timeFlex * 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: DesignColors.green,
                      borderRadius: BorderRadius.circular(18 * s),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _headerCell('Begins', 'يبدأ')),
                        Container(
                          width: 1.5,
                          height: 44 * s,
                          color: Colors.white38,
                        ),
                        Expanded(child: _headerCell('Iqamah', 'الإقامة')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6 * s),
          for (var i = 0; i < prayers.length; i++) ...[
            if (i > 0 &&
                prayers[i].name != nextPrayer?.name &&
                prayers[i - 1].name != nextPrayer?.name)
              Divider(height: 1, color: p.divider)
            else if (i > 0)
              const SizedBox(height: 1),
            Expanded(child: _row(prayers[i])),
          ],
        ],
      ),
    );
  }

  Widget _headerCell(String en, String ar) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            en,
            style: DesignText.latin(
              size: 21 * s,
              weight: FontWeight.w700,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          Text(
            ar,
            textDirection: TextDirection.rtl,
            style: DesignText.arabic(
              size: 16 * s,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(PrayerTime prayer) {
    final highlighted = prayer.name == nextPrayer?.name;
    final fg = highlighted ? Colors.white : p.ink;
    final fgMuted = highlighted ? Colors.white70 : p.inkMuted;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14 * s),
      decoration:
          highlighted
              ? BoxDecoration(
                color: DesignColors.green,
                borderRadius: BorderRadius.circular(18 * s),
              )
              : null,
      child: Row(
        children: [
          Expanded(
            flex: _nameFlex,
            child: Row(
              children: [
                _prayerIcon(
                  prayer.name,
                  36 * s,
                  highlighted ? Colors.white : p.inkMuted,
                ),
                SizedBox(width: 18 * s),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: BilingualLabel(
                      english: prayer.name,
                      arabic: Bilingual.prayerArabic(prayer.name),
                      englishStyle: DesignText.latin(
                        size: 33 * s,
                        weight: FontWeight.w800,
                        color: fg,
                        height: 1.15,
                      ),
                      arabicStyle: DesignText.arabic(
                        size: 20 * s,
                        color: fgMuted,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: _timeFlex, child: _time(prayer.getWaqtTime(), fg)),
          Expanded(flex: _timeFlex, child: _time(prayer.getIqamaTime(), fg)),
        ],
      ),
    );
  }

  Widget _time(DateTime? t, Color color) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: TimeWithPeriod(
          time: t,
          size: 32 * s,
          color: color,
          periodScale: 0.55,
        ),
      ),
    );
  }
}

// ─────────────────────────── Donate tile ───────────────────────────

/// Compact donation QR code with a "Donate" label.
class _DonateTile extends StatelessWidget {
  final double s;
  final DesignPalette p;

  const _DonateTile({required this.s, required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(6 * s, 6 * s, 30 * s, 6 * s),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(26 * s),
        border: Border.all(color: p.border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // White tile in both themes: scanners need a light quiet zone.
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              padding: EdgeInsets.all(5 * s),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18 * s),
              ),
              child: Image.asset(
                MasjidInfo.donationQrAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                semanticLabel: 'Donation QR code',
                errorBuilder:
                    (context, error, stack) =>
                        CustomPaint(painter: _DashedRectPainter(radius: 8 * s)),
              ),
            ),
          ),
          SizedBox(width: 22 * s),
          Text(
            'Donate',
            style: DesignText.latin(
              size: 36 * s,
              weight: FontWeight.w800,
              color: p.title,
              features: const [],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final double radius;

  const _DashedRectPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = DesignColors.inkFaint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
        );
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 14) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => old.radius != radius;
}
