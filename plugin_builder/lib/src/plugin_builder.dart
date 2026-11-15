import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';

import 'agent.dart';
import 'build_exception.dart';
import 'environment.dart';
import 'frontmatter.dart';
import 'harness.dart';
import 'harnesses/built_in.dart';
import 'manifests.dart';
import 'options.dart';
import 'skill_source.dart';

const String _kebab = r'^[a-z0-9]+(-[a-z0-9]+)*$';
const String _promptsSkillName = 'global-instructions';
const String _promptsDescription =
    'Standing instructions for how this collection wants work done. '
    'Load when a task depends on these preferences.';

/// Asks the user [question] and returns whether they said yes.
typedef Confirm = bool Function(String question);

/// What a build produced.
class BuildResult {
  const BuildResult({
    required this.skills,
    required this.agents,
    required this.harnesses,
  });

  /// Skills in each package, including `global-instructions`.
  final int skills;
  final int agents;

  /// Ids of the harnesses built, each in its own `out/<id>/` folder.
  final List<String> harnesses;
}

/// Parses a source collection once and builds one self-contained output
/// folder per [Harness]: `out/<harness id>/<plugin name>/` (the package) with
/// that client's marketplace and install files beside it.
class PluginBuilder {
  PluginBuilder(
    this.options, {
    this.environment = const BuildEnvironment(),
    this.harnesses = builtInHarnesses,
    this.confirm,
    void Function(String)? log,
  }) : _log = log ?? ((_) {});

  final BuildOptions options;

  /// Git and file-mode access; swap it in tests.
  final BuildEnvironment environment;

  /// The harnesses `--targets` can choose from.
  final List<Harness> harnesses;

  /// Asked before anything is deleted, unless `--yes` is set. Null means
  /// nobody can be asked, so such a step fails instead of running.
  final Confirm? confirm;
  final void Function(String) _log;

  /// Validates the source and writes every selected harness. Throws a
  /// [BuildException] when the source or a target is invalid; nothing is
  /// written in that case.
  BuildResult build() {
    var skillsDir = options.source.getFolder('skills');
    if (!skillsDir.exists) {
      throw BuildException('no skills/ directory under ${options.source.path}');
    }
    var selected = _selectHarnesses();
    var skills = SkillSource(
      collectionRoot: options.source,
      directory: skillsDir,
      gitFiles: environment.gitFiles,
      selection: options.fileSelection,
      exclude: options.exclude,
    );
    var problems = _validate(skills);
    if (problems.isNotEmpty) {
      throw BuildException(
        '${problems.length} problem(s):\n'
        '${problems.map((p) => '  - $p').join('\n')}',
        exitCode: BuildException.validationExitCode,
      );
    }

    if (options.clean && options.out.exists) {
      _checkCleanIsSafe();
      _confirmClean();
      _log('Cleaning ${options.out.path}...');
      options.out.delete();
    }
    var agents = _loadAgents();
    var servers = _loadMcpServers();

    var skillCount = 0;
    for (var harness in selected) {
      var root = options.out.getFolder(harness.id);
      var context = HarnessContext(
        options: options,
        agents: agents,
        mcpServers: servers,
        root: root,
        environment: environment,
        log: _log,
        verbose: _verbose,
      );
      _log('Building ${options.name} for ${harness.id} into ${root.path}...');
      _log('Copying skills...');
      skills.copyTo(
        context.package.getFolder('skills'),
        onCopied: (path) => _verbose('  $path'),
      );
      if (options.prompts != null) _writePromptsSkill(context);
      harness.emit(context);
      skillCount = context.package
          .getFolder('skills')
          .getChildren()
          .whereType<Folder>()
          .length;
    }
    return BuildResult(
      skills: skillCount,
      agents: agents.length,
      harnesses: [for (final harness in selected) harness.id],
    );
  }

  /// Refuses to delete an `out` that is, or contains, a build input.
  void _checkCleanIsSafe() {
    var paths = options.source.provider.pathContext;
    var out = options.out.path;
    var inputs = {
      options.source.path,
      options.agents.path,
      ?options.prompts?.path,
      ?options.mcp?.path,
    };
    for (var input in inputs) {
      if (out == input || paths.isWithin(out, input)) {
        throw BuildException(
          '--clean would delete $input, which the build reads '
          '(out is $out)',
        );
      }
    }
  }

  void _confirmClean() {
    if (options.yes) return;
    var ask = confirm;
    var approved =
        ask != null &&
        ask('--clean will delete ${options.out.path} and everything in it.');
    if (!approved) {
      throw const BuildException(
        '--clean was not confirmed; nothing was deleted '
        '(pass --yes to skip the question)',
      );
    }
  }

  List<Harness> _selectHarnesses() {
    var known = {for (final harness in harnesses) harness.id: harness};
    if (options.targets.isEmpty) return harnesses;
    return [
      for (final id in options.targets)
        known[id] ??
            (throw BuildException(
              'unknown target "$id" (expected one of ${known.keys.join(', ')})',
            )),
    ];
  }

  List<String> _validate(SkillSource skills) {
    var problems = <String>[];
    if (!RegExp(_kebab).hasMatch(options.name)) {
      problems.add('plugin name "${options.name}" is not kebab-case');
    }
    var names = skills.names;
    if (names.isEmpty) {
      problems.add('no skill directories under ${skills.directory.path}');
    }
    for (var name in names) {
      var skill = skills.directory.getFolder(name).getFile('SKILL.md');
      if (!skill.exists) {
        problems.add('skill "$name" has no SKILL.md');
        continue;
      }
      if (!RegExp(_kebab).hasMatch(name)) {
        problems.add('skill "$name" is not kebab-case');
      }
      var declared = Frontmatter.parse(skill.readAsStringSync()).fields['name'];
      if (declared != null && declared != name) {
        problems.add('skill "$name": frontmatter name "$declared" differs');
      }
    }
    return problems;
  }

  void _writePromptsSkill(HarnessContext context) {
    context.writeInPackage(
      'skills/$_promptsSkillName/SKILL.md',
      '---\n'
          'name: $_promptsSkillName\n'
          'description: $_promptsDescription\n'
          '---\n\n'
          '${options.prompts!.readAsStringSync()}',
    );
  }

  /// Every `.md` under the agents directory, parsed once for all harnesses.
  List<Agent> _loadAgents() {
    if (!options.agents.exists) return const [];
    var files = _markdownFiles(options.agents)
      ..sort((a, b) => a.path.compareTo(b.path));
    _log('Parsing ${files.length} agent(s)...');
    return [
      for (final file in files)
        Agent.parse(
          file.readAsStringSync(),
          fallbackName: file.shortName.replaceAll(RegExp(r'\.md$'), ''),
        ),
    ];
  }

  List<File> _markdownFiles(Folder folder) => [
    for (final entity in folder.getChildren())
      if (entity is Folder)
        ..._markdownFiles(entity)
      else if (entity is File && entity.path.toLowerCase().endsWith('.md'))
        entity,
  ];

  Map<String, dynamic>? _loadMcpServers() {
    var file = options.mcp;
    if (file == null) return null;
    var raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return mcpServers(raw);
  }

  void _verbose(String message) {
    if (options.verbose) _log(message);
  }
}
