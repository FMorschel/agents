import 'dart:convert';

/// A Markdown file split into its top-level `key: value` frontmatter fields
/// and the body that follows.
///
/// Only single-line scalar fields are read; indented lines (nested maps,
/// continuation lines) and empty values are skipped.
class Frontmatter {
  const Frontmatter({required this.fields, required this.body});

  /// Splits [text]. A file without a closing `---` has no frontmatter.
  factory Frontmatter.parse(String text) {
    var lines = const LineSplitter().convert(text);
    if (lines.isEmpty || lines.first.trim() != '---') {
      return Frontmatter(fields: const {}, body: lines.join('\n'));
    }
    var end = lines.indexWhere((line) => line.trim() == '---', 1);
    if (end == -1) {
      return Frontmatter(fields: const {}, body: lines.join('\n'));
    }
    var fields = <String, String>{};
    for (var line in lines.sublist(1, end)) {
      if (line.isEmpty || line.startsWith(' ') || line.startsWith('\t')) {
        continue;
      }
      var colon = line.indexOf(':');
      if (colon == -1) continue;
      var value = _unquote(line.substring(colon + 1).trim());
      if (value.isNotEmpty) fields[line.substring(0, colon).trim()] = value;
    }
    return Frontmatter(fields: fields, body: lines.sublist(end + 1).join('\n'));
  }

  final Map<String, String> fields;
  final String body;
}

String _unquote(String value) {
  if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
    return value
        .substring(1, value.length - 1)
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', r'\');
  }
  if (value.length >= 2 && value.startsWith("'") && value.endsWith("'")) {
    return value.substring(1, value.length - 1).replaceAll("''", "'");
  }
  return value;
}
