/// Standard IO transport for MCP server.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../src/base/session.dart';

/// A transport implementation that uses standard input and output
/// for communication with the parent process.
class StdioTransport implements Transport {
  final StreamController<String> _incomingController =
      StreamController<String>();

  final bool _closeOnEof;
  StreamSubscription? _stdinSubscription;

  /// Creates a new [StdioTransport] instance.
  ///
  /// If [closeOnEof] is true, the transport will close when stdin is closed.
  StdioTransport({bool closeOnEof = true}) : _closeOnEof = closeOnEof {
    _stdinSubscription = stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleStdin, onDone: _handleStdinDone);
  }

  @override
  Stream<String> get incoming => _incomingController.stream;

  @override
  Future<void> send(String message) async {
    stdout.writeln(message);
    await stdout.flush();
  }

  @override
  Future<void> close() async {
    await _stdinSubscription?.cancel();
    await _incomingController.close();
  }

  /// Handles a line from stdin.
  void _handleStdin(String line) {
    if (line.isNotEmpty) {
      _incomingController.add(line);
    }
  }

  /// Handles stdin closing.
  void _handleStdinDone() {
    if (_closeOnEof) {
      close();
    }
  }
}
