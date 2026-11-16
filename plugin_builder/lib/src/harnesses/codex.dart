import '../agent.dart';
import '../harness.dart';
import '../install_script.dart';
import '../options.dart';
import 'portable.dart';

/// Codex: the portable package, a marketplace file, `.codex/agents/*.toml`
/// and install scripts.
///
/// Codex has no plugin agents component; it reads agents only from
/// `~/.codex/agents`, so the install scripts copy the `.toml` files there.
class CodexHarness implements Harness {
  const CodexHarness();

  @override
  String get id => 'codex';

  @override
  String get description =>
      'Codex: portable manifest + mcp.json, .codex/agents/*.toml, '
      'marketplace, install scripts';

  @override
  void emit(HarnessContext context) {
    var options = context.options;
    writePortableFiles(context);
    for (var agent in context.agents) {
      context
        ..writeInPackage(
          '.codex/agents/${agent.name}.toml',
          codexAgentFile(agent),
        )
        ..detail('  codex: .codex/agents/${agent.name}.toml');
    }
    context.writeJsonInRoot(
      '.agents/plugins/marketplace.json',
      _marketplace(options),
    );
    writeInstallScripts(context, [
      ...envVarPrompts(context.mcpServers),
      if (context.agents.isNotEmpty)
        CopyFiles(
          'Copy the agents into the Codex agents folder',
          from: '${options.name}/.codex/agents',
          pattern: '*.toml',
          destination: const HomeDirectory(
            envVar: 'CODEX_HOME',
            homeFallback: '.codex',
            subdirectory: 'agents',
          ),
        ),
      const RunCommand('Register the marketplace', 'codex', [
        'plugin',
        'marketplace',
        'add',
        installRoot,
      ]),
      RunCommand('Install the plugin', 'codex', [
        'plugin',
        'add',
        '${options.name}@${options.marketplace}',
      ]),
    ], title: '${options.name} for Codex');
  }
}

Map<String, dynamic> _marketplace(BuildOptions options) => {
  'name': options.marketplace,
  if (options.displayName != null)
    'interface': {'displayName': options.displayName},
  'plugins': [
    {
      'name': options.name,
      'source': {'source': 'local', 'path': './${options.name}'},
      'policy': {'installation': 'AVAILABLE', 'authentication': 'ON_INSTALL'},
      'category': options.category,
    },
  ],
};

/// Codex `.codex/agents/<name>.toml`. Tools and `model` are dropped (Codex
/// agents inherit the parent's tools and take Codex model slugs).
String codexAgentFile(Agent agent) {
  var buffer = StringBuffer()
    ..writeln('name = ${_tomlString(agent.name)}')
    ..writeln('description = ${_tomlString(agent.description)}')
    ..writeln('developer_instructions = ${_tomlMultiline(agent.body)}');
  var effort = agent.effort;
  if (effort != null) {
    buffer.writeln('model_reasoning_effort = ${_tomlString(effort)}');
  }
  return buffer.toString();
}

String _tomlString(String value) {
  var escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n');
  return '"$escaped"';
}

String _tomlMultiline(String value) {
  var escaped = value.replaceAll(r'\', r'\\').replaceAll('"""', r'\"\"\"');
  return '"""\n$escaped\n"""';
}
