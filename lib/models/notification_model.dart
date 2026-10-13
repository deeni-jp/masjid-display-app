// lib/models/notification_model.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Notification types for categorization
enum NotificationType {
  announcement,
  event,
  alert;

  String get displayName {
    switch (this) {
      case NotificationType.announcement:
        return 'Announcement';
      case NotificationType.event:
        return 'Event';
      case NotificationType.alert:
        return 'Alert';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.event:
        return Icons.event;
      case NotificationType.alert:
        return Icons.warning_amber_rounded;
    }
  }

  static NotificationType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'event':
        return NotificationType.event;
      case 'alert':
        return NotificationType.alert;
      default:
        return NotificationType.announcement;
    }
  }

  String toFirestore() => name;
}

/// Priority levels for notifications
enum NotificationPriority {
  high,
  regular,
  low;

  String get displayName {
    switch (this) {
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.regular:
        return 'Regular';
      case NotificationPriority.low:
        return 'Low';
    }
  }

  /// Base color for priority (used when type is not alert)
  Color get color {
    switch (this) {
      case NotificationPriority.high:
        return const Color(0xFFFF9800); // Orange for high priority
      case NotificationPriority.regular:
        return const Color(0xFF1E88E5); // Blue
      case NotificationPriority.low:
        return const Color(0xFF757575); // Gray
    }
  }

  Color get backgroundColor {
    switch (this) {
      case NotificationPriority.high:
        return const Color(0xFFFFF3E0); // Light Orange
      case NotificationPriority.regular:
        return const Color(0xFFE3F2FD); // Light Blue
      case NotificationPriority.low:
        return const Color(0xFFF5F5F5); // Light Gray
    }
  }

  static NotificationPriority fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return NotificationPriority.high;
      case 'low':
        return NotificationPriority.low;
      default:
        return NotificationPriority.regular;
    }
  }

  String toFirestore() => name;
}

class MosqueNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final bool active;
  final String postedBy; // Email stored in database (not shown in UI)
  final String postedByRole; // Role to display (Admin/Moderator)
  final DateTime createdAt;
  final DateTime? eventTime; // For event-type notifications
  final DateTime expiresAt; // Expiration date - notification deleted after this

  // Optional image. The bytes live in a separate document
  // (mosque/data/notification_images/{id}); these fields describe it so the
  // UI can reserve the right space before it loads.
  final bool hasImage;
  final int? imageWidth;
  final int? imageHeight;
  final DateTime? imageUpdatedAt; // Changes whenever the image is replaced

  // Weekly repeating events (e.g. every Friday at 19:30). Only the rule is
  // stored; the next date is worked out on each device, so nothing has to
  // run or be written every week.
  final List<int> repeatWeekdays; // DateTime.weekday values, 1 = Mon … 7 = Sun
  final String? repeatTime; // "HH:mm", 24-hour
  final DateTime? repeatUntil; // Last day it repeats (optional)

  MosqueNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.active,
    required this.postedBy,
    this.postedByRole = 'Staff',
    required this.createdAt,
    this.eventTime,
    required this.expiresAt,
    this.hasImage = false,
    this.imageWidth,
    this.imageHeight,
    this.imageUpdatedAt,
    this.repeatWeekdays = const [],
    this.repeatTime,
    this.repeatUntil,
  });

  /// Create empty notification
  factory MosqueNotification.empty() {
    return MosqueNotification(
      id: '',
      title: '',
      message: '',
      type: NotificationType.announcement,
      priority: NotificationPriority.regular,
      active: false,
      postedBy: '',
      postedByRole: 'Staff',
      createdAt: DateTime.now(),
      eventTime: null,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
  }

  /// Create a new notification with generated ID
  factory MosqueNotification.create({
    required String title,
    required String message,
    required NotificationType type,
    required NotificationPriority priority,
    required String postedBy,
    required String postedByRole,
    DateTime? eventTime,
    required DateTime expiresAt,
    bool hasImage = false,
    int? imageWidth,
    int? imageHeight,
    DateTime? imageUpdatedAt,
  }) {
    return MosqueNotification(
      id: '', // Will be set by Firestore
      title: title,
      message: message,
      type: type,
      priority: priority,
      active: true,
      postedBy: postedBy,
      postedByRole: postedByRole,
      createdAt: DateTime.now(),
      eventTime: eventTime,
      expiresAt: expiresAt,
      hasImage: hasImage,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      imageUpdatedAt: imageUpdatedAt,
    );
  }

  /// Backward-compatible factory for legacy code using timestamp parameter
  factory MosqueNotification.legacy({
    String? id,
    required String title,
    required String message,
    required bool active,
    required String postedBy,
    required DateTime timestamp,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? eventTime,
    DateTime? expiresAt,
  }) {
    return MosqueNotification(
      id: id ?? '',
      title: title,
      message: message,
      type: type ?? NotificationType.announcement,
      priority: priority ?? NotificationPriority.regular,
      active: active,
      postedBy: postedBy,
      postedByRole: 'Staff',
      createdAt: timestamp,
      eventTime: eventTime,
      expiresAt:
          expiresAt ?? timestamp.add(AppConstants.defaultAnnouncementExpiry),
    );
  }

  /// Create from Firestore document
  factory MosqueNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      return MosqueNotification.empty();
    }

    return MosqueNotification(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      type: NotificationType.fromString(data['type']?.toString()),
      priority: NotificationPriority.fromString(data['priority']?.toString()),
      active: data['active'] == true,
      postedBy: data['postedBy']?.toString() ?? '',
      postedByRole: data['postedByRole']?.toString() ?? 'Staff',
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      eventTime: _parseDateTime(data['eventTime']),
      expiresAt:
          _parseDateTime(data['expiresAt']) ??
          DateTime.now().add(const Duration(days: 7)),
      hasImage: data['hasImage'] == true,
      imageWidth: (data['imageWidth'] as num?)?.toInt(),
      imageHeight: (data['imageHeight'] as num?)?.toInt(),
      imageUpdatedAt: _parseDateTime(data['imageUpdatedAt']),
      repeatWeekdays: _parseWeekdays(data['repeatWeekdays']),
      repeatTime: _parseRepeatTime(data['repeatTime']),
      repeatUntil: _parseDateTime(data['repeatUntil']),
    );
  }

  /// Create from Map (for local storage)
  factory MosqueNotification.fromMap(Map<String, dynamic> map) {
    return MosqueNotification(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: NotificationType.fromString(map['type']?.toString()),
      priority: NotificationPriority.fromString(map['priority']?.toString()),
      active: map['active'] == true,
      postedBy: map['postedBy']?.toString() ?? '',
      postedByRole: map['postedByRole']?.toString() ?? 'Staff',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      eventTime:
          map['eventTime'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['eventTime'])
              : null,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        map['expiresAt'] ??
            DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
      ),
      hasImage: map['hasImage'] == true,
      imageWidth: (map['imageWidth'] as num?)?.toInt(),
      imageHeight: (map['imageHeight'] as num?)?.toInt(),
      imageUpdatedAt:
          map['imageUpdatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['imageUpdatedAt'])
              : null,
      repeatWeekdays: _parseWeekdays(map['repeatWeekdays']),
      repeatTime: _parseRepeatTime(map['repeatTime']),
      repeatUntil:
          map['repeatUntil'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['repeatUntil'])
              : null,
    );
  }

  /// Create from JSON string
  factory MosqueNotification.fromJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return MosqueNotification.fromMap(json);
    } catch (_) {
      return MosqueNotification.empty();
    }
  }

  /// Parse DateTime from various Firestore formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      final ms = int.tryParse(value);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return null;
  }

  /// Valid, sorted, de-duplicated weekdays (1–7).
  static List<int> _parseWeekdays(dynamic value) {
    if (value is! List) return const [];
    final days =
        value
            .map((d) => d is num ? d.toInt() : int.tryParse('$d'))
            .whereType<int>()
            .where((d) => d >= DateTime.monday && d <= DateTime.sunday)
            .toSet()
            .toList()
          ..sort();
    return days;
  }

  /// "HH:mm" if valid, else null.
  static String? _parseRepeatTime(dynamic value) {
    if (value is! String) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]), m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Convert to Map for local storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toFirestore(),
      'priority': priority.toFirestore(),
      'active': active,
      'postedBy': postedBy,
      'postedByRole': postedByRole,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'eventTime': eventTime?.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'hasImage': hasImage,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'imageUpdatedAt': imageUpdatedAt?.millisecondsSinceEpoch,
      'repeatWeekdays': repeatWeekdays,
      'repeatTime': repeatTime,
      'repeatUntil': repeatUntil?.millisecondsSinceEpoch,
    };
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toMap());
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    return {
      'title': title,
      'message': message,
      'type': type.toFirestore(),
      'priority': priority.toFirestore(),
      'active': active,
      'postedBy': postedBy,
      'postedByRole': postedByRole,
      'createdAt':
          useServerTimestamp
              ? FieldValue.serverTimestamp()
              : Timestamp.fromDate(createdAt),
      'eventTime': eventTime != null ? Timestamp.fromDate(eventTime!) : null,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'hasImage': hasImage,
      'imageWidth': hasImage ? imageWidth : null,
      'imageHeight': hasImage ? imageHeight : null,
      'imageUpdatedAt':
          hasImage && imageUpdatedAt != null
              ? Timestamp.fromDate(imageUpdatedAt!)
              : null,
      'repeatWeekdays': isRepeating ? repeatWeekdays : null,
      'repeatTime': isRepeating ? repeatTime : null,
      'repeatUntil':
          isRepeating && repeatUntil != null
              ? Timestamp.fromDate(repeatUntil!)
              : null,
    };
  }

  /// Get message preview (first line or truncated)
  String getPreview({int maxLength = 100}) {
    if (message.isEmpty) return '';

    // Get first line
    final firstLine = message.split('\n').first;

    // Truncate if too long
    if (firstLine.length > maxLength) {
      return '${firstLine.substring(0, maxLength)}...';
    }

    return firstLine;
  }

  /// Whether there is a text description
  bool get hasMessage => message.trim().isNotEmpty;

  /// Check if notification has content (a description, an image, or both)
  bool get hasContent => hasMessage || hasImage;

  /// Width / height of the image, if known
  double? get imageAspectRatio {
    final w = imageWidth, h = imageHeight;
    if (!hasImage || w == null || h == null || w <= 0 || h <= 0) return null;
    return w / h;
  }

  /// Check if notification should be shown
  bool get shouldShow => active && hasContent && !isExpired;

  /// Check if notification is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if notification is high priority
  bool get isHighPriority => priority == NotificationPriority.high;

  /// Check if this is an event notification
  bool get isEvent => type == NotificationType.event;

  /// Whether this is a weekly repeating event.
  bool get isRepeating =>
      isEvent && repeatWeekdays.isNotEmpty && repeatTime != null;

  /// How long a repeating event keeps showing "today" after it starts.
  static const repeatGrace = Duration(hours: 1);

  /// When the event (next) takes place: for a repeating event, the next
  /// occurrence that started no more than [repeatGrace] ago, or null after
  /// [repeatUntil]; otherwise [eventTime].
  DateTime? nextEventTime([DateTime? now]) {
    if (!isRepeating) return eventTime;
    now ??= DateTime.now();
    final parts = repeatTime!.split(':');
    final hour = int.parse(parts[0]), minute = int.parse(parts[1]);
    final until = repeatUntil;
    final lastDay =
        until == null ? null : DateTime(until.year, until.month, until.day);

    for (var offset = 0; offset <= 7; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset);
      if (!repeatWeekdays.contains(day.weekday)) continue;
      if (lastDay != null && day.isAfter(lastDay)) return null;
      final start = DateTime(day.year, day.month, day.day, hour, minute);
      if (start.add(repeatGrace).isAfter(now)) return start;
    }
    return null;
  }

  /// "Every Friday", "Every Sat & Sun", "Every Mon, Wed & Fri".
  String? get repeatLabel {
    if (!isRepeating) return null;
    const full = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (repeatWeekdays.length == 7) return 'Every day';
    if (repeatWeekdays.length == 1) {
      return 'Every ${full[repeatWeekdays.first - 1]}';
    }
    final names = repeatWeekdays.map((d) => short[d - 1]).toList();
    final last = names.removeLast();
    return 'Every ${names.join(', ')} & $last';
  }

  /// Check if this is an alert notification
  bool get isAlert => type == NotificationType.alert;

  /// Get the effective priority color (red for alerts, otherwise priority color)
  Color get effectivePriorityColor {
    if (isAlert && isHighPriority) {
      return const Color(0xFFE53935); // Red for high priority alerts
    }
    return priority.color;
  }

  /// Get the effective priority background color
  Color get effectivePriorityBgColor {
    if (isAlert && isHighPriority) {
      return const Color(0xFFFFEBEE); // Light red for high priority alerts
    }
    return priority.backgroundColor;
  }

  /// Get time remaining until expiry
  Duration get timeUntilExpiry {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }

  /// Backward compatibility getter for timestamp (use createdAt instead)
  @Deprecated('Use createdAt instead')
  DateTime get timestamp => createdAt;

  /// Get formatted expiry text
  String get expiryText {
    final duration = timeUntilExpiry;
    if (duration == Duration.zero) return 'Expired';
    // Weekly events run until switched off or their end date.
    if (isRepeating && duration.inDays >= 7) return 'Weekly';

    if (duration.inDays > 0) {
      return '${duration.inDays}d left';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h left';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m left';
    } else {
      return 'Expiring soon';
    }
  }

  /// Copy with new values
  MosqueNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    bool? active,
    String? postedBy,
    String? postedByRole,
    DateTime? createdAt,
    DateTime? eventTime,
    DateTime? expiresAt,
    bool? hasImage,
    int? imageWidth,
    int? imageHeight,
    DateTime? imageUpdatedAt,
    List<int>? repeatWeekdays,
    String? repeatTime,
    DateTime? repeatUntil,
  }) {
    return MosqueNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      active: active ?? this.active,
      postedBy: postedBy ?? this.postedBy,
      postedByRole: postedByRole ?? this.postedByRole,
      createdAt: createdAt ?? this.createdAt,
      eventTime: eventTime ?? this.eventTime,
      expiresAt: expiresAt ?? this.expiresAt,
      hasImage: hasImage ?? this.hasImage,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      imageUpdatedAt: imageUpdatedAt ?? this.imageUpdatedAt,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      repeatTime: repeatTime ?? this.repeatTime,
      repeatUntil: repeatUntil ?? this.repeatUntil,
    );
  }

  @override
  String toString() {
    return 'MosqueNotification(id: $id, title: $title, type: ${type.displayName}, priority: ${priority.displayName}, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MosqueNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Extension for sorting notifications
extension NotificationListExtension on List<MosqueNotification> {
  /// Get only active (non-expired) notifications
  List<MosqueNotification> get activeOnly {
    return where((n) => n.shouldShow).toList();
  }

  /// Get only high priority notifications
  List<MosqueNotification> get highPriorityOnly {
    return where((n) => n.isHighPriority && n.shouldShow).toList();
  }

  /// Get notifications excluding high priority (for ticker)
  List<MosqueNotification> get excludingHighPriority {
    return where((n) => !n.isHighPriority && n.shouldShow).toList();
  }

  /// Sort by expiry date (closest first)
  List<MosqueNotification> get sortedByExpiry {
    final sorted = List<MosqueNotification>.from(this);
    sorted.sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    return sorted;
  }

  /// Sort by priority then expiry
  List<MosqueNotification> get sortedByPriorityThenExpiry {
    final sorted = List<MosqueNotification>.from(this);
    sorted.sort((a, b) {
      // First by priority (high > regular > low)
      final priorityCompare = a.priority.index.compareTo(b.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      // Then by expiry (closest first)
      return a.expiresAt.compareTo(b.expiresAt);
    });
    return sorted;
  }

  /// Sort by creation date (newest first)
  List<MosqueNotification> get sortedByNewest {
    final sorted = List<MosqueNotification>.from(this);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Group by type
  Map<NotificationType, List<MosqueNotification>> get groupedByType {
    final grouped = <NotificationType, List<MosqueNotification>>{};
    for (final notification in this) {
      grouped.putIfAbsent(notification.type, () => []).add(notification);
    }
    return grouped;
  }

  /// Get the high priority notification closest to expiry
  MosqueNotification? get priorityNotification {
    final highPriority = highPriorityOnly.sortedByExpiry;
    return highPriority.isNotEmpty ? highPriority.first : null;
  }
}
