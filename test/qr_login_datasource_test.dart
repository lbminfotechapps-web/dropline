import 'package:dio/dio.dart';
import 'package:dropline/features/dashboard/data/datasource/qr_login_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('posts scanned token and signed-in identity as form data', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.uri.toString(), QrLoginDatasource.endpoint);
          expect(options.method, 'POST');
          expect(options.contentType, Headers.formUrlEncodedContentType);
          expect(options.data, {
            'login_id': '42',
            'mobile_no': '9999999999',
            'token': 'scanned-token',
          });
          handler.resolve(
            Response(
              requestOptions: options,
              data: '{"status":true,"message":"Approved","result":[]}',
            ),
          );
        },
      ),
    );
    expect(
      await QrLoginDatasource(dio).approve(
        loginId: '42',
        mobileNo: '9999999999',
        token: ' scanned-token ',
      ),
      'Approved',
    );
  });

  test('surfaces API rejection instead of reporting success', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {'status': false, 'message': 'QR session expired'},
            ),
          );
        },
      ),
    );
    await expectLater(
      QrLoginDatasource(
        dio,
      ).approve(loginId: '42', mobileNo: '9999999999', token: 'expired-token'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'QR session expired',
        ),
      ),
    );
  });
}
