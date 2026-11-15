import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:plugin_builder/plugin_builder.dart';

/// An in-memory file system with a small source collection at `/src`, built
/// into `/out`, plus helpers to inspect what a build wrote.
class MemoryWorkspace {
  MemoryWorkspace() {
    write('/src/skills/alpha/SKILL.md', '---\nname: alpha\n---\nBody');
    write('/src/skills/alpha/notes/extra.md', 'support file');
    write('/src/skills/private/SKILL.md', '---\nname: private\n---\nSecret');
    write(
      '/src/agents/Review/test writer.md',
      '---\nname: test writer\ndescription: d\ntools: Read\n'
          'effort: low\n---\n\nBody',
    );
    write('/src/prompts.md', '# Global rules');
  }

  final MemoryResourceProvider provider = MemoryResourceProvider();

  /// Executable files the build asked for, in order.
  final List<String> madeExecutable = [];

  /// No git (everything not excluded ships) and a recording `chmod`.
  late final BuildEnvironment environment = BuildEnvironment(
    gitFiles: (collectionRoot, directory, {required includeUntracked}) => null,
    makeExecutable: madeExecutable.add,
  );

  void write(String path, String content) => provider.newFile(path, content);

  String read(String path) => provider.getFile(path).readAsStringSync();

  Map<String, dynamic> readJson(String path) =>
      jsonDecode(read(path)) as Map<String, dynamic>;

  bool exists(String path) => provider.getResource(path).exists;

  /// Options for building `/src` into `/out`; [extra] adds or overrides flags.
  BuildOptions options({List<String> extra = const [], String name = 'demo'}) =>
      BuildOptions.parse(
        [
          '--source',
          '/src',
          '--name',
          name,
          '--out',
          '/out',
          '--prompts',
          '/src/prompts.md',
          '--exclude',
          'private',
          // A repeated option keeps its last value, so overrides go last.
          ...extra,
        ],
        provider: provider,
        workingDirectory: '/',
      );

  PluginBuilder builder(
    BuildOptions options, {
    BuildEnvironment? environment,
    List<Harness> harnesses = builtInHarnesses,
  }) => PluginBuilder(
    options,
    environment: environment ?? this.environment,
    harnesses: harnesses,
  );

  /// Every file under [folder], relative to it, `/`-separated and sorted.
  List<String> filesUnder(String folder) {
    var root = provider.getFolder(folder);
    if (!root.exists) return const [];
    var context = provider.pathContext;
    return [
      for (final file in _files(root))
        context.relative(file.path, from: root.path).replaceAll(r'\', '/'),
    ]..sort();
  }

  List<File> _files(Folder folder) => [
    for (final entity in folder.getChildren())
      if (entity is Folder) ..._files(entity) else entity as File,
  ];
}
