import 'package:plugin_builder/plugin_builder.dart';
import 'package:plugin_builder/src/portable_mcp.dart';
import 'package:test/test.dart';

Map<String, Map<String, dynamic>> _convert(Map<String, dynamic> servers) => {
  for (final entry in (portableMcp(servers)['mcpServers'] as Map).entries)
    '${entry.key}': (entry.value as Map).cast<String, dynamic>(),
};

Matcher _rejects(Pattern message) => throwsA(
  isA<BuildException>()
      .having((e) => e.exitCode, 'exitCode', 2)
      .having((e) => e.message, 'message', contains(message)),
);

void main() {
  test('wraps the servers with the required schema', () {
    expect(portableMcp({}), {
      r'$schema': 'https://agent-plugins.org/schemas/1.0.0/mcp.schema.json',
      'mcpServers': <String, dynamic>{},
    });
  });

  group('stdio servers', () {
    test('get type stdio and keep their fields', () {
      expect(
        _convert({
          'dart': {
            'command': 'npx',
            'args': ['-y', 'server'],
            'env': {'A': 'b'},
            'cwd': './sub',
          },
        }),
        {
          'dart': {
            'type': 'stdio',
            'command': 'npx',
            'args': ['-y', 'server'],
            'env': {'A': 'b'},
            'cwd': './sub',
          },
        },
      );
    });

    test('an explicit stdio type is kept', () {
      expect(
        _convert({
          'a': {'type': 'stdio', 'command': 'node'},
        }),
        {
          'a': {'type': 'stdio', 'command': 'node'},
        },
      );
    });

    test('placeholders are expanded in args, env values and cwd', () {
      expect(
        _convert({
          'a': {
            'command': 'node',
            'args': [r'${CLAUDE_PLUGIN_ROOT}/server.js', '--x'],
            'env': {'DB': r'${CLAUDE_PLUGIN_DATA}/db'},
            'cwd': r'${CLAUDE_PLUGIN_ROOT}',
          },
        })['a'],
        {
          'type': 'stdio',
          'command': 'node',
          'args': [r'${PLUGIN_ROOT}/server.js', '--x'],
          'env': {'DB': r'${PLUGIN_DATA}/db'},
          'cwd': r'${PLUGIN_ROOT}',
        },
      );
    });

    test('a leading plugin root in command becomes a ./ path', () {
      expect(
        _convert({
          'a': {'command': r'${CLAUDE_PLUGIN_ROOT}/bin/run'},
        })['a']!['command'],
        './bin/run',
      );
    });

    test('a ./ path and a bare name are accepted as they are', () {
      expect(
        _convert({
          'a': {'command': './bin/run'},
        })['a']!['command'],
        './bin/run',
      );
      expect(
        _convert({
          'a': {'command': 'node'},
        })['a']!['command'],
        'node',
      );
    });

    test('a placeholder elsewhere in command is rejected', () {
      expect(
        () => portableMcp({
          'a': {'command': r'x${CLAUDE_PLUGIN_ROOT}'},
        }),
        _rejects('does not expand in "command"'),
      );
    });

    test('a shell string or non-plugin path as command is rejected', () {
      expect(
        () => portableMcp({
          'a': {'command': 'node server.js'},
        }),
        _rejects('not a shell string'),
      );
      expect(
        () => portableMcp({
          'a': {'command': '/usr/bin/node'},
        }),
        _rejects('bare executable name or a ./ plugin path'),
      );
    });

    test('a missing command and a reserved env key are rejected', () {
      expect(
        () => portableMcp({'a': <String, dynamic>{}}),
        _rejects('"command"'),
      );
      expect(
        () => portableMcp({
          'a': {
            'command': 'x',
            'env': {'PLUGIN_ROOT': 'y'},
          },
        }),
        _rejects('env key "PLUGIN_ROOT" is reserved'),
      );
    });
  });

  group('http servers', () {
    test('a url without a type becomes streamable-http', () {
      expect(
        _convert({
          'a': {'url': 'https://x.dev/mcp'},
        }),
        {
          'a': {'type': 'streamable-http', 'url': 'https://x.dev/mcp'},
        },
      );
    });

    test("Claude's http alias becomes streamable-http", () {
      expect(
        _convert({
          'a': {
            'type': 'http',
            'url': 'https://x.dev/mcp',
            'headers': {'Authorization': 'Bearer t'},
          },
        })['a'],
        {
          'type': 'streamable-http',
          'url': 'https://x.dev/mcp',
          'headers': {'Authorization': 'Bearer t'},
        },
      );
    });

    test('streamable-http and sse are kept', () {
      expect(
        _convert({
          'a': {'type': 'sse', 'url': 'https://x.dev/sse'},
        })['a']!['type'],
        'sse',
      );
      expect(
        _convert({
          'a': {'type': 'streamable-http', 'url': 'https://x.dev/m'},
        })['a']!['type'],
        'streamable-http',
      );
    });

    test(
      'placeholders in url and headers, and non-http urls, are rejected',
      () {
        expect(
          () => portableMcp({
            'a': {'url': r'https://x.dev/${CLAUDE_PLUGIN_ROOT}'},
          }),
          _rejects('url'),
        );
        expect(
          () => portableMcp({
            'a': {
              'url': 'https://x.dev',
              'headers': {'X': r'${CLAUDE_PLUGIN_ROOT}'},
            },
          }),
          _rejects('header "X"'),
        );
        expect(
          () => portableMcp({
            'a': {'url': 'ws://x.dev'},
          }),
          _rejects('absolute http or https URL'),
        );
      },
    );
  });

  group('what has no portable equivalent', () {
    test('websocket and unknown transports are rejected', () {
      expect(
        () => portableMcp({
          'a': {'type': 'ws', 'url': 'wss://x.dev'},
        }),
        _rejects('transport type "ws"'),
      );
    });

    test('fields a variant does not define are rejected', () {
      expect(
        () => portableMcp({
          'a': {'command': 'x', 'envFile': '.env'},
        }),
        _rejects('field "envFile" has no portable equivalent'),
      );
      expect(
        () => portableMcp({
          'a': {'url': 'https://x.dev', 'command': 'x'},
        }),
        _rejects('field "command" has no portable equivalent'),
      );
    });

    test('a server that is not an object is rejected', () {
      expect(() => portableMcp({'a': 'node'}), _rejects('is not an object'));
    });

    test('every problem of every server is reported at once', () {
      expect(
        () => portableMcp({
          'one': {'type': 'ws', 'url': 'wss://x'},
          'two': {'command': 'a b'},
        }),
        throwsA(
          isA<BuildException>().having(
            (e) => e.message,
            'message',
            allOf(contains('server "one"'), contains('server "two"')),
          ),
        ),
      );
    });
  });
}
