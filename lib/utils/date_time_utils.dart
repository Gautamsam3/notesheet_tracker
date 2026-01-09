// lib/utils/date_time_utils.dart
import 'package:intl/intl.dart';
import '../utils/enums.dart';

class DateTimeUtils {
  /// Formats a DateTime object into a human-readable date string (e.g., "Jul 19, 2025").
  static String formatDate(DateTime dateTime) {
    return DateFormat.yMMMd().format(dateTime); // e.g., "Jul 19, 2025"
  }

  /// Formats a DateTime object into a short time string (e.g., "10:17 PM").
  static String formatTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime); // e.g., "10:17 PM"
  }

  /// Formats a DateTime object into a full date and time string (e.g., "Jul 19, 2025 10:17 PM").
  static String formatDateTime(DateTime dateTime) {
    return DateFormat.yMMMd().add_jm().format(
      dateTime,
    ); // e.g., "Jul 19, 2025 10:17 PM"
  }

  /// Formats a DateTime object into a full date and time string including seconds (e.g., "Jul 19, 2025 10:17:46 PM").
  static String formatFullDateTime(DateTime dateTime) {
    return DateFormat.yMMMd().add_jms().format(
      dateTime,
    ); // e.g., "Jul 19, 2025 10:17:46 PM"
  }

  /// Determines if an event is upcoming, ongoing, or occurred based on current time.
  /// (This logic is also partly in EventService, but can be useful client-side for dynamic UI).
  /// Note: This utility does not consider the 'cancelled' status, as it's time-agnostic.
  static EventStatus getEventLiveStatus(DateTime startTime, DateTime endTime) {
    final now = DateTime.now();

    // Check if the event is already over (occurred)
    if (now.isAfter(endTime)) {
      return EventStatus.occurred;
    }
    // Check if the event is currently happening (ongoing)
    else if (now.isAfter(startTime) && now.isBefore(endTime)) {
      return EventStatus.ongoing;
    }
    // Otherwise, the event is upcoming
    else {
      return EventStatus.upcoming;
    }
  }
}
