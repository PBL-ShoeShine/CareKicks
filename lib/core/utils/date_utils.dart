class DateTimeUtils {
  /// Parses a date string, automatically assuming UTC if there is no timezone suffix,
  /// and converts/adds the +7 hours offset to return the DateTime in WIB.
  static DateTime parseToWib(String dateStr) {
    String parseStr = dateStr;
    bool hasTimezone = false;
    if (dateStr.length > 10) {
      final timePart = dateStr.substring(10);
      if (timePart.contains('Z') || timePart.contains('+') || timePart.contains('-')) {
        hasTimezone = true;
      }
    }
    if (!hasTimezone) {
      parseStr = '${dateStr}Z';
    }
    return DateTime.parse(parseStr).toUtc().add(const Duration(hours: 7));
  }
}
