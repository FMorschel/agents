import 'options.dart';

const String _portablePluginSchema =
    'https://agent-plugins.org/schemas/1.0.0/plugin.schema.json';

/// Root `plugin.json` (Agent Plugins 1.0).
Map<String, dynamic> portableManifest(BuildOptions options) => {
  r'$schema': _portablePluginSchema,
  'name': options.name,
  'version': options.version,
  if (options.description != null) 'description': options.description,
  if (options.author != null) 'author': {'name': options.author},
  if (options.repository != null) 'repository': options.repository,
  if (options.license != null) 'license': options.license,
};

/// The server map of an MCP config, whether or not it is wrapped in
/// `mcpServers`.
Map<String, dynamic> mcpServers(Map<String, dynamic> raw) {
  var servers = raw['mcpServers'];
  if (servers is Map) return servers.map((k, v) => MapEntry('$k', v));
  return raw;
}

/// Claude's `.mcp.json`.
Map<String, dynamic> claudeMcp(Map<String, dynamic> servers) => {
  'mcpServers': servers,
};
