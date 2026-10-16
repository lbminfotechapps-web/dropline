
import 'dart:convert';

class EventDraftScope {
  final String userId;
  final String projectId;
  final DateTime date;
  final String timeSlotId;

  const EventDraftScope({
    required this.userId,
    required this.projectId,
    required this.date,
    required this.timeSlotId,
  });

  String get sessionKey => jsonEncode([
        userId,
        projectId,
        date.year,
        date.month,
        date.day,
      ]);

  String get storageKey => jsonEncode([
        userId,
        projectId,
        date.year,
        date.month,
        date.day,
        timeSlotId,
      ]);

  String get folderKey => base64Url
      .encode(utf8.encode(storageKey))
      .replaceAll('=', '');

  bool belongsToSameSession(EventDraftScope other) {
    return sessionKey == other.sessionKey;
  }
}
