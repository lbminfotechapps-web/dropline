import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dropline/features/event/data/datasources/time_slot_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final asString in [false, true]) {
    test('Parses time slot IDs and labels, string=$asString', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/get_time_slot');
            expect(options.method, 'GET');
            final data = {
              'status': true,
              'result': [
                {'fld_time_slot_id': '2', 'fld_time': '00:15'},
              ],
            };
            handler.resolve(
              Response(
                requestOptions: options,
                data: asString ? jsonEncode(data) : data,
              ),
            );
          },
        ),
      );
      final slots = await TimeSlotRemoteDataSource(dio).getTimeSlots();
      expect(slots.single.id, '2');
      expect(slots.single.time, '00:15');
    });
  }
}
