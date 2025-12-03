// lib/models/hijri_date.dart

/// Model representing a Hijri (Islamic) calendar date
/// Supports conversion from Gregorian dates via Aladhan API
class HijriDate {
  final int day;
  final int month;
  final int year;
  final String monthName; // Arabic month name
  final String monthNameEnglish; // English transliteration
  final String weekdayName; // Arabic weekday name
  final String weekdayNameEnglish; // English weekday name
  final DateTime gregorianDate; // Corresponding Gregorian date
  final DateTime cachedAt; // When this data was cached

  HijriDate({
    required this.day,
    required this.month,
    required this.year,
    required this.monthName,
    required this.monthNameEnglish,
    required this.weekdayName,
    required this.weekdayNameEnglish,
    required this.gregorianDate,
    required this.cachedAt,
  });

  /// Short formatted date: "24 Muharram 1446 AH"
  String get formattedShort => '$day $monthNameEnglish $year AH';

  /// Long formatted date: "Thursday, 24 Muharram 1446 AH"
  String get formattedLong =>
      '$weekdayNameEnglish, $day $monthNameEnglish $year AH';

  /// Check if cached date is still valid
  /// Valid if: within 24 hours AND Gregorian date matches current date
  bool get isCacheValid {
    final now = DateTime.now();

    // Check time window (24 hours)
    final age = now.difference(cachedAt);
    if (age > const Duration(hours: 24)) return false;

    // Check date match (ignore time component)
    final nowDate = DateTime(now.year, now.month, now.day);
    final cachedDate = DateTime(
      gregorianDate.year,
      gregorianDate.month,
      gregorianDate.day,
    );

    return nowDate == cachedDate;
  }

  /// Create from Aladhan API response
  /// API response format: {hijri: {...}, gregorian: {...}}
  factory HijriDate.fromApiResponse(Map<String, dynamic> data) {
    final hijri = data['hijri'] as Map<String, dynamic>;
    final gregorian = data['gregorian'] as Map<String, dynamic>;

    // Parse Hijri date
    final day = int.parse(hijri['day'] as String);
    final month = hijri['month'] as Map<String, dynamic>;
    final monthNumber = month['number'] as int;
    final monthNameEn = month['en'] as String;
    final monthNameAr = month['ar'] as String;
    final year = int.parse(hijri['year'] as String);

    // Parse weekday
    final weekday = hijri['weekday'] as Map<String, dynamic>;
    final weekdayEn = weekday['en'] as String;
    final weekdayAr = weekday['ar'] as String;

    // Parse corresponding Gregorian date
    final gregDateStr = gregorian['date'] as String; // Format: "DD-MM-YYYY"
    final gregParts = gregDateStr.split('-');
    final gregDate = DateTime(
      int.parse(gregParts[2]), // year
      int.parse(gregParts[1]), // month
      int.parse(gregParts[0]), // day
    );

    return HijriDate(
      day: day,
      month: monthNumber,
      year: year,
      monthName: monthNameAr,
      monthNameEnglish: monthNameEn,
      weekdayName: weekdayAr,
      weekdayNameEnglish: weekdayEn,
      gregorianDate: gregDate,
      cachedAt: DateTime.now(),
    );
  }

  /// Create from cached JSON
  factory HijriDate.fromCache(Map<String, dynamic> json) {
    return HijriDate(
      day: json['day'] as int,
      month: json['month'] as int,
      year: json['year'] as int,
      monthName: json['monthName'] as String,
      monthNameEnglish: json['monthNameEnglish'] as String,
      weekdayName: json['weekdayName'] as String,
      weekdayNameEnglish: json['weekdayNameEnglish'] as String,
      gregorianDate: DateTime.parse(json['gregorianDate'] as String),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'month': month,
      'year': year,
      'monthName': monthName,
      'monthNameEnglish': monthNameEnglish,
      'weekdayName': weekdayName,
      'weekdayNameEnglish': weekdayNameEnglish,
      'gregorianDate': gregorianDate.toIso8601String(),
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  HijriDate copyWith({
    int? day,
    int? month,
    int? year,
    String? monthName,
    String? monthNameEnglish,
    String? weekdayName,
    String? weekdayNameEnglish,
    DateTime? gregorianDate,
    DateTime? cachedAt,
  }) {
    return HijriDate(
      day: day ?? this.day,
      month: month ?? this.month,
      year: year ?? this.year,
      monthName: monthName ?? this.monthName,
      monthNameEnglish: monthNameEnglish ?? this.monthNameEnglish,
      weekdayName: weekdayName ?? this.weekdayName,
      weekdayNameEnglish: weekdayNameEnglish ?? this.weekdayNameEnglish,
      gregorianDate: gregorianDate ?? this.gregorianDate,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  String toString() => formattedShort;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HijriDate &&
        other.day == day &&
        other.month == month &&
        other.year == year &&
        other.gregorianDate == gregorianDate;
  }

  @override
  int get hashCode {
    return day.hashCode ^
        month.hashCode ^
        year.hashCode ^
        gregorianDate.hashCode;
  }
}
