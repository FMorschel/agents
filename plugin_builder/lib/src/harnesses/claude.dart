import '../agent.dart';
import '../escape.dart';
import '../harness.dart';
import '../install_script.dart';
import '../manifests.dart';
import '../options.dart';

/// Claude Code: `.claude-plugin/plugin.json`, `agents/*.md`, `.mcp.json`, a
/// marketplace file and install scripts.
class ClaudeHarness implements Harness {
  const ClaudeHarness();

  @override
  String get id => 'claude';

  @override
  String get description =>
      'Claude Code: agents/*.md, .mcp.json, marketplace, install scripts';

  @override
  void emit(HarnessContext context) {
    var options = context.options;
    context.writeJsonInPackage(
      '.claude-plugin/plugin.json',
      _manifest(options),
    );
    for (var agent in context.agents) {
      context
        ..writeInPackage('agents/${agent.name}.md', claudeAgentFile(agent))
        ..detail('  claude: agents/${agent.name}.md');
    }
    var servers = context.mcpServers;
    if (servers != null) {
      context.writeJsonInPackage('.mcp.json', claudeMcp(servers));
    }
    context.writeJsonInRoot(
      '.claude-plugin/marketplace.json',
      _marketplace(options),
    );
    writeInstallScripts(context, [
      ...envVarPrompts(servers),
      const RunCommand('Register the marketplace', 'claude', [
        'plugin',
        'marketplace',
        'add',
        installRoot,
      ]),
      RunCommand('Install the plugin', 'claude', [
        'plugin',
        'install',
        '${options.name}@${options.marketplace}',
      ]),
    ], title: '${options.name} for Claude Code');
  }
}

Map<String, dynamic> _manifest(BuildOptions options) => {
  'name': options.name,
  'version': options.version,
  if (options.description != null) 'description': options.description,
  if (options.author != null) 'author': {'name': options.author},
};

Map<String, dynamic> _marketplace(BuildOptions options) => {
  'name': options.marketplace,
  if (options.description != null) 'description': options.description,
  'owner': {'name': options.author ?? options.marketplace},
  'plugins': [
    {
      'name': options.name,
      'source': './${options.name}',
      if (options.description != null) 'description': options.description,
    },
  ],
};

/// Claude Code `agents/<name>.md`: every field passes through unchanged.
String claudeAgentFile(Agent agent) {
  var frontmatter = <String>[
    'name: ${agent.name}',
    'description: ${yamlString(agent.description)}',
    if (agent.tools.isNotEmpty) 'tools: ${agent.tools.join(', ')}',
    if (agent.model != null) 'model: ${agent.model}',
    if (agent.effort != null) 'effort: ${agent.effort}',
  ];
  return '---\n${frontmatter.join('\n')}\n---\n\n${agent.body}\n';
}
