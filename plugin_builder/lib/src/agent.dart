import 'frontmatter.dart';

/// A client-neutral agent definition: Markdown with `name`, `description`,
/// `tools`, `model` and `effort` frontmatter, whose body is the system prompt.
///
/// Fields the clients have no equivalent for (opencode's `mode` and
/// `permission`) are not read.
class Agent {
  const Agent({
    required this.name,
    required this.description,
    required this.tools,
    required this.body,
    this.model,
    this.effort,
  });

  /// Parses [text]; [fallbackName] (usually the file's base name) is used when
  /// the frontmatter has no `name`. Names are slugified (`test writer` becomes
  /// `test-writer`).
  factory Agent.parse(String text, {required String fallbackName}) {
    var parsed = Frontmatter.parse(text);
    var fields = parsed.fields;
    return Agent(
      name: slugify(fields['name'] ?? fallbackName),
      description: fields['description'] ?? '',
      tools: [
        for (final token in (fields['tools'] ?? '').split(','))
          if (token.trim().isNotEmpty) token.trim(),
      ],
      model: fields['model'],
      effort: fields['effort'],
      body: parsed.body.trim(),
    );
  }

  final String name;
  final String description;
  final List<String> tools;
  final String body;
  final String? model;
  final String? effort;
}

/// Lowercases [value] and joins its words with hyphens.
String slugify(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
