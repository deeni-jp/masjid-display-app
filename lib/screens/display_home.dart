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

class DisplayHome extends StatefulWidget {
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

  @override
  State<DisplayHome> createState() => _DisplayHomeState();
}

/// Image-only notices are too small to see in the notices card, so they're
/// shown full screen instead.
bool _isImageOnly(MosqueNotification n) => n.hasImage && !n.hasMessage;

/// One step of the notice rotation: a notice in the card, an image-only
/// notice full screen, or (notice == null) just the normal screen.
class _RotationStep {
  final MosqueNotification? notice;
  final bool fullScreen;
  final Duration duration;

  const _RotationStep(this.notice, this.duration, {this.fullScreen = false});
}

class _DisplayHomeState extends State<DisplayHome> {
  static const _cardInterval = Duration(seconds: 10);
  static const _maxCardInterval = Duration(seconds: 30);
  static const _fullScreenDuration = Duration(seconds: 5);

  /// Normal screen kept between two full-screen images, so the prayer times
  /// stay visible even if every notice is an image.
  static const _gapDuration = Duration(seconds: 10);

  Timer? _timer;
  int _step = 0;
  String? _cardNoticeId;
  MosqueNotification? _fullScreen;

  List<MosqueNotification> get _active =>
      widget.notifications.activeOnly.sortedByPriorityThenExpiry;

  /// Longer notices stay in the card longer, so they can be read.
  static Duration _cardDuration(MosqueNotification n) {
    final chars = n.title.length + n.message.length;
    final extraSeconds = ((chars - 120) / 25).ceil().clamp(0, 20);
    final d = _cardInterval + Duration(seconds: extraSeconds);
    return d > _maxCardInterval ? _maxCardInterval : d;
  }

  List<_RotationStep> _steps(List<MosqueNotification> active) {
    final steps = <_RotationStep>[];
    for (final n in active) {
      if (_isImageOnly(n)) {
        if (steps.isNotEmpty && steps.last.fullScreen) {
          steps.add(const _RotationStep(null, _gapDuration));
        }
        steps.add(_RotationStep(n, _fullScreenDuration, fullScreen: true));
      } else {
        steps.add(_RotationStep(n, _cardDuration(n)));
      }
    }
    // Also no two full-screen images in a row when the rotation wraps round.
    if (steps.isNotEmpty && steps.last.fullScreen && steps.first.fullScreen) {
      steps.add(const _RotationStep(null, _gapDuration));
    }
    return steps;
  }

  @override
  void initState() {
    super.initState();
    _showStep(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showStep(int index) {
    _timer?.cancel();
    final steps = _steps(_active);
    if (steps.isEmpty) {
      _step = 0;
      _fullScreen = null;
      _timer = Timer(_cardInterval, _next);
      return;
    }
    _step = index % steps.length;
    final step = steps[_step];
    _fullScreen = step.fullScreen ? step.notice : null;
    if (!step.fullScreen && step.notice != null) {
      _cardNoticeId = step.notice!.id;
    }
    _timer = Timer(step.duration, _next);
  }

  void _next() {
    if (!mounted) return;
    setState(() => _showStep(_step + 1));
  }

  /// Reference size of the design canvas; everything scales from it.
  static const double _designWidth = 2000;
  static const double _designHeight = 1125;

  /// Height of the footer row (ticker + donate tile).
  static const double _footerHeight = 146;

  @override
  Widget build(BuildContext context) {
    final prayerSchedule = widget.prayerSchedule;
    final nextPrayer = widget.nextPrayer;
    final timeToNext = widget.timeToNext;
    final darkMode = widget.darkMode;
    final active = _active;
    final cardNotices = active.where((n) => !_isImageOnly(n)).toList();
    var cardIndex = cardNotices.indexWhere((n) => n.id == _cardNoticeId);
    if (cardIndex < 0) cardIndex = 0;
    // The ticker scrolls announcements and alerts (not events or images).
    final tickerNotices =
        active.where((n) => n.hasMessage && !n.isEvent).toList();
    final p = DesignPalette.of(darkMode);
    // A deleted/expired notice disappears from full screen straight away.
    final fullScreen =
        _fullScreen == null
            ? null
            : active.where((n) => n.id == _fullScreen!.id).firstOrNull;

    return Stack(
      children: [
        _buildScreen(
          context,
          p: p,
          prayerSchedule: prayerSchedule,
          nextPrayer: nextPrayer,
          timeToNext: timeToNext,
          cardNotices: cardNotices,
          cardIndex: cardIndex,
          tickerNotices: tickerNotices,
        ),
        // Drawn inside the home screen, so the prayer screens (iqamah
        // countdown etc., drawn above the whole page) always cover it.
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child:
                fullScreen == null
                    ? const SizedBox.shrink()
                    : _FullScreenNotice(
                      key: ValueKey('fullscreen-${fullScreen.id}'),
                      notice: fullScreen,
                      onClose: () => setState(() => _fullScreen = null),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreen(
    BuildContext context, {
    required DesignPalette p,
    required PrayerSchedule? prayerSchedule,
    required PrayerTime? nextPrayer,
    required Duration timeToNext,
    required List<MosqueNotification> cardNotices,
    required int cardIndex,
    required List<MosqueNotification> tickerNotices,
  }) {
    final onOpenSettings = widget.onOpenSettings;
    final onNotificationTap = widget.onNotificationTap;
    final hijriDate = widget.hijriDate;

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
                            if (cardNotices.isNotEmpty) ...[
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
                                notices: cardNotices,
                                index: cardIndex,
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

/// "Friday 17 Oct · 7:30 PM" for events with a time; for weekly events
/// "Every Friday · 7:30 PM · next 17 Oct".
String? _eventText(MosqueNotification n) {
  final time = n.nextEventTime();
  if (!n.isEvent || time == null) return null;
  if (n.isRepeating) {
    return '${n.repeatLabel} · ${DateFormat('h:mm a').format(time)}'
        ' · next ${DateFormat('d MMM').format(time)}';
  }
  return DateFormat('EEEE d MMM · h:mm a').format(time);
}

final _arabicScript = RegExp(r'[؀-ۿ]');

class _NoticeCarousel extends StatefulWidget {
  final double s;
  final DesignPalette p;

  /// Notices for the card (not image-only ones) and the one to show; the
  /// rotation is run by [DisplayHome].
  final List<MosqueNotification> notices;
  final int index;
  final PrayerTime? nextPrayer;
  final Duration timeToNext;
  final void Function(MosqueNotification)? onTap;

  const _NoticeCarousel({
    required this.s,
    required this.p,
    required this.notices,
    required this.index,
    required this.nextPrayer,
    required this.timeToNext,
    this.onTap,
  });

  @override
  State<_NoticeCarousel> createState() => _NoticeCarouselState();
}

class _NoticeCarouselState extends State<_NoticeCarousel> {
  @override
  void initState() {
    super.initState();
    // Text is measured to fit the card; measure again once the display
    // fonts have loaded.
    PaintingBinding.instance.systemFonts.addListener(_onFontsChanged);
  }

  void _onFontsChanged() {
    if (mounted) setState(() {});
  }

  bool _isArabic(String text) => _arabicScript.hasMatch(text);

  TextStyle _messageStyle(String message, double size) {
    if (_isArabic(message)) {
      return DesignText.arabic(size: size * 0.9, color: widget.p.ink);
    }
    return DesignText.latin(
      size: size,
      // Bold at the design size; lighter when shrunk for long text.
      weight: size >= 26 * widget.s ? FontWeight.w700 : FontWeight.w600,
      color: widget.p.ink,
      height: 1.3,
    );
  }

  /// The largest message size (from [maxSize] down to [minSize]) at which the
  /// whole message fits in [maxHeight], and how many lines fit at that size.
  /// If it doesn't fit even at [minSize], the text ends with an ellipsis.
  _MessageFit _fitMessage(
    BuildContext context,
    String message, {
    required double maxSize,
    required double minSize,
    required double width,
    required double maxHeight,
  }) {
    final textScaler = MediaQuery.textScalerOf(context);
    // Text widgets merge their style into the inherited default (e.g. its
    // letter spacing), so measure with the same merged style.
    final inherited = DefaultTextStyle.of(context).style;
    final direction =
        _isArabic(message) ? TextDirection.rtl : TextDirection.ltr;
    TextPainter layout(TextStyle style, String text, [int? maxLines]) =>
        TextPainter(
          text: TextSpan(text: text, style: inherited.merge(style)),
          textDirection: direction,
          textScaler: textScaler,
          maxLines: maxLines,
        )..layout(maxWidth: width);

    final step = (maxSize - minSize) / 8;
    var size = maxSize;
    while (size - step >= minSize - 0.01 && step > 0) {
      if (layout(_messageStyle(message, size), message).height <= maxHeight) {
        break;
      }
      size -= step;
    }
    final style = _messageStyle(message, size);
    final lineHeight = layout(style, 'Hg').height;
    return _MessageFit(
      style: style,
      maxLines: (maxHeight / lineHeight).floor().clamp(1, 1000),
    );
  }

  /// The description, at most [maxHeight] tall. maxLines guarantees an
  /// ellipsis (rather than a silently cut-off line) if it's too long.
  Widget _messageText(MosqueNotification n, _MessageFit fit, double maxHeight) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight < 0 ? 0 : maxHeight),
      child: Text(
        n.message,
        maxLines: fit.maxLines,
        overflow: TextOverflow.ellipsis,
        textDirection:
            _isArabic(n.message) ? TextDirection.rtl : TextDirection.ltr,
        style: fit.style,
      ),
    );
  }

  double _measure(
    BuildContext context,
    String text,
    TextStyle style,
    double width, {
    int? maxLines,
  }) {
    return (TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: maxLines,
    )..layout(maxWidth: width)).height;
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_onFontsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final p = widget.p;
    final notices = widget.notices;
    final index = notices.isEmpty ? 0 : widget.index % notices.length;

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
              42 * s,
              34 * s,
              42 * s,
              notices.length > 1 ? 66 * s : 30 * s,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child:
                  notices.isEmpty
                      ? _buildNextPrayerSlide(s)
                      : _buildNoticeSlide(s, notices[index]),
            ),
          ),
          if (notices.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 30 * s,
              child: _Dots(s: s, p: p, count: notices.length, index: index),
            ),
        ],
      ),
    );
  }

  Widget _buildNoticeSlide(double s, MosqueNotification n) {
    if (n.hasImage) return _buildImageSlide(s, n);

    final label = _noticeLabel(n.type);
    final eventText = _eventText(n);
    final eventStyle = DesignText.latin(
      size: 23 * s,
      weight: FontWeight.w600,
      color: widget.p.inkMuted,
    );
    final hasTitle = n.title.trim().isNotEmpty;

    return GestureDetector(
      key: ValueKey(n.id),
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null ? null : () => widget.onTap!(n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chip(s, label),
          SizedBox(height: 20 * s),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                // Long descriptions get a shorter title and smaller text so
                // the whole notice fits; short ones keep the design sizes.
                final longMessage = n.message.length > 160;
                final titleStyle = DesignText.latin(
                  size: (longMessage ? 42 : 54) * s,
                  weight: FontWeight.w800,
                  color: widget.p.title,
                  height: 1.08,
                  features: const [],
                );
                final titleHeight =
                    hasTitle
                        ? _measure(
                          context,
                          n.title,
                          titleStyle,
                          c.maxWidth,
                          maxLines: 2,
                        )
                        : 0.0;
                final eventHeight =
                    eventText == null
                        ? 0.0
                        : 10 * s +
                            _measure(
                              context,
                              eventText,
                              eventStyle,
                              c.maxWidth,
                            );
                final ruleHeight = hasTitle ? 2 * 18 * s + 3 * s : 0.0;
                // A few pixels of slack for rounding.
                final available =
                    c.maxHeight - titleHeight - ruleHeight - eventHeight - 4;
                final fit = _fitMessage(
                  context,
                  n.message,
                  maxSize: 29 * s,
                  minSize: 19 * s,
                  width: c.maxWidth,
                  maxHeight: available,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    if (hasTitle) ...[
                      Text(
                        n.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      SizedBox(height: 18 * s),
                      Container(
                        width: 110 * s,
                        height: 3 * s,
                        color: DesignColors.gold,
                      ),
                      SizedBox(height: 18 * s),
                    ],
                    _messageText(n, fit, available),
                    if (eventText != null) ...[
                      SizedBox(height: 10 * s),
                      Text(eventText, style: eventStyle),
                    ],
                    const Spacer(flex: 2),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// A notice with an image and a description: the description on top, the
  /// image filling the rest, keeping its proportions.
  Widget _buildImageSlide(double s, MosqueNotification n) {
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
          // The description gets up to a third of the space; the image
          // keeps the rest.
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final fit = _fitMessage(
                  context,
                  n.message,
                  maxSize: 26 * s,
                  minSize: 19 * s,
                  width: c.maxWidth,
                  maxHeight: c.maxHeight / 3,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _messageText(n, fit, c.maxHeight / 3),
                    SizedBox(height: 16 * s),
                    Expanded(
                      child: NoticeImage(notification: n, borderRadius: 18 * s),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_eventText(n) case final eventText?) ...[
            SizedBox(height: 12 * s),
            Text(
              eventText,
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

/// How a notice description is drawn so it fits its space.
class _MessageFit {
  final TextStyle style;

  /// Lines that fit in the space at [style].
  final int maxLines;

  const _MessageFit({required this.style, required this.maxLines});
}

/// An image-only notice shown over the whole display for a few seconds.
class _FullScreenNotice extends StatelessWidget {
  final MosqueNotification notice;
  final VoidCallback onClose;

  const _FullScreenNotice({
    super.key,
    required this.notice,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final eventText = _eventText(notice);
    final hasTitle = notice.title.trim().isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: ColoredBox(
        color: DesignColors.greenDeep,
        child: LayoutBuilder(
          builder: (context, c) {
            // Same scale as the display layout (design width 2000).
            final s = c.maxWidth / 2000;
            return Padding(
              padding: EdgeInsets.fromLTRB(40 * s, 36 * s, 40 * s, 28 * s),
              child: Column(
                children: [
                  Expanded(
                    child: NoticeImage(
                      notification: notice,
                      borderRadius: 20 * s,
                    ),
                  ),
                  SizedBox(height: 22 * s),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20 * s,
                          vertical: 9 * s,
                        ),
                        decoration: BoxDecoration(
                          color: DesignColors.gold,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          _noticeLabel(notice.type),
                          style: DesignText.latin(
                            size: 20 * s,
                            weight: FontWeight.w700,
                            color: DesignColors.greenDeep,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      if (hasTitle) ...[
                        SizedBox(width: 22 * s),
                        Flexible(
                          child: Text(
                            notice.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DesignText.latin(
                              size: 40 * s,
                              weight: FontWeight.w800,
                              color: Colors.white,
                              features: const [],
                            ),
                          ),
                        ),
                      ],
                      if (eventText != null) ...[
                        SizedBox(width: 22 * s),
                        Text(
                          eventText,
                          style: DesignText.latin(
                            size: 28 * s,
                            weight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
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
