class AttendanceRecord {
  final String date;
  final String siteName;
  final String inTime;
  final String outTime;
  final String note;
  final bool hasPhoto;
  final bool hasRecording;

  AttendanceRecord({
    required this.date,
    required this.siteName,
    required this.inTime,
    required this.outTime,
    required this.note,
    required this.hasPhoto,
    required this.hasRecording,
  });
}
