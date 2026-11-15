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
