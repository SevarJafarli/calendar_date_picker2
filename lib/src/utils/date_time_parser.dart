extension DateTimeParser on DateTime {
  Map<String, dynamic> toJson() {
    return {
      "year": year,
      "month": month,
      "day": day,
      "hour": hour,
      "minute": minute,
      "second": second 
    };
  }

  static DateTime fromJson(Map<String, dynamic> json) {
    return DateTime(
      json["year"] as int? ?? 0,
      json["month"] as int? ?? 0,
      json["day"] as int? ?? 0,
      json["hour"] as int? ?? 0,
      json["minute"] as int? ?? 0,
      json["second"] as int? ?? 0 
    );
  }
} 