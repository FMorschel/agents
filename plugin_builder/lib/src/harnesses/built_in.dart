import '../harness.dart';
import 'claude.dart';
import 'codex.dart';
import 'portable.dart';
import 'vscode.dart';

/// Every harness the builder knows. Add a new client's [Harness] here.
const List<Harness> builtInHarnesses = [
  ClaudeHarness(),
  CodexHarness(),
  VsCodeHarness(),
  PortableHarness(),
];
