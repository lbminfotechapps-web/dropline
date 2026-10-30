import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dropline/features/companies/data/datasource/multiple_company_admin_datasource.dart';
import 'package:dropline/features/companies/domain/entities/multiple_company_admin_entity.dart';

void main() {
  for (final asString in [false, true]) {
    test(
      'Sends multiple people and accepts empty success result, string=$asString',
      () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.path, '/submit_multiple_company_admin_owner');
              expect(options.method, 'POST');
              final fields = Map.fromEntries((options.data as FormData).fields);
              expect(fields['login_user_id'], '1');
              expect(fields['company_id'], '');
              expect(fields['project_id'], '1');
              expect(fields['sub_company_id'], '1');
              expect(jsonDecode(fields['admin_owner_arr']!), [
                {
                  'admin_owner_name': 'Rahul Sharma',
                  'mobile_no': '9876543210',
                  'role_id': 2,
                  'task_define_arr': [
                    {'task_define_id': 1, 'flag': 1},
                    {'task_define_id': 2, 'flag': 0},
                  ],
                },
                {
                  'admin_owner_name': 'Amit Patil',
                  'mobile_no': '9876543211',
                  'role_id': 3,
                  'task_define_arr': [
                    {'task_define_id': 4, 'flag': 1},
                  ],
                },
              ]);
              final data = {
                'status': true,
                'message': 'Admin owners inserted successfully.',
                'result': [],
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
        final result = await MultipleCompanyAdminDatasource(dio).submit(
          MultipleCompanyAdminRequest(
            loginUserId: '1',
            companyId: '',
            projectId: '1',
            subCompanyId: '1',
            people: [
              CompanyAdminPerson(
                name: 'Rahul Sharma',
                mobile: '9876543210',
                roleId: '2',
                tasks: {'1': true, '2': false},
              ),
              CompanyAdminPerson(
                name: 'Amit Patil',
                mobile: '9876543211',
                roleId: '3',
                tasks: {'4': true},
              ),
            ],
          ),
        );
        expect(result.message, 'Admin owners inserted successfully.');
      },
    );
  }
  test('Rejects API failure and preserves its message', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {'status': false, 'message': 'Invalid role', 'result': []},
            ),
          );
        },
      ),
    );
    await expectLater(
      MultipleCompanyAdminDatasource(dio).submit(
        MultipleCompanyAdminRequest(
          loginUserId: '1',
          companyId: '',
          projectId: '1',
          subCompanyId: '1',
          people: [],
        ),
      ),
      throwsA(predicate((error) => error.toString().contains('Invalid role'))),
    );
  });
}
