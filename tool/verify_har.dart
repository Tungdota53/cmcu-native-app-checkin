// Kiểm tra offline HAR cục bộ. Chỉ in số lượng, không xuất ID/điểm/nội dung HAR.
import 'dart:convert';
import 'dart:io';

import 'package:cmc_checkin/core/academic_models.dart';
import 'package:cmc_checkin/core/portal_api.dart';
import 'package:cmc_checkin/core/portal_crypto.dart';

void main(List<String> args) {
  try {
    final path = args.isEmpty ? 'iu.cmcu.edu.vn.har' : args.single;
    final root = jsonDecode(File(path).readAsStringSync());
    var checked = 0;
    for (final entry in root['log']['entries'] as List) {
      final uri = Uri.parse(entry['request']['url'] as String);
      if (uri.host != 'iu.cmcu.edu.vn') continue;
      if (uri.pathSegments.isEmpty) continue;
      final suffix = uri.pathSegments.last;
      final program = suffix == 'DSA4FSkuLyYVKC8CKTQuLyYVMygvKQkuIgPP';
      final transcript = suffix == 'CiQ1EDQgCS4iFSAxAiAPKSAv';
      if (!program && !transcript) continue;
      final form = Uri.splitQueryString(
        entry['request']['postData']['text'] as String,
      );
      final payload = jsonDecode(PortalCrypto.decrypt(form['A']!, suffix));
      final expected = [
        'action',
        'func',
        'iM',
        'strChucNang_Id',
        'strQLSV_NguoiHoc_Id',
        if (transcript) 'strDaoTao_ChuongTrinh_Id',
        'strNguoiThucHien_Id',
      ];
      if ((payload as Map).keys.join(',') != expected.join(',')) {
        throw const FormatException('Request contract changed');
      }
      final content = entry['response']['content'];
      final body = content['encoding'] == 'base64'
          ? utf8.decode(base64Decode(content['text'] as String))
          : content['text'] as String;
      final data = parseResponse(body).data;
      if (program) {
        final programs = StudyProgram.parse(data);
        stdout.writeln('Programs parsed: ${programs.length}');
      } else {
        final record = AcademicRecord.parse(data);
        if (record.summary().average4 == null ||
            record.terms.isEmpty ||
            record.summary(record.terms.first).average4 == null) {
          throw const FormatException('Summary selectors do not match');
        }
        stdout.writeln(
          'Transcript parsed: ${record.courses.length} courses, ${record.terms.length} terms; cumulative/term GPA selectors OK',
        );
      }
      checked++;
    }
    if (checked < 2) throw const FormatException('Missing academic requests');
    stdout.writeln('Offline HAR contract verification passed.');
  } catch (_) {
    stderr.writeln(
      'HAR verification failed. Check file, schema and request contract locally.',
    );
    exitCode = 1;
  }
}
