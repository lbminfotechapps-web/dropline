import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dropline/core/api_constant/api_client.dart';

class TimeSlot {
  final String id;
  final String time;

  const TimeSlot({required this.id, required this.time});
}

class TimeSlotRemoteDataSource {
  final Dio dio;

  const TimeSlotRemoteDataSource(this.dio);

  Future<List<TimeSlot>> getTimeSlots() async {
    final response = await dio.get(ApiClient.getTimeSlot);
    final data = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    if (data is! Map ||
        ![true, 1, '1'].contains(data['status']) ||
        data['result'] is! List) {
      throw const FormatException('Unable to load time slots');
    }
    return (data['result'] as List).map((entry) {
      if (entry is! Map) {
        throw const FormatException('Invalid time slot');
      }
      final id = entry['fld_time_slot_id']?.toString().trim() ?? '';
      final time = entry['fld_time']?.toString().trim() ?? '';
      if (id.isEmpty || time.isEmpty) {
        throw const FormatException('Invalid time slot');
      }
      return TimeSlot(id: id, time: time);
    }).toList();
  }
}
