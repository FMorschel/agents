import 'package:plugin_builder/src/agent.dart';
import 'package:plugin_builder/src/harnesses/claude.dart';
import 'package:plugin_builder/src/harnesses/codex.dart';
import 'package:plugin_builder/src/harnesses/vscode.dart';
import 'package:test/test.dart';

const String _source = r'''
---
name: test writer
description: "Writes tests, \"carefully\"."
tools: Read, Grep, Glob, Skill, mcp__dart-sdk__analyze_files, mcp__dart-sdk__lsp
model: sonnet
effort: high
mode: subagent
permission:
  edit: deny
---

# Test Writer

Body.
''';

void main() {
  var agent = Agent.parse(_source, fallbackName: 'fallback');

  group('Agent.parse', () {
    test('slugifies the name and reads the neutral fields', () {
      expect(agent.name, 'test-writer');
      expect(agent.description, 'Writes tests, "carefully".');
      expect(agent.model, 'sonnet');
      expect(agent.effort, 'high');
      expect(agent.tools, [
        'Read',
        'Grep',
        'Glob',
        'Skill',
        'mcp__dart-sdk__analyze_files',
        'mcp__dart-sdk__lsp',
      ]);
      expect(agent.body, '# Test Writer\n\nBody.');
    });

    test('falls back to the file name when the frontmatter has no name', () {
      var unnamed = Agent.parse('# Just a body', fallbackName: 'plain');
      expect(unnamed.name, 'plain');
      expect(unnamed.body, '# Just a body');
    });
  });

  group('copilotTools', () {
    test('maps, deduplicates and collapses MCP tools per server', () {
      expect(copilotTools(agent.tools), ['read', 'search', 'dart-sdk/*']);
    });

    test('drops tokens with no Copilot equivalent', () {
      expect(copilotTools(['Skill', 'SendMessage', 'ListAgents']), isEmpty);
    });
  });

  group('agent files', () {
    test('Claude keeps model and effort and joins tools with commas', () {
      var text = claudeAgentFile(agent);
      expect(text, contains('name: test-writer'));
      expect(text, contains('tools: Read, Grep, Glob, Skill,'));
      expect(text, contains('model: sonnet'));
      expect(text, contains('effort: high'));
      expect(text, isNot(contains('mode:')));
      expect(text, isNot(contains('permission')));
    });

    test('Copilot drops model and renames effort', () {
      var text = copilotAgentFile(agent);
      expect(text, contains("tools: ['read', 'search', 'dart-sdk/*']"));
      expect(text, contains('reasoning-effort: high'));
      expect(text, isNot(contains('model:')));
    });

    test('Codex emits TOML with the body as developer_instructions', () {
      var text = codexAgentFile(agent);
      expect(text, contains('name = "test-writer"'));
      expect(text, contains(r'description = "Writes tests, \"carefully\"."'));
      expect(text, contains('developer_instructions = """\n# Test Writer'));
      expect(text, contains('model_reasoning_effort = "high"'));
      expect(text, isNot(contains('tools')));
    });

    test('Codex escapes triple quotes in the body', () {
      const tricky = Agent(
        name: 'a',
        description: 'd',
        tools: [],
        body: 'say """hi"""',
      );
      expect(codexAgentFile(tricky), contains(r'\"\"\"hi\"\"\"'));
    });
  });
}
