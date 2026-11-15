/// A failure the CLI reports to the user without a stack trace.
class BuildException implements Exception {
  const BuildException(this.message, {this.exitCode = usageExitCode});

  /// Exit code for bad arguments or a missing config/source.
  static const int usageExitCode = 64;

  /// Exit code for a source collection that fails validation.
  static const int validationExitCode = 2;

  final String message;
  final int exitCode;

  @override
  String toString() => message;
}
