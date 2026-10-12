// lib/screens/home_tab.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../models/prayer_time.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../models/hijri_date.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../utils/design.dart';
import '../widgets/notice_image.dart';
import 'display_home.dart';

/// Home tab. Shows the masjid display on large screens
/// (design/screens/1 · Home display) and the mobile home otherwise
/// (design/screens/6 · Mobile app).
class HomeTab extends StatelessWidget {
  final LocationData? locationData;
  final PrayerSchedule? prayerSchedule;
  final PrayerTime? nextPrayer;
  final Duration timeToNext;
  final List<MosqueNotification> notifications;
  final bool darkMode;
  final Future<void> Function() onRefresh;
  final AppUser currentUser;
  final void Function(AppUser?) onUserChanged;
  final void Function(MosqueNotification)? onNotificationTap;
  final HijriDate? hijriDate;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenNotices;

  const HomeTab({
    super.key,
    required this.locationData,
    required this.prayerSchedule,
    required this.nextPrayer,
    required this.timeToNext,
    required this.notifications,
    required this.darkMode,
    required this.onRefresh,
    required this.currentUser,
    required this.onUserChanged,
    this.onNotificationTap,
    this.hijriDate,
    this.onOpenSettings,
    this.onOpenNotices,
  });

  /// Active notices for the rotating card: high priority first, then the
  /// rest, newest first within each group.
  List<MosqueNotification> get _cardNotices {
    final active = notifications.activeOnly;
    return [
      ...active.highPriorityOnly.sortedByNewest,
      ...active.excludingHighPriority.sortedByNewest,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (isDisplayLayout(context)) {
      return DisplayHome(
        prayerSchedule: prayerSchedule,
        nextPrayer: nextPrayer,
        timeToNext: timeToNext,
        notifications: notifications,
        hijriDate: hijriDate,
        onOpenSettings: onOpenSettings,
        onNotificationTap: onNotificationTap,
        darkMode: darkMode,
      );
    }

    final p = DesignPalette.of(darkMode);
    final notices = _cardNotices;

    return ColoredBox(
      color: p.background,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: DesignColors.green,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _buildHeader(p),
            const SizedBox(height: 22),
            _buildNextPrayerCard(),
            const SizedBox(height: 16),
            _buildPrayerList(p),
            if (notices.isNotEmpty) ...[
              const SizedBox(height: 16),
              _RotatingNoticeCard(
                notices: notices,
                palette: p,
                builder: (notice) => _buildNoticeCard(p, notice),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DesignPalette p) {
    return Row(
      children: [
        Expanded(
          child: Text(
            MasjidInfo.name,
            style: DesignText.latin(
              size: 24,
              weight: FontWeight.w800,
              color: p.title,
              height: 1.15,
              features: const [],
            ),
          ),
        ),
        Material(
          color: p.surface,
          shape: CircleBorder(side: BorderSide(color: p.border)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onOpenNotices,
            child: SizedBox(
              width: 50,
              height: 50,
              child: Icon(
                Icons.notifications_none_rounded,
                color: p.title,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextPrayerCard() {
    final name = nextPrayer?.name ?? '';
    final iqamah = nextPrayer?.getIqamaTime();
    const labelColor = Color(0xFFBFDCCD);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: DesignColors.green,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NEXT PRAYER',
                style: DesignText.latin(
                  size: 13,
                  weight: FontWeight.w700,
                  color: labelColor,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                'الصلاة القادمة',
                textDirection: TextDirection.rtl,
                style: DesignText.arabic(size: 14, color: labelColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                name.isEmpty ? '—' : name,
                style: DesignText.latin(
                  size: 34,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  features: const [],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                Bilingual.prayerArabic(name),
                textDirection: TextDirection.rtl,
                style: DesignText.arabic(
                  size: 26,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              DesignTime.hms(timeToNext),
              style: DesignText.latin(
                size: 50,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                iqamah != null
                    ? 'Iqamah ${DateFormat('h:mm a').format(iqamah)}'
                    : 'Iqamah',
                style: DesignText.latin(
                  size: 15,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (iqamah != null)
                Text(
                  'الإقامة ${Bilingual.timeArabic(iqamah)}',
                  textDirection: TextDirection.rtl,
                  style: DesignText.arabic(size: 14, color: Colors.white),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerList(DesignPalette p) {
    final prayers = displayPrayers(prayerSchedule);
    if (prayers.isEmpty) return const SizedBox.shrink();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < prayers.length; i++) ...[
            if (i > 0 &&
                prayers[i].name != nextPrayer?.name &&
                prayers[i - 1].name != nextPrayer?.name)
              Divider(height: 1, indent: 16, endIndent: 16, color: p.divider),
            _buildPrayerRow(p, prayers[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayerRow(DesignPalette p, PrayerTime prayer) {
    final highlighted = prayer.name == nextPrayer?.name;
    final nameColor = highlighted ? p.highlightText : p.ink;

    String fmt(DateTime? t) =>
        t == null
            ? PrayerTime.trimTime(prayer.waqt)
            : DateFormat('h:mm a').format(t);

    return Container(
      color: highlighted ? p.highlight : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  prayer.name,
                  style: DesignText.latin(
                    size: 17,
                    weight: FontWeight.w700,
                    color: nameColor,
                    features: const [],
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    Bilingual.prayerArabic(prayer.name),
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: DesignText.arabic(size: 14, color: nameColor),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 92,
            child: Text(
              fmt(prayer.getWaqtTime()),
              textAlign: TextAlign.right,
              style: DesignText.latin(
                size: 16,
                weight: FontWeight.w500,
                color: highlighted ? p.highlightText : p.inkMuted,
              ),
            ),
          ),
          SizedBox(
            width: 92,
            child: Text(
              fmt(prayer.getIqamaTime()),
              textAlign: TextAlign.right,
              style: DesignText.latin(
                size: 16,
                weight: FontWeight.w800,
                color: nameColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(DesignPalette p, MosqueNotification notice) {
    final hasArabic = RegExp(r'[؀-ۿ]').hasMatch(notice.message);
    final label = notice.isHighPriority ? 'IMPORTANT' : 'NOTICE';
    final labelColor =
        notice.isHighPriority
            ? DesignColors.red
            : (darkMode ? DesignColors.goldBright : DesignColors.goldText);

    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: p.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap:
            onNotificationTap == null ? null : () => onNotificationTap!(notice),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: DesignText.latin(
                      size: 13,
                      weight: FontWeight.w700,
                      color: labelColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              if (notice.title.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  notice.title,
                  style: DesignText.latin(
                    size: 18,
                    weight: FontWeight.w700,
                    color: p.ink,
                    height: 1.3,
                    features: const [],
                  ),
                ),
              ],
              // An image takes the place of the description.
              if (notice.hasImage) ...[
                const SizedBox(height: 10),
                NoticeImage(notification: notice, maxHeight: 220),
              ] else if (notice.hasMessage &&
                  notice.message.trim() != notice.title.trim()) ...[
                const SizedBox(height: 4),
                Text(
                  notice.getPreview(maxLength: 140),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textDirection: hasArabic ? TextDirection.rtl : null,
                  style:
                      hasArabic
                          ? DesignText.arabic(size: 15, color: p.inkMuted)
                          : DesignText.latin(
                            size: 14,
                            weight: FontWeight.w500,
                            color: p.inkMuted,
                            height: 1.4,
                            features: const [],
                          ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Cycles through [notices] every few seconds, with position dots.
class _RotatingNoticeCard extends StatefulWidget {
  final List<MosqueNotification> notices;
  final DesignPalette palette;
  final Widget Function(MosqueNotification) builder;

  const _RotatingNoticeCard({
    required this.notices,
    required this.palette,
    required this.builder,
  });

  @override
  State<_RotatingNoticeCard> createState() => _RotatingNoticeCardState();
}

class _RotatingNoticeCardState extends State<_RotatingNoticeCard> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(AppConstants.notificationRotationInterval, (_) {
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
    final notices = widget.notices;
    if (_index >= notices.length) _index = 0;
    final notice = notices[_index];

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            layoutBuilder:
                (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, if (current != null) current],
                ),
            child: KeyedSubtree(
              key: ValueKey(notice.id),
              child: widget.builder(notice),
            ),
          ),
        ),
        if (notices.length > 10) ...[
          const SizedBox(height: 8),
          Text(
            '${_index + 1} / ${notices.length}',
            style: DesignText.latin(
              size: 12,
              weight: FontWeight.w600,
              color: widget.palette.inkMuted,
            ),
          ),
        ] else if (notices.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < notices.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        i == _index
                            ? DesignColors.green
                            : widget.palette.dotInactive,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
