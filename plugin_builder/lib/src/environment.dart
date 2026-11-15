import 'dart:io';

/// Lists the files git knows under [directory], relative to it and
/// `/`-separated: the tracked ones, plus the untracked ones that `.gitignore`
/// does not ignore when [includeUntracked] is set. Null when [collectionRoot]
/// is not inside a git repository (or git is unavailable).
typedef GitFilesLookup =
    List<String>? Function(
      String collectionRoot,
      String directory, {
      required bool includeUntracked,
    });

/// Makes the file at an absolute path executable.
typedef MakeExecutable = void Function(String path);

/// The parts of the host the builder reaches outside its file system: git and
/// file modes. Files themselves go through the `ResourceProvider` of the
/// options' folders, so tests can swap in an in-memory one and these two
/// callbacks.
class BuildEnvironment {
  const BuildEnvironment({
    this.gitFiles = gitListFiles,
    this.makeExecutable = chmodExecutable,
  });

  /// An environment with no git and no file modes: everything ships, nothing
  /// is chmod-ed.
  const BuildEnvironment.inert() : gitFiles = _noGit, makeExecutable = _noChmod;

  final GitFilesLookup gitFiles;
  final MakeExecutable makeExecutable;
}

List<String>? _noGit(
  String collectionRoot,
  String directory, {
  required bool includeUntracked,
}) => null;

void _noChmod(String path) {}

/// [GitFilesLookup] backed by the `git` CLI. Asking git keeps git-ignored
/// content out of the package.
List<String>? gitListFiles(
  String collectionRoot,
  String directory, {
  required bool includeUntracked,
}) {
  var top = _git(['-C', collectionRoot, 'rev-parse', '--show-toplevel']);
  if (top == null) return null;
  var prefix = _relative(directory, top);
  if (prefix == null) return null;
  var output = _git([
    '-C',
    collectionRoot,
    'ls-files',
    '-z',
    '--full-name',
    if (includeUntracked) ...['--cached', '--others', '--exclude-standard'],
    '--',
    prefix,
  ]);
  if (output == null) return null;
  return [
    for (final path in output.split('\u0000'))
      if (path.isNotEmpty) _relative(path, prefix)!,
  ];
}

/// [MakeExecutable] using `chmod +x`; does nothing on Windows.
void chmodExecutable(String path) {
  if (!Platform.isWindows) Process.runSync('chmod', ['+x', path]);
}

String? _relative(String path, String from) {
  var p = _normalize(path);
  var f = _normalize(from);
  if (p == f) return '';
  if (!p.startsWith('$f/')) return null;
  return p.substring(f.length + 1);
}

String _normalize(String path) =>
    Uri.file(Directory(path).absolute.path).normalizePath().toFilePath();

String? _git(List<String> args) {
  var result = Process.runSync('git', args);
  if (result.exitCode != 0) return null;
  var out = (result.stdout as String).trim();
  return out.isEmpty ? null : out;
}
