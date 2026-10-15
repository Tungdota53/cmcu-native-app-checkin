import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

/// Chỉ dành cho văn bản hiển thị; không dùng để sửa ID, từ khóa hoặc payload.
/// Portal có thể trả thẻ HTML hoặc HTML đã escape trong các nhãn.
String portalPlainText(String? source) {
  if (source == null || source.isEmpty) return '';
  var text = source;
  for (var pass = 0; pass < 3; pass++) {
    final fragment = html.parseFragment(text);
    final buffer = StringBuffer();
    void read(Node node) {
      if (node is Text) {
        buffer.write(node.data);
        return;
      }
      if (node is Element) {
        if (const {'script', 'style', 'iframe'}.contains(node.localName))
          return;
        if (node.localName == 'br') {
          buffer.writeln();
          return;
        }
        final block = const {'div', 'p', 'li', 'tr'}.contains(node.localName);
        if (block) buffer.writeln();
        for (final child in node.nodes) {
          read(child);
        }
        if (block) buffer.writeln();
      } else {
        for (final child in node.nodes) {
          read(child);
        }
      }
    }

    read(fragment);
    final decoded = buffer.toString();
    if (decoded == text) break;
    text = decoded;
  }
  return text
      .replaceAll('\u00a0', ' ')
      .split(RegExp(r'[\r\n]+'))
      .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .join('\n');
}

/// Tìm tiếng Việt có/không dấu, đồng thời bỏ markup của portal khỏi nhãn tìm kiếm.
String searchKey(String source) {
  var result = portalPlainText(source).toLowerCase();
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final group in groups.entries) {
    result = result.replaceAll(RegExp('[${group.value}]'), group.key);
  }
  return result
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
