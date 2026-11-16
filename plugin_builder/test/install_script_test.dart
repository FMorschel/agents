import 'package:plugin_builder/plugin_builder.dart';
import 'package:test/test.dart';

const List<InstallStep> _steps = [
  CopyFiles(
    'Copy agents',
    from: 'demo/.codex/agents',
    pattern: '*.toml',
    destination: HomeDirectory(
      envVar: 'CODEX_HOME',
      homeFallback: '.codex',
      subdirectory: 'agents',
    ),
  ),
  RunCommand("Add the it's marketplace", 'codex', [
    'plugin',
    'marketplace',
    'add',
    installRoot,
  ]),
];

void main() {
  test('shell installer numbers steps, checks the tool and quotes args', () {
    var sh = renderShellInstaller(_steps, title: 'demo');

    expect(sh, startsWith('#!/bin/sh\n'));
    expect(sh, contains('set -eu'));
    expect(sh, contains("echo '[1/2] Copy agents'"));
    expect(sh, contains(r'dest="${CODEX_HOME:-$HOME/.codex}/agents"'));
    expect(sh, contains(r'for file in "$here/demo/.codex/agents/"*.toml; do'));
    expect(sh, contains(r'cp "$file" "$target"'));
    expect(sh, contains(r"echo '[2/2] Add the it'\''s marketplace'"));
    expect(sh, contains('command -v '));
    expect(sh, contains(r'codex plugin marketplace add "$here"'));
  });

  test('shell installer asks before overwriting unless --yes is passed', () {
    var sh = renderShellInstaller(_steps, title: 'demo');

    expect(sh, contains('--yes|-y) assume_yes=1'));
    expect(sh, contains(r'if [ -e "$target" ] && [ "$assume_yes" -ne 1 ]'));
    expect(sh, contains('Overwrite? [y/N]'));
    expect(sh, contains('skipped'));
  });

  test('PowerShell installer asks before overwriting unless -Yes is set', () {
    var ps = renderPowerShellInstaller(_steps, title: 'demo');

    expect(ps, contains(r'param([switch]$Yes)'));
    expect(ps, contains(r'(Test-Path $Target) -and -not $Yes'));
    expect(ps, contains('Overwrite? [y/N]'));
  });

  group('PromptEnvVar', () {
    var steps = [PromptEnvVar('EXAMPLE_TOKEN')];

    test('shell installer reads silently and keeps what already exists', () {
      var sh = renderShellInstaller(steps, title: 'demo');

      expect(sh, contains("echo '[1/1] Set the EXAMPLE_TOKEN environment"));
      expect(sh, contains(r'if [ -n "${EXAMPLE_TOKEN:-}" ]; then'));
      expect(sh, contains("grep -qs '^export EXAMPLE_TOKEN='"));
      expect(sh, contains('elif [ ! -t 0 ]; then'));
      expect(sh, contains('stty -echo'));
      expect(sh, contains(r'>> "$profile"'));
      expect(sh, isNot(contains('@NAME@')));
    });

    test(
      'PowerShell installer reads a secure string and keeps what exists',
      () {
        var ps = renderPowerShellInstaller(steps, title: 'demo');

        expect(ps, contains("GetEnvironmentVariable('EXAMPLE_TOKEN')"));
        expect(ps, contains('[Console]::IsInputRedirected'));
        expect(ps, contains('-AsSecureString'));
        expect(ps, contains(r"SetEnvironmentVariable('EXAMPLE_TOKEN', $Value"));
        expect(ps, isNot(contains('@NAME@')));
      },
    );

    test('rejects a name that is not an environment variable name', () {
      expect(
        () => PromptEnvVar('bad name; rm'),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('envVarPrompts', () {
    test(r'finds ${NAME} placeholders in headers, args and env', () {
      var prompts = envVarPrompts({
        'a': {
          'headers': {'Authorization': r'Bearer ${EXAMPLE_TOKEN}'},
          'args': [r'--key=${OTHER}', r'${EXAMPLE_TOKEN}'],
        },
        'b': {
          'env': {'X': r'${THIRD}'},
        },
      });

      expect(
        [for (final p in prompts) p.name],
        ['EXAMPLE_TOKEN', 'OTHER', 'THIRD'],
      );
    });

    test('ignores plugin placeholders and plain text', () {
      var prompts = envVarPrompts({
        'a': {
          'command': r'${CLAUDE_PLUGIN_ROOT}/run',
          'args': [
            r'${PLUGIN_ROOT}',
            r'${PLUGIN_DATA}',
            r'${CLAUDE_PLUGIN_DATA}',
          ],
          'env': {'X': r'$NOT_BRACED'},
        },
      });

      expect(prompts, isEmpty);
    });

    test('is empty without MCP servers', () {
      expect(envVarPrompts(null), isEmpty);
    });
  });

  test('PowerShell installer uses backslash paths and checks exit codes', () {
    var ps = renderPowerShellInstaller(_steps, title: 'demo');

    expect(ps, contains(r"$ErrorActionPreference = 'Stop'"));
    expect(ps, contains("Write-Host '[1/2] Copy agents'"));
    expect(ps, contains(r"'demo\.codex\agents\*.toml'"));
    expect(ps, contains(r'if ($env:CODEX_HOME) { $env:CODEX_HOME }'));
    expect(ps, contains("Write-Host '[2/2] Add the it''s marketplace'"));
    expect(ps, contains(r"& 'codex' 'plugin' 'marketplace' 'add' $Here"));
    expect(ps, contains(r'$LASTEXITCODE -ne 0'));
  });
}
