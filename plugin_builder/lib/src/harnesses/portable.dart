import '../harness.dart';
import '../manifests.dart';
import '../portable_mcp.dart';

/// The vendor-neutral Agent Plugins 1.0 package: `plugin.json` plus `mcp.json`
/// next to the skills. Carries no agents. The id carries the format version,
/// so a later Agent Plugins version can be added beside it.
class PortableHarness implements Harness {
  const PortableHarness();

  @override
  String get id => 'portable-v1.0';

  @override
  String get description =>
      'Agent Plugins 1.0 (vendor-neutral): skills + MCP, no agents';

  @override
  void emit(HarnessContext context) => writePortableFiles(context);
}

/// Writes the portable `plugin.json` and, when MCP servers are configured,
/// `mcp.json`. Codex and VS Code read this same format.
void writePortableFiles(HarnessContext context) {
  context.writeJsonInPackage('plugin.json', portableManifest(context.options));
  var servers = context.mcpServers;
  if (servers != null) {
    context.writeJsonInPackage('mcp.json', portableMcp(servers));
  }
}
