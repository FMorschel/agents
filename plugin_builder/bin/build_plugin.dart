import 'dart:io';

import 'package:plugin_builder/plugin_builder.dart';

String _usage() =>
    '''
Usage: dart run plugin_builder:build_plugin --source <dir> --name <id> [options]
       dart run plugin_builder:build_plugin --config <file.json> [options]

Builds one self-contained plugin folder per target (${builtInHarnesses.map((h) => h.id).join(', ')})
into <out>/<target>/.

${buildArgParser().usage}''';

/// Asks on the terminal; with no terminal to ask on, the answer is no.
bool _askOnTerminal(String question) {
  if (!stdin.hasTerminal) return false;
  stdout.write('$question Continue? [y/N] ');
  var answer = stdin.readLineSync()?.trim().toLowerCase();
  return answer == 'y' || answer == 'yes';
}

void main(List<String> args) {
  if (args.contains('--list-targets')) {
    stdout.writeln(describeHarnesses(builtInHarnesses));
    return;
  }
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage());
    return;
  }
  try {
    var options = BuildOptions.parse(args);
    var result = PluginBuilder(
      options,
      confirm: _askOnTerminal,
      log: stdout.writeln,
    ).build();
    stdout.writeln(
      'build_plugin: done — ${options.name} '
      '(${result.skills} skill(s), ${result.agents} agent(s)) '
      'for ${result.harnesses.join(', ')} in ${options.out.path}',
    );
  } on BuildException catch (error) {
    stderr.writeln('build_plugin: $error');
    exit(error.exitCode);
  }
}
