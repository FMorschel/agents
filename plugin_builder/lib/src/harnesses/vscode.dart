import '../agent.dart';
import '../escape.dart';
import '../harness.dart';
import '../install_script.dart';
import 'portable.dart';

/// VS Code / Copilot: the portable package plus
/// `com.github.copilot/agents/*.agent.md`.
///
/// VS Code has no CLI to install a plugin (it is enabled through settings),
/// so install scripts are written only when the MCP servers need environment
/// variables (they just ask for them).
class VsCodeHarness implements Harness {
  const VsCodeHarness();

  @override
  String get id => 'vscode';

  @override
  String get description =>
      'VS Code / Copilot: portable manifest + mcp.json, Copilot agent files';

  @override
  void emit(HarnessContext context) {
    writePortableFiles(context);
    for (var agent in context.agents) {
      var path = 'com.github.copilot/agents/${agent.name}.agent.md';
      context
        ..writeInPackage(path, copilotAgentFile(agent))
        ..detail('  vscode: $path');
    }
    // No plugin to install, so the scripts exist only to ask for the MCP
    // servers' environment variables.
    var prompts = envVarPrompts(context.mcpServers);
    if (prompts.isNotEmpty) {
      writeInstallScripts(
        context,
        prompts,
        title: '${context.options.name} for VS Code',
      );
    }
  }
}

/// Copilot agent file. `model` is dropped (Copilot takes its own model ids)
/// and `effort` becomes `reasoning-effort`.
String copilotAgentFile(Agent agent) {
  var tools = copilotTools(agent.tools);
  var frontmatter = <String>[
    'name: ${agent.name}',
    'description: ${yamlString(agent.description)}',
    if (tools.isNotEmpty) "tools: [${tools.map((t) => "'$t'").join(', ')}]",
    if (agent.effort != null) 'reasoning-effort: ${agent.effort}',
  ];
  return '---\n${frontmatter.join('\n')}\n---\n\n${agent.body}\n';
}

const Map<String, String> _copilotToolMap = {
  'Read': 'read',
  'Grep': 'search',
  'Glob': 'search',
  'WebFetch': 'web',
  'WebSearch': 'web',
  'Write': 'edit',
  'Edit': 'edit',
  'Bash': 'execute',
  'Agent': 'agent',
  'TodoWrite': 'todo',
};

/// Maps Claude-style tool names to Copilot's coarse aliases, in first-seen
/// order without duplicates. MCP tools collapse to `<server>/*`; tokens with
/// no Copilot equivalent (`Skill`, `SendMessage`, `ListAgents`) are dropped.
List<String> copilotTools(List<String> tools) {
  var mapped = <String>[];
  for (var tool in tools) {
    var alias = tool.startsWith('mcp__')
        ? _mcpServerAlias(tool)
        : _copilotToolMap[tool];
    if (alias != null && !mapped.contains(alias)) mapped.add(alias);
  }
  return mapped;
}

String? _mcpServerAlias(String tool) {
  var parts = tool.split('__');
  return parts.length >= 2 ? '${parts[1]}/*' : null;
}
