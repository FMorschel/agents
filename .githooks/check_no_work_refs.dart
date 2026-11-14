import 'dart:io';

/// Fails if any work identifier appears in the git index — i.e. in what a
/// commit would contain — so those terms never reach origin.
///
/// The term list lives in a git-ignored config file (default:
/// `.work-identifiers`), so the list itself is never committed. `.gitignore` is
/// always excluded from the scan: ignore patterns are the one place work
/// references are allowed.
///
/// Usage:
/// ```sh
/// dart run .githooks/check_no_work_refs.dart \
///   [--config <file>] [--working-tree] [<path>...]
/// ```
///
/// Scans the index by default. Pass `--working-tree` to scan the working tree
/// of tracked files instead. Positional paths narrow the scan to those
/// pathspecs.
///
/// Exit codes: 0 clean (or nothing to check), 1 a term was found, 2 error.
///
/// See `specs/cross-platform-plugin-packaging.md`.
Future<void> main(List<String> args) async {
  var configFlag = _valueAfter(args, '--config');
  var workingTree = args.contains('--working-tree');
  var paths = args.where((a) => !a.startsWith('--')).toList();
  if (configFlag == null && args.contains('--config')) {
    stderr.writeln('check_no_work_refs: --config needs a file path.');
    exit(2);
  }

  var root = await _gitRoot();
  if (root == null) {
    stderr.writeln('check_no_work_refs: not inside a git repository.');
    exit(2);
  }

  var config = _resolveConfig(configFlag, root);
  if (config == null) {
    stdout.writeln(
      'check_no_work_refs: no term list found '
      '(${configFlag ?? '.work-identifiers'}); nothing to check.',
    );
    exit(0);
  }

  var terms = _readTerms(config);
  if (terms.isEmpty) {
    stdout.writeln(
      'check_no_work_refs: ${config.path} lists no terms; nothing to check.',
    );
    exit(0);
  }

  stdout.writeln(
    'check_no_work_refs: scanning the '
    '${workingTree ? 'working tree' : 'index'} for '
    '${terms.length} term(s) from ${config.path}...',
  );

  var result = await Process.run('git', [
    'grep',
    '-n',
    '-I',
    '-i',
    if (!workingTree) '--cached',
    for (final term in terms) ...['-e', term],
    '--',
    if (paths.isEmpty) ...['.', ':(exclude).gitignore'] else ...paths,
  ], workingDirectory: root);

  switch (result.exitCode) {
    case 0:
      stderr
        ..writeln(
          'check_no_work_refs: work identifier(s) found in '
          '${workingTree ? 'tracked files' : 'staged content'}:',
        )
        ..writeln(result.stdout);
      exit(1);
    case 1:
      stdout.writeln('check_no_work_refs: clean.');
      exit(0);
    default:
      stderr
        ..writeln(
          'check_no_work_refs: git grep failed '
          '(exit ${result.exitCode}).',
        )
        ..writeln(result.stderr);
      exit(2);
  }
}

String? _valueAfter(List<String> args, String flag) {
  var i = args.indexOf(flag);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}

Future<String?> _gitRoot() async {
  var result = await Process.run('git', ['rev-parse', '--show-toplevel']);
  if (result.exitCode != 0) return null;
  var path = (result.stdout as String).trim();
  return path.isEmpty ? null : path;
}

File? _resolveConfig(String? explicit, String root) {
  var candidates = [
    if (explicit != null) File(explicit),
    File('.work-identifiers'),
    File('$root/.work-identifiers'),
  ];
  for (var file in candidates) {
    if (file.existsSync()) return file;
  }
  return null;
}

List<String> _readTerms(File config) {
  var terms = <String>[];
  for (var raw in config.readAsLinesSync()) {
    var line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    terms.add(line);
  }
  return terms;
}
