import 'dart:convert';
import 'dart:io';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args/args.dart';

import 'build_exception.dart';

/// Which files of the source's `skills/` folder ship.
enum FileSelection {
  /// Only files git tracks (the default); falls back to [all] outside git.
  tracked,

  /// Tracked files plus untracked ones that `.gitignore` does not ignore;
  /// falls back to [all] outside git.
  unignored,

  /// Every file on disk, git-ignored ones included.
  all,
}

/// Everything a build needs, from command-line flags and an optional JSON
/// config file. Flags override the file; relative paths in the file resolve
/// against the config's directory (flags and no-config runs resolve against
/// the working directory).
class BuildOptions {
  const BuildOptions({
    required this.source,
    required this.name,
    required this.out,
    required this.agents,
    required this.marketplace,
    this.version = '0.1.0',
    this.targets = const [],
    this.exclude = const [],
    this.fileSelection = FileSelection.tracked,
    this.category = 'Productivity',
    this.clean = false,
    this.yes = false,
    this.verbose = false,
    this.description,
    this.author,
    this.repository,
    this.license,
    this.mcp,
    this.prompts,
    this.displayName,
  });

  /// Reads [args]. Throws a [BuildException] for missing or unknown input.
  ///
  /// Files and folders are resolved through [provider] (the real file system
  /// by default) against [workingDirectory] (the process' by default).
  factory BuildOptions.parse(
    List<String> args, {
    ResourceProvider? provider,
    String? workingDirectory,
  }) {
    var files = provider ?? PhysicalResourceProvider.INSTANCE;
    var paths = files.pathContext;
    String resolve(String base, String path) =>
        paths.normalize(paths.join(base, path));

    ArgResults results;
    try {
      results = buildArgParser().parse(args);
    } on FormatException catch (error) {
      throw BuildException('${error.message} (see --help)');
    }
    if (results.rest.isNotEmpty) {
      throw BuildException(
        'unexpected argument "${results.rest.first}" (see --help)',
      );
    }

    var configPath = results.option('config');
    var base = workingDirectory ?? Directory.current.path;
    var config = const <String, dynamic>{};
    if (configPath != null) {
      var file = files.getFile(resolve(base, configPath));
      if (!file.exists) throw BuildException('config not found: $configPath');
      config = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      base = file.parent.path;
    }

    // A flag given on the command line wins over the config file, which wins
    // over the parser's default.
    String? text(String option, String key) => results.wasParsed(option)
        ? results.option(option)
        : config[key] as String? ?? results.option(option);
    List<String> list(String option, String key) => results.wasParsed(option)
        ? results.multiOption(option)
        : (config[key] as List?)?.cast<String>() ?? const [];
    bool toggle(String option, String key) => results.wasParsed(option)
        ? results.flag(option)
        : config[key] as bool? ?? results.flag(option);

    var name = text('name', 'name');
    var source = text('source', 'source');
    if (name == null || source == null) {
      throw const BuildException(
        '--source and --name are required (or a config providing them)',
      );
    }

    File? file(String option, String key) {
      var value = text(option, key);
      return value == null ? null : files.getFile(resolve(base, value));
    }

    var sourceDir = resolve(base, source);
    var agents = text('agents', 'agents');
    return BuildOptions(
      source: files.getFolder(sourceDir),
      agents: files.getFolder(
        agents == null
            ? paths.join(sourceDir, 'agents')
            : resolve(base, agents),
      ),
      name: name,
      out: files.getFolder(resolve(base, text('out', 'out')!)),
      version: text('version', 'version')!,
      targets: list('targets', 'targets'),
      exclude: list('exclude', 'exclude'),
      fileSelection: _selection(text('files', 'files')!),
      marketplace: text('marketplace', 'marketplace') ?? name,
      category: text('category', 'category')!,
      clean: toggle('clean', 'clean'),
      yes: toggle('yes', 'yes'),
      verbose: toggle('verbose', 'verbose'),
      description: text('description', 'description'),
      author: text('author', 'author'),
      repository: text('repository', 'repository'),
      license: text('license', 'license'),
      mcp: file('mcp', 'mcp'),
      prompts: file('prompts', 'prompts'),
      displayName: text('display-name', 'displayName'),
    );
  }

  /// Root of the source collection (holds `skills/`).
  final Folder source;

  /// Plugin id, kebab-case.
  final String name;

  /// Marketplace root; the package is written to `out/<name>`.
  final Folder out;

  /// Agent definitions; absent directories are treated as "no agents".
  final Folder agents;
  final String version;

  /// Harness ids to build; empty means every known harness.
  final List<String> targets;

  /// Skill folder names to leave out, whatever [fileSelection] is.
  final List<String> exclude;

  /// Which skill files ship (`--files`).
  final FileSelection fileSelection;

  final String marketplace;
  final String category;
  final bool clean;

  /// Skips every confirmation (`--clean` asking before it deletes `out`).
  final bool yes;
  final bool verbose;
  final String? description;
  final String? author;
  final String? repository;
  final String? license;
  final File? mcp;

  /// Global instructions to wrap as the `global-instructions` skill.
  final File? prompts;
  final String? displayName;
}

/// The command-line grammar of the builder. Also the source of `--help`.
ArgParser buildArgParser() => ArgParser(usageLineLength: 80)
  ..addOption(
    'config',
    valueHelp: 'file',
    help:
        'JSON file with the same fields as the flags (camelCase keys). '
        'Relative paths in it resolve against its directory; flags '
        'override it.',
  )
  ..addOption(
    'source',
    valueHelp: 'dir',
    help: 'Collection root (has skills/).',
  )
  ..addOption('name', valueHelp: 'id', help: 'Plugin name, kebab-case.')
  ..addOption(
    'out',
    valueHelp: 'dir',
    defaultsTo: 'dist',
    help: 'Output directory; one folder per target inside.',
  )
  ..addMultiOption(
    'targets',
    valueHelp: 'a,b',
    help: 'Harness ids to build (default: all; see --list-targets).',
  )
  ..addOption(
    'agents',
    valueHelp: 'dir',
    help: 'Agent definitions (default: <source>/agents).',
  )
  ..addOption(
    'prompts',
    valueHelp: 'file',
    help: 'Global instructions, wrapped as the global-instructions skill.',
  )
  ..addOption('mcp', valueHelp: 'file', help: 'MCP server config to bundle.')
  ..addMultiOption(
    'exclude',
    valueHelp: 'a,b',
    help: 'Skill folders to leave out, in every file-selection mode.',
  )
  ..addOption(
    'files',
    defaultsTo: FileSelection.tracked.name,
    allowed: [for (final selection in FileSelection.values) selection.name],
    allowedHelp: {
      FileSelection.tracked.name: 'files git tracks',
      FileSelection.unignored.name:
          'tracked, plus untracked files .gitignore does not ignore',
      FileSelection.all.name: 'every file on disk, ignored ones included',
    },
    help: 'Which skill files ship.',
  )
  ..addOption('version', defaultsTo: '0.1.0', help: 'Plugin version.')
  ..addOption('description', help: 'Plugin description.')
  ..addOption('author', help: 'Plugin author.')
  ..addOption('repository', help: 'Repository URL (portable manifest).')
  ..addOption('license', help: 'License id (portable manifest).')
  ..addOption(
    'marketplace',
    help: 'Marketplace name (default: the plugin name).',
  )
  ..addOption('display-name', help: 'Marketplace display name (Codex).')
  ..addOption(
    'category',
    defaultsTo: 'Productivity',
    help: 'Marketplace category (Codex).',
  )
  ..addFlag(
    'clean',
    negatable: false,
    help: 'Delete --out first (asks to confirm unless --yes).',
  )
  ..addFlag(
    'yes',
    abbr: 'y',
    negatable: false,
    help: 'Answer yes to every confirmation, e.g. for --clean.',
  )
  ..addFlag('verbose', negatable: false, help: 'Log every file written.')
  ..addFlag(
    'list-targets',
    negatable: false,
    help: 'List the supported targets and exit.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

FileSelection _selection(String value) {
  for (var selection in FileSelection.values) {
    if (selection.name == value) return selection;
  }
  throw BuildException(
    'unknown files value "$value" (expected one of '
    '${FileSelection.values.map((s) => s.name).join(', ')})',
  );
}
