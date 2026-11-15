import 'dart:io';

import 'package:plugin_builder/plugin_builder.dart';
import 'package:test/test.dart';

import 'support/memory_workspace.dart';

/// The skill files every harness package carries for the sample collection.
List<String> _skills(String prefix) => [
  '$prefix/skills/alpha/SKILL.md',
  '$prefix/skills/alpha/notes/extra.md',
  '$prefix/skills/global-instructions/SKILL.md',
];

void main() {
  late MemoryWorkspace workspace;

  setUp(() => workspace = MemoryWorkspace());

  group('where files are written', () {
    test('each harness folder holds exactly its own client files', () {
      workspace.builder(workspace.options()).build();

      expect(
        workspace.filesUnder('/out'),
        [
          '.claude-plugin/marketplace.json'.withPrefix('claude'),
          'install.ps1'.withPrefix('claude'),
          'install.sh'.withPrefix('claude'),
          'demo/.claude-plugin/plugin.json'.withPrefix('claude'),
          'demo/agents/test-writer.md'.withPrefix('claude'),
          ..._skills('claude/demo'),
          '.agents/plugins/marketplace.json'.withPrefix('codex'),
          'install.ps1'.withPrefix('codex'),
          'install.sh'.withPrefix('codex'),
          'demo/plugin.json'.withPrefix('codex'),
          'demo/.codex/agents/test-writer.toml'.withPrefix('codex'),
          ..._skills('codex/demo'),
          'demo/plugin.json'.withPrefix('vscode'),
          'demo/com.github.copilot/agents/test-writer.agent.md'.withPrefix(
            'vscode',
          ),
          ..._skills('vscode/demo'),
          'demo/plugin.json'.withPrefix('portable-v1.0'),
          ..._skills('portable-v1.0/demo'),
        ]..sort(),
      );
    });

    test("MCP config lands in each client's own file", () {
      workspace.write(
        '/src/mcp.json',
        r'{"mcpServers": {"dart": {"command": "${CLAUDE_PLUGIN_ROOT}/run"}}}',
      );
      workspace
          .builder(workspace.options(extra: ['--mcp', '/src/mcp.json']))
          .build();

      var files = workspace.filesUnder('/out');
      expect(files, contains('claude/demo/.mcp.json'));
      expect(files, isNot(contains('claude/demo/mcp.json')));
      for (var id in ['codex', 'vscode', 'portable-v1.0']) {
        expect(files, contains('$id/demo/mcp.json'), reason: id);
        expect(files, isNot(contains('$id/demo/.mcp.json')), reason: id);
      }
      var portable =
          workspace.readJson('/out/codex/demo/mcp.json')['mcpServers'] as Map;
      expect((portable['dart'] as Map)['type'], 'stdio');
      expect((portable['dart'] as Map)['command'], './run');
      expect(workspace.readJson('/out/claude/demo/.mcp.json')['mcpServers'], {
        'dart': {'command': r'${CLAUDE_PLUGIN_ROOT}/run'},
      });
    });

    test(
      'an MCP server the portable format cannot hold fails those targets',
      () {
        workspace.write(
          '/src/mcp.json',
          '{"mcpServers": {"live": {"type": "ws", "url": "wss://x.dev"}}}',
        );

        expect(
          () => workspace
              .builder(
                workspace.options(
                  extra: ['--mcp', '/src/mcp.json', '--targets', 'codex'],
                ),
              )
              .build(),
          throwsA(
            isA<BuildException>().having(
              (e) => e.message,
              'message',
              contains('transport type "ws"'),
            ),
          ),
        );
      },
    );

    test('Claude keeps such a server as written', () {
      workspace.write(
        '/src/mcp.json',
        '{"mcpServers": {"live": {"type": "ws", "url": "wss://x.dev"}}}',
      );

      workspace
          .builder(
            workspace.options(
              extra: ['--mcp', '/src/mcp.json', '--targets', 'claude'],
            ),
          )
          .build();

      expect(workspace.readJson('/out/claude/demo/.mcp.json')['mcpServers'], {
        'live': {'type': 'ws', 'url': 'wss://x.dev'},
      });
    });

    test('writes nothing outside the output folder', () {
      var sourceBefore = workspace.filesUnder('/src');

      workspace.builder(workspace.options()).build();

      expect(workspace.filesUnder('/src'), sourceBefore);
      expect(
        workspace.filesUnder('/')
          ..removeWhere((path) => path.startsWith('out/'))
          ..removeWhere((path) => path.startsWith('src/')),
        isEmpty,
      );
    });

    test('--targets builds only the chosen harness folders', () {
      var result = workspace
          .builder(workspace.options(extra: ['--targets', 'claude']))
          .build();

      expect(result.harnesses, ['claude']);
      expect(
        workspace.filesUnder('/out').every((p) => p.startsWith('claude/')),
        isTrue,
      );
    });

    test('--out is created and the package is named after the plugin', () {
      workspace
          .builder(
            workspace.options(
              extra: ['--out', '/elsewhere/dist'],
              name: 'my-kit',
            ),
          )
          .build();

      expect(workspace.exists('/elsewhere/dist/claude/my-kit/skills'), isTrue);
      expect(workspace.exists('/out'), isFalse);
    });
  });

  group('what is written', () {
    test('manifests carry the plugin name', () {
      workspace.builder(workspace.options()).build();

      expect(
        workspace.readJson(
          '/out/claude/demo/.claude-plugin/plugin.json',
        )['name'],
        'demo',
      );
      expect(
        workspace.readJson(
          '/out/codex/.agents/plugins/marketplace.json',
        )['plugins'],
        isNotEmpty,
      );
    });

    test('skills are copied byte for byte, support files included', () {
      workspace.builder(workspace.options()).build();

      expect(
        workspace.read('/out/claude/demo/skills/alpha/SKILL.md'),
        '---\nname: alpha\n---\nBody',
      );
      expect(
        workspace.read('/out/vscode/demo/skills/alpha/notes/extra.md'),
        'support file',
      );
      expect(
        workspace.read(
          '/out/portable-v1.0/demo/skills/global-instructions/SKILL.md',
        ),
        allOf(
          startsWith('---\nname: global-instructions\n'),
          endsWith('# Global rules'),
        ),
      );
    });

    test('excluded skills never ship', () {
      workspace.builder(workspace.options()).build();

      expect(workspace.exists('/out/claude/demo/skills/private'), isFalse);
    });

    test('install scripts are marked executable (the .sh only)', () {
      workspace.builder(workspace.options()).build();

      expect(workspace.madeExecutable, [
        '/out/claude/install.sh',
        '/out/codex/install.sh',
      ]);
    });

    test('Codex installer copies the agents it wrote', () {
      workspace.builder(workspace.options()).build();

      var sh = workspace.read('/out/codex/install.sh');
      expect(sh, contains(r'$here/demo/.codex/agents/'));
      expect(
        workspace.exists('/out/codex/demo/.codex/agents/test-writer.toml'),
        isTrue,
      );
      expect(sh.indexOf('cp '), lessThan(sh.indexOf('marketplace')));
    });

    test('the result counts skills, agents and harnesses', () {
      var result = workspace.builder(workspace.options()).build();

      expect(result.skills, 2);
      expect(result.agents, 1);
      expect(result.harnesses, ['claude', 'codex', 'vscode', 'portable-v1.0']);
    });
  });

  group('file selection', () {
    /// An environment whose git lists [files] (null: not a git checkout) and
    /// records every `includeUntracked` it was asked with.
    ({BuildEnvironment environment, List<bool> asked}) fakeGit(
      List<String>? files,
    ) {
      var asked = <bool>[];
      return (
        asked: asked,
        environment: BuildEnvironment(
          gitFiles: (collectionRoot, directory, {required includeUntracked}) {
            asked.add(includeUntracked);
            return files;
          },
          makeExecutable: (_) {},
        ),
      );
    }

    List<String> shipped(BuildEnvironment environment, List<String> flags) {
      workspace
          .builder(
            workspace.options(extra: ['--targets', 'portable-v1.0', ...flags]),
            environment: environment,
          )
          .build();
      return workspace.filesUnder('/out/portable-v1.0/demo/skills');
    }

    setUp(() {
      workspace
        ..write('/src/skills/alpha/draft.md', 'untracked')
        ..write('/src/skills/beta/SKILL.md', '---\nname: beta\n---\nB');
    });

    test('by default only what git tracks ships', () {
      var git = fakeGit(['alpha/SKILL.md', 'alpha/notes/extra.md']);

      expect(shipped(git.environment, []), [
        'alpha/SKILL.md',
        'alpha/notes/extra.md',
        'global-instructions/SKILL.md',
      ]);
      expect(git.asked, [false]);
    });

    test('exclude applies to git-tracked files too', () {
      var git = fakeGit(['alpha/SKILL.md', 'private/SKILL.md']);

      expect(shipped(git.environment, []), [
        'alpha/SKILL.md',
        'global-instructions/SKILL.md',
      ]);
    });

    test('--files all ships every file on disk without asking git', () {
      var git = fakeGit(['alpha/SKILL.md']);

      expect(shipped(git.environment, ['--files', 'all']), [
        'alpha/SKILL.md',
        'alpha/draft.md',
        'alpha/notes/extra.md',
        'beta/SKILL.md',
        'global-instructions/SKILL.md',
      ]);
      expect(git.asked, isEmpty);
    });

    test('--files unignored asks git for untracked files too', () {
      var git = fakeGit(['alpha/SKILL.md', 'alpha/draft.md', 'beta/SKILL.md']);

      expect(shipped(git.environment, ['--files', 'unignored']), [
        'alpha/SKILL.md',
        'alpha/draft.md',
        'beta/SKILL.md',
        'global-instructions/SKILL.md',
      ]);
      expect(git.asked, [true]);
    });

    test('outside git the disk is used, minus exclude', () {
      var git = fakeGit(null);

      expect(shipped(git.environment, []), [
        'alpha/SKILL.md',
        'alpha/draft.md',
        'alpha/notes/extra.md',
        'beta/SKILL.md',
        'global-instructions/SKILL.md',
      ]);
    });

    test('a listed file that is gone from disk is skipped', () {
      var git = fakeGit(['alpha/SKILL.md', 'alpha/deleted.md']);

      expect(shipped(git.environment, []), [
        'alpha/SKILL.md',
        'global-instructions/SKILL.md',
      ]);
    });

    test('the lookup is asked about the skills folder', () {
      var asked = <String>[];
      var environment = BuildEnvironment(
        gitFiles: (collectionRoot, directory, {required includeUntracked}) {
          asked.add('$collectionRoot|$directory');
          return null;
        },
        makeExecutable: (_) {},
      );

      workspace.builder(workspace.options(), environment: environment).build();

      expect(asked, ['/src|/src/skills']);
    });

    test('--files picks the selection; the config key works too', () {
      FileSelection selection(List<String> args) => BuildOptions.parse(
        ['--source', '/src', '--name', 'demo', ...args],
        provider: workspace.provider,
        workingDirectory: '/',
      ).fileSelection;

      expect(selection([]), FileSelection.tracked);
      expect(selection(['--files', 'unignored']), FileSelection.unignored);
      expect(selection(['--files', 'all']), FileSelection.all);

      workspace.write(
        '/project/plugin.config.json',
        '{"name": "x", "source": "/src", "files": "unignored"}',
      );
      var config = ['--config', '/project/plugin.config.json'];
      FileSelection parse(List<String> args) => BuildOptions.parse([
        ...config,
        ...args,
      ], provider: workspace.provider).fileSelection;
      expect(parse([]), FileSelection.unignored);
      expect(parse(['--files', 'tracked']), FileSelection.tracked);
    });

    test('an unknown --files value is a usage error', () {
      expect(
        () => BuildOptions.parse([
          '--source',
          '/src',
          '--name',
          'demo',
          '--files',
          'some',
        ], provider: workspace.provider),
        throwsA(isA<BuildException>()),
      );
    });

    test('an unknown files value in the config is a usage error', () {
      workspace.write(
        '/project/plugin.config.json',
        '{"name": "x", "source": "/src", "files": "some"}',
      );

      expect(
        () => BuildOptions.parse([
          '--config',
          '/project/plugin.config.json',
        ], provider: workspace.provider),
        throwsA(
          isA<BuildException>().having(
            (e) => e.message,
            'message',
            contains('tracked, unignored, all'),
          ),
        ),
      );
    });
  });

  test('with real git the three selections differ as documented', () {
    var temp = Directory.systemTemp.createTempSync('plugin_builder_git_');
    addTearDown(() => temp.deleteSync(recursive: true));
    for (var skill in ['tracked', 'fresh', 'ignored']) {
      File('${temp.path}/repo/skills/$skill/SKILL.md')
        ..createSync(recursive: true)
        ..writeAsStringSync('---\nname: $skill\n---\nBody');
    }
    File('${temp.path}/repo/.gitignore').writeAsStringSync('skills/ignored/\n');
    for (var args in [
      ['init', '-q'],
      ['add', '.gitignore', 'skills/tracked'],
    ]) {
      var result = Process.runSync(
        'git',
        args,
        workingDirectory: '${temp.path}/repo',
      );
      expect(result.exitCode, 0, reason: '${result.stderr}');
    }

    List<String> skills(List<String> flags) {
      var out = '${temp.path}/out${flags.join().hashCode}';
      PluginBuilder(
        BuildOptions.parse([
          '--source',
          '${temp.path}/repo',
          '--name',
          'demo',
          '--out',
          out,
          '--targets',
          'portable-v1.0',
          ...flags,
        ]),
        environment: const BuildEnvironment(makeExecutable: _ignore),
      ).build();
      return [
        for (var entity in Directory(
          '$out/portable-v1.0/demo/skills',
        ).listSync())
          entity.uri.pathSegments.where((s) => s.isNotEmpty).last,
      ]..sort();
    }

    expect(skills([]), ['tracked']);
    expect(skills(['--files', 'unignored']), ['fresh', 'tracked']);
    expect(skills(['--files', 'all']), ['fresh', 'ignored', 'tracked']);
  });

  group('validation', () {
    test('a name mismatch fails before anything is written', () {
      workspace.write('/src/skills/beta/SKILL.md', '---\nname: gamma\n---\nB');

      expect(
        () => workspace.builder(workspace.options()).build(),
        throwsA(
          isA<BuildException>()
              .having((e) => e.exitCode, 'exitCode', 2)
              .having((e) => e.message, 'message', contains('"gamma" differs')),
        ),
      );
      expect(workspace.exists('/out'), isFalse);
    });

    test('a plugin name that is not kebab-case is rejected', () {
      expect(
        () => workspace.builder(workspace.options(name: 'Not Kebab')).build(),
        throwsA(isA<BuildException>()),
      );
      expect(workspace.exists('/out'), isFalse);
    });

    test('an unknown target lists the known ones and writes nothing', () {
      expect(
        () => workspace
            .builder(workspace.options(extra: ['--targets', 'cursor']))
            .build(),
        throwsA(
          isA<BuildException>().having(
            (e) => e.message,
            'message',
            allOf(contains('cursor'), contains('claude, codex, vscode')),
          ),
        ),
      );
      expect(workspace.exists('/out'), isFalse);
    });

    test('a missing skills folder is a usage error', () {
      expect(
        () => workspace
            .builder(workspace.options(extra: ['--source', '/nowhere']))
            .build(),
        throwsA(
          isA<BuildException>().having((e) => e.exitCode, 'exitCode', 64),
        ),
      );
    });
  });

  group('--clean', () {
    test('removes stale output but leaves the source alone', () {
      workspace.write('/out/stale.txt', 'old');

      workspace.builder(workspace.options(extra: ['--clean', '--yes'])).build();

      expect(workspace.exists('/out/stale.txt'), isFalse);
      expect(workspace.exists('/src/skills/alpha/SKILL.md'), isTrue);
    });

    test('asks first, and a no deletes nothing', () {
      workspace.write('/out/stale.txt', 'old');
      var asked = <String>[];

      expect(
        () => PluginBuilder(
          workspace.options(extra: ['--clean']),
          environment: workspace.environment,
          confirm: (question) {
            asked.add(question);
            return false;
          },
        ).build(),
        throwsA(isA<BuildException>()),
      );

      expect(asked.single, contains('/out'));
      expect(workspace.exists('/out/stale.txt'), isTrue);
    });

    test('a yes to the question deletes the output', () {
      workspace.write('/out/stale.txt', 'old');

      PluginBuilder(
        workspace.options(extra: ['--clean']),
        environment: workspace.environment,
        confirm: (_) => true,
      ).build();

      expect(workspace.exists('/out/stale.txt'), isFalse);
    });

    test('with nobody to ask it fails instead of deleting', () {
      workspace.write('/out/stale.txt', 'old');

      expect(
        () => workspace.builder(workspace.options(extra: ['--clean'])).build(),
        throwsA(isA<BuildException>()),
      );
      expect(workspace.exists('/out/stale.txt'), isTrue);
    });

    test('--yes skips the question', () {
      workspace.write('/out/stale.txt', 'old');

      PluginBuilder(
        workspace.options(extra: ['--clean', '--yes']),
        environment: workspace.environment,
        confirm: (_) => fail('must not ask'),
      ).build();

      expect(workspace.exists('/out/stale.txt'), isFalse);
    });

    test('refuses when out is, or contains, the source', () {
      for (var out in ['/src', '/']) {
        expect(
          () => workspace
              .builder(
                workspace.options(extra: ['--out', out, '--clean', '--yes']),
              )
              .build(),
          throwsA(isA<BuildException>()),
          reason: out,
        );
      }
      expect(workspace.exists('/src/skills/alpha/SKILL.md'), isTrue);
    });

    test('without it, existing output is kept', () {
      workspace.write('/out/stale.txt', 'old');

      workspace.builder(workspace.options()).build();

      expect(workspace.exists('/out/stale.txt'), isTrue);
    });
  });

  group('command line', () {
    BuildOptions parse(List<String> args) => BuildOptions.parse(
      args,
      provider: workspace.provider,
      workingDirectory: '/',
    );
    var required = ['--source', '/src', '--name', 'demo'];

    test('defaults apply when nothing is given', () {
      var options = parse(required);

      expect(options.out.path, '/dist');
      expect(options.version, '0.1.0');
      expect(options.category, 'Productivity');
      expect(options.marketplace, 'demo');
      expect(options.targets, isEmpty);
      expect(options.fileSelection, FileSelection.tracked);
      expect(options.clean, isFalse);
    });

    test('a repeated option keeps its last value', () {
      expect(
        parse([...required, '--version', '1', '--version', '2']).version,
        '2',
      );
    });

    test('multi options take commas and accumulate across repeats', () {
      var options = parse([
        ...required,
        '--targets',
        'claude,codex',
        '--targets',
        'vscode',
        '--exclude',
        'a',
      ]);

      expect(options.targets, ['claude', 'codex', 'vscode']);
      expect(options.exclude, ['a']);
    });

    test('flags override the config, which overrides defaults', () {
      workspace.write(
        '/project/plugin.config.json',
        '{"name": "x", "source": "/src", "version": "2.0.0", "clean": true,'
            ' "targets": ["codex"]}',
      );

      var fromConfig = parse(['--config', '/project/plugin.config.json']);
      expect(fromConfig.version, '2.0.0');
      expect(fromConfig.clean, isTrue);
      expect(fromConfig.targets, ['codex']);

      var overridden = parse([
        '--config',
        '/project/plugin.config.json',
        '--version',
        '3.0.0',
        '--targets',
        'claude',
      ]);
      expect(overridden.version, '3.0.0');
      expect(overridden.targets, ['claude']);
    });

    test('--source and --name are required', () {
      expect(
        () => parse(['--name', 'demo']),
        throwsA(
          isA<BuildException>().having(
            (e) => e.message,
            'message',
            contains('--source and --name are required'),
          ),
        ),
      );
    });

    test(
      'unknown flags, missing values and stray arguments are usage errors',
      () {
        for (var bad in [
          [...required, '--nope'],
          [...required, '--out'],
          [...required, 'stray'],
        ]) {
          expect(
            () => parse(bad),
            throwsA(
              isA<BuildException>()
                  .having((e) => e.exitCode, 'exitCode', 64)
                  .having((e) => e.message, 'message', contains('--help')),
            ),
            reason: '$bad',
          );
        }
      },
    );

    test('--list-targets is documented in the usage', () {
      var usage = buildArgParser().usage;

      expect(usage, contains('--list-targets'));
    });

    test('the generated usage documents every flag', () {
      var usage = buildArgParser().usage;

      for (var flag in [
        '--config',
        '--source',
        '--name',
        '--out',
        '--targets',
        '--exclude',
        '--files',
        '--clean',
        '--verbose',
      ]) {
        expect(usage, contains(flag));
      }
    });
  });

  group('config file', () {
    test('relative paths resolve against the config directory', () {
      workspace.write(
        '/project/plugin.config.json',
        '{"name": "from-config", "source": "../src", "out": "built",'
            ' "version": "1.2.3", "exclude": ["private"],'
            ' "targets": ["codex"]}',
      );

      var options = BuildOptions.parse(
        ['--config', '/project/plugin.config.json', '--version', '9.9.9'],
        provider: workspace.provider,
        workingDirectory: '/elsewhere',
      );

      expect(options.name, 'from-config');
      expect(options.version, '9.9.9');
      expect(options.source.path, '/src');
      expect(options.out.path, '/project/built');
      expect(options.agents.path, '/src/agents');
      expect(options.exclude, ['private']);
      expect(options.targets, ['codex']);
    });

    test('a missing config is a usage error', () {
      expect(
        () => BuildOptions.parse([
          '--config',
          '/nope.json',
        ], provider: workspace.provider),
        throwsA(isA<BuildException>()),
      );
    });
  });

  group('list of harnesses', () {
    test('has one line per built-in harness, ids aligned', () {
      var lines = describeHarnesses(builtInHarnesses).split('\n');

      expect(lines, hasLength(builtInHarnesses.length));
      for (var i = 0; i < lines.length; i++) {
        var harness = builtInHarnesses[i];
        expect(lines[i], startsWith(harness.id));
        expect(lines[i], endsWith(harness.description));
      }
      var descriptionColumns = {
        for (var i = 0; i < lines.length; i++)
          lines[i].indexOf(builtInHarnesses[i].description),
      };
      expect(descriptionColumns, hasLength(1));
    });

    test('the portable harness id carries the format version', () {
      expect(
        builtInHarnesses.map((h) => h.id),
        containsAll(['claude', 'codex', 'vscode', 'portable-v1.0']),
      );
    });

    test('every id is usable as a folder name and --targets value', () {
      for (var harness in builtInHarnesses) {
        expect(harness.id, matches(RegExp(r'^[a-z0-9]+([.-][a-z0-9]+)*$')));
        expect(harness.description, isNotEmpty);
      }
      expect(
        builtInHarnesses.map((h) => h.id).toSet(),
        hasLength(builtInHarnesses.length),
      );
    });
  });

  test('a custom harness plugs in and writes inside its own folder', () {
    var result = workspace
        .builder(
          workspace.options(extra: ['--targets', 'echo']),
          harnesses: [_EchoHarness()],
        )
        .build();

    expect(result.harnesses, ['echo']);
    expect(workspace.filesUnder('/out/echo'), [
      'demo/echo.txt',
      'demo/skills/alpha/SKILL.md',
      'demo/skills/alpha/notes/extra.md',
      'demo/skills/global-instructions/SKILL.md',
      'note.txt',
    ]);
    expect(workspace.read('/out/echo/demo/echo.txt'), 'test-writer');
  });

  test('on the real file system a build lands where the options say', () {
    var temp = Directory.systemTemp.createTempSync('plugin_builder_test_');
    addTearDown(() => temp.deleteSync(recursive: true));
    File('${temp.path}/src/skills/alpha/SKILL.md')
      ..createSync(recursive: true)
      ..writeAsStringSync('---\nname: alpha\n---\nBody');

    var options = BuildOptions.parse([
      '--source',
      '${temp.path}/src',
      '--name',
      'demo',
      '--out',
      '${temp.path}/out',
      '--targets',
      'claude',
    ]);
    PluginBuilder(options, environment: const BuildEnvironment.inert()).build();

    expect(
      File('${temp.path}/out/claude/demo/skills/alpha/SKILL.md').existsSync(),
      isTrue,
    );
    expect(File('${temp.path}/out/claude/install.sh').existsSync(), isTrue);
  });
}

/// A made-up client that writes one file in the package and one beside it.
class _EchoHarness implements Harness {
  @override
  String get id => 'echo';

  @override
  String get description => 'writes one file';

  @override
  void emit(HarnessContext context) => context
    ..writeInPackage('echo.txt', context.agents.first.name)
    ..writeInRoot('note.txt', 'beside the package');
}

extension on String {
  /// This path under the harness folder [folder].
  String withPrefix(String folder) => '$folder/$this';
}

void _ignore(String path) {}
