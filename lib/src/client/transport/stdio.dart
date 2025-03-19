/// Standard IO transport for MCP client.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../src/base/session.dart';

/// A transport implementation that uses standard input and output
/// for communication with a child process.
class StdioTransport implements Transport {
  final Process _process;
  final StreamController<String> _incomingController =
      StreamController<String>();

  /// Creates a new [StdioTransport] instance.
  StdioTransport(this._process) {
    _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleStdout, onError: _handleError);

    _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleStderr);
  }

  @override
  Stream<String> get incoming => _incomingController.stream;

  @override
  Future<void> send(String message) async {
    _process.stdin.writeln(message);
    await _process.stdin.flush();
  }

  @override
  Future<void> close() async {
    await _process.stdin.close();
    await _incomingController.close();

    // Kill the process if it's still running
    if (_process.kill()) {
      // Wait for the process to exit
      await _process.exitCode;
    }
  }

  /// Handles a line from the process's stdout.
  void _handleStdout(String line) {
    if (line.isNotEmpty) {
      _incomingController.add(line);
    }
  }

  /// Handles a line from the process's stderr.
  void _handleStderr(String line) {
    // Log stderr output (could replace with proper logging)
    print('StdioTransport stderr: $line');
  }

  /// Handles an error from the process's stdout or stderr.
  void _handleError(Object error) {
    _incomingController.addError(error);
  }
}
