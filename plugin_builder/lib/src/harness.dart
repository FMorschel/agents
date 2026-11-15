import 'dart:convert';
import 'package:analyzer/file_system/file_system.dart';

import 'agent.dart';
import 'environment.dart';
import 'options.dart';

/// One output option of the builder: everything specific to a single client
/// (Claude Code, Codex, ...).
///
/// The core builder parses the source collection once, then for each selected
/// harness creates `out/<id>/<plugin name>/`, copies the skills (and the
/// `global-instructions` skill) into it and calls [emit]. A harness adds only
/// what its client needs: manifests, agent files, MCP config, marketplace
/// files, install scripts.
///
/// To support a new client, implement this interface and add the class to
/// `builtInHarnesses`.
abstract interface class Harness {
  /// Folder name under the output directory and the value `--targets` takes:
  /// lowercase letters, digits, hyphens and dots. Put a format version in it
  /// when the client's format is versioned (`portable-v1.0`).
  String get id;

  /// One line saying what this harness writes, shown by `--list-targets`.
  String get description;

  /// Writes this client's files through [context]. Skills are already in
  /// place.
  void emit(HarnessContext context);
}

/// What a [Harness] sees while emitting: the parsed collection and helpers
/// that write inside its own output folder.
class HarnessContext {
  HarnessContext({
    required this.options,
    required this.agents,
    required this.mcpServers,
    required this.root,
    required this.environment,
    required void Function(String) log,
    required void Function(String) verbose,
  }) : _log = log,
       _verbose = verbose;

  final BuildOptions options;

  /// Every agent of the collection, already parsed.
  final List<Agent> agents;

  /// The collection's MCP servers, or null when none is configured.
  final Map<String, dynamic>? mcpServers;

  /// This harness' marketplace root (`out/<id>`).
  final Folder root;

  final BuildEnvironment environment;

  final void Function(String) _log;
  final void Function(String) _verbose;

  /// The plugin package (`root/<plugin name>`).
  Folder get package => root.getFolder(options.name);

  /// Writes [content] to [path] inside the package.
  void writeInPackage(String path, String content) =>
      _write(package, path, content);

  /// Writes [content] to [path] inside the marketplace root, next to the
  /// package.
  void writeInRoot(String path, String content) => _write(root, path, content);

  /// Writes [data] as indented JSON to [path] inside the package.
  void writeJsonInPackage(String path, Map<String, dynamic> data) =>
      writeInPackage(path, _json(data));

  /// Writes [data] as indented JSON to [path] inside the marketplace root.
  void writeJsonInRoot(String path, Map<String, dynamic> data) =>
      writeInRoot(path, _json(data));

  /// Reports one step of a harness; shown only with `--verbose`.
  void detail(String message) => _verbose(message);

  /// Marks the file at [path] inside the marketplace root executable.
  void markExecutableInRoot(String path) =>
      environment.makeExecutable(root.getFile(path).path);

  void _write(Folder base, String path, String content) {
    base.getFile(path)
      ..parent.create()
      ..writeAsStringSync(content);
    _log('Wrote $path');
  }

  String _json(Map<String, dynamic> data) =>
      '${const JsonEncoder.withIndent('  ').convert(data)}\n';
}

/// The `--list-targets` text: one line per harness, `id  description`, with
/// the descriptions aligned.
String describeHarnesses(List<Harness> harnesses) {
  var width = harnesses.fold<int>(
    0,
    (longest, harness) =>
        harness.id.length > longest ? harness.id.length : longest,
  );
  return [
    for (final harness in harnesses)
      '${harness.id.padRight(width)}  ${harness.description}',
  ].join('\n');
}
