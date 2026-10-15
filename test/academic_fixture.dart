import 'package:cmc_checkin/core/models.dart';

const testSession = Session(
  token: 'test-token',
  userId: 'student-synthetic',
  chucNangId: 'schedule-menu',
  gradesChucNangId: 'grades-menu',
  portalIp: '',
);

Map<String, dynamic> academicFixture({String name = 'Lập trình di động'}) => {
  'rsDiemKetThucHocPhan': [
    {
      'ID': 'result-1',
      'DAOTAO_HOCPHAN_MA': 'MOB101',
      'DAOTAO_HOCPHAN_TEN': name,
      'DAOTAO_HOCPHAN_HOCTRINH': 3.0,
      'NAMHOC': '2025-2026',
      'HOCKY': 2.0,
      'DIEM': 8.5,
      'DIEMQUYDOI': 3.5,
      'DIEMQUYDOI_TEN': 'B+',
      'DANHGIA_TEN': 'Đạt',
      'LANHOC': 1.0,
      'LANTHI': 1.0,
    },
    {
      'ID': 'result-2',
      'DAOTAO_HOCPHAN_MA': 'NET101',
      'DAOTAO_HOCPHAN_TEN': 'Mạng máy tính',
      'DAOTAO_HOCPHAN_HOCTRINH': '3',
      'NAMHOC': '2025-2026',
      'HOCKY': '1',
      'DIEM': null,
    },
    {
      'ID': 'result-3',
      'DAOTAO_HOCPHAN_MA': 'MOB101',
      'DAOTAO_HOCPHAN_TEN': name,
      'NAMHOC': '2024-2025',
      'HOCKY': 2,
      'DIEM': 0,
      'LANHOC': 1,
      'LANTHI': 1,
    },
  ],
  'rsDiemTrungBinhChung': [
    average('TRUNGBINHTICHLUY', '4', 3.2),
    average('TRUNGBINHTICHLUY', '10', 8, credits: 48),
    average('TRUNGBINHCHUNG', '10', 7.9, curriculum: 130),
    average('TRUNGBINHCHUNG', '4', 3.9, term: true),
    average('TRUNGBINHTICHLUY', '4', 3.1, term: true),
    average('TRUNGBINHCHUNG', '10', 9.1, term: true),
    average('TRUNGBINHTICHLUY', '10', 8.1, term: true, credits: 30),
  ],
  'rsHocPhanChuaHoanThanh': [],
};

Map<String, dynamic> average(
  String type,
  String scale,
  double score, {
  bool term = false,
  double? credits,
  double? curriculum,
}) => {
  'LOAIDIEMTRUNGBINH_MA': type,
  'THANGDIEM_MA': scale,
  'DIEMTRUNGBINH': score,
  'THUOCTINHLANTINH': 0.0,
  'DAOTAO_THOIGIANDAOTAO_ID': term ? 'term-2' : null,
  'NAMHOC': term ? '2025-2026' : null,
  'DAOTAO_THOIGIANDAOTAO_KY': term ? 2.0 : null,
  'DOTHOC': null,
  'PHAMVITONGHOPDIEM_TEN': term ? 'HOCKY' : null,
  'TONGSOTINCHI': credits,
  'TONGSOTINCHICTDT': curriculum,
};
