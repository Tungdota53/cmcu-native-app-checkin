// Checkout chưa có Runner.xcodeproj. Generator xuất PNG trước khi gặp project
// còn thiếu. Hoàn thiện manifest bằng helper của flutter_launcher_icons;
// CI tạo platform đầy đủ rồi chạy generator như thường.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_launcher_icons/ios.dart' as launcher;

Future<void> main() async {
  await launcher.modifyDefaultContentsFile('Icon-App', null, null);
  const directory = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  final manifest = jsonDecode(
    File('$directory/Contents.json').readAsStringSync(),
  );
  var count = 0;
  for (final entry in manifest['images'] as List) {
    final name = entry['filename'];
    if (name is! String || !File('$directory/$name').existsSync()) {
      throw StateError('Missing icon asset');
    }
    final bytes = File('$directory/$name').readAsBytesSync();
    final header = ByteData.sublistView(bytes);
    final points = double.parse((entry['size'] as String).split('x').first);
    final scale = double.parse((entry['scale'] as String).replaceAll('x', ''));
    final pixels = (points * scale).round();
    if (header.getUint32(16) != pixels || header.getUint32(20) != pixels) {
      throw StateError('Incorrect icon resolution');
    }
    count++;
  }
  stdout.writeln(
    'iOS icon catalog ready: $count entries with valid files and resolutions.',
  );
}
