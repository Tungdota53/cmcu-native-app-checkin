import 'dart:convert';

import 'package:cmc_checkin/core/portal_api.dart';
import 'package:cmc_checkin/core/portal_crypto.dart';
import 'package:cmc_checkin/core/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'academic_fixture.dart';

void main() {
  test(
    'Uses observed endpoints, encrypted form, dedicated permission and selected program',
    () async {
      final requests = <http.Request>[];
      final api = PortalApi(
        session: testSession,
        userAgent: 'test-agent',
        cookieHeader: (_) async => 'session=synthetic',
        client: MockClient((r) async {
          requests.add(r);
          final isProgram = r.url.path.endsWith(
            'DSA4FSkuLyYVKC8CKTQuLyYVMygvKQkuIgPP',
          );
          final data = isProgram
              ? [
                  {
                    'DAOTAO_TOCHUCCHUONGTRINH_ID': 'program-1',
                    'DAOTAO_CHUONGTRINH_TEN': 'Công nghệ thông tin',
                  },
                ]
              : academicFixture();
          return http.Response(
            jsonEncode({
              'Success': true,
              'Data': {
                'B': PortalCrypto.encrypt(jsonEncode(data), PortalCrypto.im),
              },
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      expect((await api.studyPrograms()).single.id, 'program-1');
      expect((await api.academicRecord('program-1')).courses, hasLength(3));
      for (final r in requests) {
        expect(r.method, 'POST');
        expect(r.url.host, 'iu.cmcu.edu.vn');
        expect(r.url.path, startsWith('/sinhvienapi/api/'));
        expect(r.bodyFields.keys, ['A']);
        expect(r.headers['Authorization'], 'Bearer test-token');
        expect(r.headers['Cookie'], 'session=synthetic');
        final payload = jsonDecode(
          PortalCrypto.decrypt(r.bodyFields['A']!, r.url.pathSegments.last),
        );
        expect(payload['strChucNang_Id'], 'grades-menu');
        expect(payload['strQLSV_NguoiHoc_Id'], 'student-synthetic');
        expect(payload['strNguoiThucHien_Id'], 'student-synthetic');
        expect(payload['iM'], 'AzzSystem');
      }
      final payload = jsonDecode(
        PortalCrypto.decrypt(
          requests.last.bodyFields['A']!,
          requests.last.url.pathSegments.last,
        ),
      );
      expect(payload.keys, [
        'action',
        'func',
        'iM',
        'strChucNang_Id',
        'strQLSV_NguoiHoc_Id',
        'strDaoTao_ChuongTrinh_Id',
        'strNguoiThucHien_Id',
      ]);
      expect(
        payload['func'],
        'pkg_congthongtin_hssv_thongtin.KetQuaHocTapCaNhan',
      );
      expect(payload['strDaoTao_ChuongTrinh_Id'], 'program-1');
    },
  );
  test(
    'Fetches components by result ID rather than joining different attempts',
    () async {
      final api = PortalApi(
        session: testSession,
        userAgent: 'test',
        cookieHeader: (_) async => null,
        client: MockClient((r) async {
          expect(
            r.url.pathSegments.last,
            'DSA4BRIFKCQsFSkgLykRKSAvFSkkLhUKCREP',
          );
          final payload = jsonDecode(
            PortalCrypto.decrypt(r.bodyFields['A']!, r.url.pathSegments.last),
          );
          expect(payload['strDiem_NguoiHoc_TongKet_Id'], 'result-1');
          return http.Response(
            jsonEncode({
              'Success': true,
              'Data': [
                {
                  'DIEM_THANHPHANDIEM_TEN': 'Chuyên cần',
                  'DIEM': 0,
                  'LANHOC': 1,
                  'LANTHI': 2,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(api.close);
      expect((await api.gradeComponents('result-1')).single.score, 0);
    },
  );
  test('Does not send requests with missing grades permission', () async {
    final api = PortalApi(
      session: const Session(
        token: 't',
        userId: 'u',
        chucNangId: 'schedule',
        portalIp: '',
      ),
      userAgent: 'test',
      cookieHeader: (_) async => null,
      client: MockClient((_) async => throw StateError('Must not send')),
    );
    addTearDown(api.close);
    await expectLater(api.studyPrograms(), throwsA(isA<PortalException>()));
  });
  test(
    'Distinguishes business failure, expired session and schema errors',
    () async {
      for (final status in [200, 401, 503]) {
        final api = PortalApi(
          session: testSession,
          userAgent: 'test',
          cookieHeader: (_) async => null,
          client: MockClient(
            (_) async => http.Response(
              '{"Success":false,"Message":"Bị từ chối"}',
              status,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          ),
        );
        await expectLater(
          api.academicRecord('p'),
          throwsA(
            status == 401
                ? isA<SessionExpiredException>()
                : isA<PortalException>(),
          ),
        );
        api.close();
      }
      expect(
        () => parseResponse('{"Success":true,"Data":{"B":"invalid"}}'),
        throwsA(isA<PortalException>()),
      );
    },
  );
}
