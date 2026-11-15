import 'package:analyzer/file_system/file_system.dart';

import 'environment.dart';
import 'options.dart';

/// The `skills/` folder of a source collection: which files ship and how they
/// are copied.
///
/// [selection] decides which files are candidates (see [FileSelection]);
/// [exclude]d skill folders are then removed whatever the selection.
class SkillSource {
  SkillSource({
    required this.collectionRoot,
    required this.directory,
    required GitFilesLookup gitFiles,
    this.selection = FileSelection.tracked,
    this.exclude = const [],
  }) : _all = _candidates(collectionRoot, directory, gitFiles, selection);

  final Folder collectionRoot;
  final Folder directory;
  final FileSelection selection;
  final List<String> exclude;

  /// Candidate files, relative to [directory], before [exclude] applies.
  final List<String> _all;

  /// Candidates that are not excluded.
  List<String> get _shipped => [
    for (final path in _all)
      if (!exclude.contains(_skillOf(path))) path,
  ];

  /// Names of the skill folders that will ship, sorted.
  List<String> get names =>
      {for (final path in _shipped) ?_skillOf(path)}.toList()..sort();

  /// Copies the shippable files into [target], reporting each through
  /// [onCopied].
  void copyTo(Folder target, {void Function(String)? onCopied}) {
    target.create();
    for (var name in {
      for (final path in _all)
        if (_skillOf(path) case var name? when exclude.contains(name)) name,
    }) {
      onCopied?.call('skipped $name (excluded)');
    }
    for (var relative in _shipped) {
      var from = directory.getFile(relative);
      if (!from.exists) continue;
      var to = target.getFile(relative);
      to.parent.create();
      to.writeAsBytesSync(from.readAsBytesSync());
      onCopied?.call(relative);
    }
  }
}

/// The skill folder [path] belongs to, or null for a file directly in
/// `skills/`.
String? _skillOf(String path) {
  var slash = path.indexOf('/');
  return slash == -1 ? null : path.substring(0, slash);
}

List<String> _candidates(
  Folder collectionRoot,
  Folder directory,
  GitFilesLookup gitFiles,
  FileSelection selection,
) {
  if (selection != FileSelection.all) {
    var listed = gitFiles(
      collectionRoot.path,
      directory.path,
      includeUntracked: selection == FileSelection.unignored,
    );
    if (listed != null) return listed;
  }
  return _filesOnDisk(directory, '');
}

List<String> _filesOnDisk(Folder folder, String prefix) => [
  for (final entity in folder.getChildren())
    if (entity is Folder)
      ..._filesOnDisk(entity, '$prefix${entity.shortName}/')
    else
      '$prefix${entity.shortName}',
];
