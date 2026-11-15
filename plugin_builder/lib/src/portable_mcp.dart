import 'build_exception.dart';

const String _portableMcpSchema =
    'https://agent-plugins.org/schemas/1.0.0/mcp.schema.json';

const String _claudeRoot = r'${CLAUDE_PLUGIN_ROOT}';
const String _claudeData = r'${CLAUDE_PLUGIN_DATA}';
const String _portableRoot = r'${PLUGIN_ROOT}';
const String _portableData = r'${PLUGIN_DATA}';

const Map<String, Set<String>> _allowedFields = {
  'stdio': {'type', 'command', 'args', 'env', 'cwd'},
  'streamable-http': {'type', 'url', 'headers'},
  'sse': {'type', 'url', 'headers'},
};

/// The portable `mcp.json` (Agent Plugins 1.0) for Claude-style [servers].
///
/// The portable format is stricter than Claude's, so each server is converted
/// rather than copied:
///
/// - `type` is required: `http` becomes `streamable-http`, a missing one is
///   inferred (`url` means `streamable-http`, else `stdio`), and `ws` or any
///   other value cannot be expressed.
/// - Claude's plugin-root and plugin-data placeholders become the portable
///   ones, but only where the format expands them: `args`, `env` values and
///   `cwd`. A leading `${CLAUDE_PLUGIN_ROOT}/` in `command` becomes `./`.
/// - Every server variant is closed: a field it does not define is an error.
///
/// Throws a [BuildException] listing every server that cannot be converted.
Map<String, dynamic> portableMcp(Map<String, dynamic> servers) {
  var problems = <String>[];
  var converted = <String, dynamic>{
    for (final entry in servers.entries)
      entry.key: _Conversion(entry.key, entry.value, problems).run(),
  };
  if (problems.isNotEmpty) {
    throw BuildException(
      'MCP config cannot be written in the portable format:\n'
      '${problems.map((p) => '  - $p').join('\n')}',
      exitCode: BuildException.validationExitCode,
    );
  }
  return {r'$schema': _portableMcpSchema, 'mcpServers': converted};
}

/// Converts one server, recording what cannot be converted in [problems].
class _Conversion {
  _Conversion(this.name, this.server, this.problems);

  final String name;
  final Object? server;
  final List<String> problems;

  Map<String, dynamic> run() {
    var raw = server;
    if (raw is! Map) {
      _problem('is not an object');
      return {};
    }
    var type = _type(raw);
    if (type == null) return {};
    var allowed = _allowedFields[type]!;
    for (var key in raw.keys) {
      if (!allowed.contains(key)) {
        _problem('field "$key" has no portable equivalent for type $type');
      }
    }
    return {
      'type': type,
      if (type == 'stdio') ..._stdio(raw) else ..._http(raw),
    };
  }

  String? _type(Map<dynamic, dynamic> raw) {
    var declared = raw['type'];
    if (declared == null) {
      return raw.containsKey('url') ? 'streamable-http' : 'stdio';
    }
    var type = declared == 'http' ? 'streamable-http' : declared;
    if (!_allowedFields.containsKey(type)) {
      _problem('transport type "$declared" has no portable equivalent');
      return null;
    }
    return type as String;
  }

  Map<String, dynamic> _stdio(Map<dynamic, dynamic> raw) => {
    'command': _command(raw['command']),
    if (raw.containsKey('args')) 'args': _args(raw['args']),
    if (raw.containsKey('env')) 'env': _env(raw['env']),
    if (raw.containsKey('cwd')) 'cwd': _expand(_string(raw['cwd'], 'cwd')),
  };

  Map<String, dynamic> _http(Map<dynamic, dynamic> raw) => {
    'url': _url(raw['url']),
    if (raw.containsKey('headers')) 'headers': _headers(raw['headers']),
  };

  String _command(Object? value) {
    var command = _string(value, 'command');
    if (command.startsWith('$_claudeRoot/')) {
      command = './${command.substring(_claudeRoot.length + 1)}';
    }
    if (command.contains(_claudeRoot) || command.contains(_claudeData)) {
      _problem(
        'command "$command" uses a plugin placeholder, which the portable '
        'format does not expand in "command" (use a ./ path)',
      );
    } else if (RegExp(r'\s').hasMatch(command)) {
      _problem('command "$command" must be one executable, not a shell string');
    } else if (command.contains('/') && !command.startsWith('./')) {
      _problem(
        'command "$command" must be a bare executable name or a ./ plugin '
        'path',
      );
    }
    return command;
  }

  List<String> _args(Object? value) {
    if (value is! List) {
      _problem('field "args" is not a list');
      return [];
    }
    return [for (final arg in value) _expand(_string(arg, 'args item'))];
  }

  Map<String, String> _env(Object? value) {
    var env = _stringMap(value, 'env');
    for (var key in ['PLUGIN_ROOT', 'PLUGIN_DATA']) {
      if (env.containsKey(key)) _problem('env key "$key" is reserved');
    }
    return {for (final e in env.entries) e.key: _expand(e.value)};
  }

  String _url(Object? value) {
    var url = _string(value, 'url');
    if (url.contains(r'${CLAUDE_PLUGIN_')) {
      _problem('url "$url" uses a plugin placeholder, which is not expanded');
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _problem('url "$url" must be an absolute http or https URL');
    }
    return url;
  }

  Map<String, String> _headers(Object? value) {
    var headers = _stringMap(value, 'headers');
    for (var entry in headers.entries) {
      if (entry.value.contains(r'${CLAUDE_PLUGIN_')) {
        _problem(
          'header "${entry.key}" uses a plugin placeholder, which is not '
          'expanded',
        );
      }
    }
    return headers;
  }

  String _expand(String value) => value
      .replaceAll(_claudeRoot, _portableRoot)
      .replaceAll(_claudeData, _portableData);

  String _string(Object? value, String field) {
    if (value is String) return value;
    _problem('field "$field" is not a string');
    return '';
  }

  Map<String, String> _stringMap(Object? value, String field) {
    if (value is! Map) {
      _problem('field "$field" is not an object');
      return {};
    }
    return {for (final e in value.entries) '${e.key}': _string(e.value, field)};
  }

  void _problem(String message) => problems.add('server "$name": $message');
}
