/// Builds a cross-platform plugin package (Claude Code, Codex, VS Code/Copilot)
/// from a collection of skills, agents and prompts.
library;

export 'src/agent.dart' show Agent;
export 'src/build_exception.dart' show BuildException;
export 'src/environment.dart'
    show BuildEnvironment, GitFilesLookup, MakeExecutable;
export 'src/harness.dart' show Harness, HarnessContext, describeHarnesses;
export 'src/harnesses/built_in.dart' show builtInHarnesses;
export 'src/install_script.dart'
    show
        CopyFiles,
        HomeDirectory,
        InstallStep,
        RunCommand,
        installRoot,
        renderPowerShellInstaller,
        renderShellInstaller,
        writeInstallScripts;
export 'src/options.dart' show BuildOptions, FileSelection, buildArgParser;
export 'src/plugin_builder.dart' show BuildResult, PluginBuilder;
