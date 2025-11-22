// lib/models/notification_model.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class MosqueNotification {
  final String title;
  final String message;
  final bool active;
  final String postedBy;
  final DateTime timestamp;

  MosqueNotification({
    required this.title,
    required this.message,
    required this.active,
    required this.postedBy,
    required this.timestamp,
  });

  /// Create empty notification
  factory MosqueNotification.empty() {
    return MosqueNotification(
      title: '',
      message: '',
      active: false,
      postedBy: '',
      timestamp: DateTime.now(),
    );
  }

  /// Create from Firestore document
  factory MosqueNotification.fromFirestore(Map<String, dynamic> data) {
    int tsMs = 0;
    final tsRaw = data['ts'];

    if (tsRaw == null) {
      tsMs = DateTime.now().millisecondsSinceEpoch;
    } else if (tsRaw is Timestamp) {
      tsMs = (tsRaw as Timestamp).millisecondsSinceEpoch;
    } else if (tsRaw is int) {
      tsMs = tsRaw;
    } else if (tsRaw is String) {
      tsMs = int.tryParse(tsRaw) ?? DateTime.now().millisecondsSinceEpoch;
    } else {
      tsMs = DateTime.now().millisecondsSinceEpoch;
    }

    return MosqueNotification(
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      active: data['active'] == true,
      postedBy: data['postedBy']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(tsMs),
    );
  }

  /// Create from JSON (for local storage)
  factory MosqueNotification.fromJson(Map<String, dynamic> json) {
    return MosqueNotification(
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      active: json['active'] == true,
      postedBy: json['postedBy']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] ?? 0),
    );
  }

  /// Create from JSON string
  factory MosqueNotification.fromJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return MosqueNotification.fromJson(json);
    } catch (_) {
      return MosqueNotification.empty();
    }
  }

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'active': active,
      'postedBy': postedBy,
      'ts': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    return {
      'title': title,
      'message': message,
      'active': active,
      'postedBy': postedBy,
      'ts': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : timestamp.millisecondsSinceEpoch,
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

  /// Check if notification has content
  bool get hasContent => message.trim().isNotEmpty;

  /// Check if notification should be shown
  bool get shouldShow => active && hasContent;

  /// Copy with new values
  MosqueNotification copyWith({
    String? title,
    String? message,
    bool? active,
    String? postedBy,
    DateTime? timestamp,
  }) {
    return MosqueNotification(
      title: title ?? this.title,
      message: message ?? this.message,
      active: active ?? this.active,
      postedBy: postedBy ?? this.postedBy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'MosqueNotification(title: $title, active: $active, by: $postedBy, time: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MosqueNotification &&
        other.title == title &&
        other.message == message &&
        other.active == active &&
        other.postedBy == postedBy &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(title, message, active, postedBy, timestamp);
  }
}
