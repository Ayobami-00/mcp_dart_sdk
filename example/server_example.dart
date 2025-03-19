import 'dart:async';
import 'dart:io';

import 'package:mcp_dart_sdk/src/base/session.dart';
import 'package:mcp_dart_sdk/src/base/types.dart';
import 'package:mcp_dart_sdk/src/server/server.dart';
import 'package:mcp_dart_sdk/src/server/transport/stdio.dart';
import 'package:mcp_dart_sdk/src/server/transport/http_sse.dart';
import 'package:mcp_dart_sdk/src/server/transport/websocket.dart';

/// A simple MCP server example that demonstrates different transport options.
Future<void> main(List<String> args) async {
  // Parse transport type from arguments
  final transportType = args.isNotEmpty ? args[0] : 'stdio';

  print('Starting MCP server with $transportType transport...');

  // Create a server
  final server = McpServer(
    serverInfo: ServerInfo(name: 'Dart MCP Server', version: '0.1.0'),
    capabilities: ServerCapabilities(
      tools: {'list': true, 'execute': true},
      resources: {'list': true, 'read': true, 'write': true},
    ),
  );

  // Register a custom method handler
  server.registerMethodHandler('echo', (method, params) async {
    print('Received echo request: $params');
    return {'echo': params};
  });

  // Register a calculation tool
  server.registerMethodHandler('tools/list', (method, params) async {
    return {
      'tools': [
        {
          'name': 'calculator',
          'description': 'A simple calculator tool',
          'schema': {
            'type': 'object',
            'properties': {
              'operation': {
                'type': 'string',
                'enum': ['add', 'subtract', 'multiply', 'divide']
              },
              'a': {'type': 'number'},
              'b': {'type': 'number'}
            },
            'required': ['operation', 'a', 'b']
          }
        }
      ]
    };
  });

  server.registerMethodHandler('tools/execute', (method, params) async {
    final Map<String, dynamic> toolParams = params as Map<String, dynamic>;

    if (toolParams['name'] != 'calculator') {
      throw Exception('Unknown tool: ${toolParams['name']}');
    }

    final Map<String, dynamic> args =
        toolParams['params'] as Map<String, dynamic>;
    final String operation = args['operation'] as String;
    final num a = args['a'] as num;
    final num b = args['b'] as num;

    num result;
    switch (operation) {
      case 'add':
        result = a + b;
        break;
      case 'subtract':
        result = a - b;
        break;
      case 'multiply':
        result = a * b;
        break;
      case 'divide':
        if (b == 0) {
          throw Exception('Division by zero');
        }
        result = a / b;
        break;
      default:
        throw Exception('Unknown operation: $operation');
    }

    return {'result': result};
  });

  // Create the appropriate transport
  Transport transport;
  switch (transportType) {
    case 'http':
      final httpTransport = HttpSseServerTransport();
      await httpTransport.start();
      print('HTTP server listening on http://localhost:8000');
      print('SSE endpoint: http://localhost:8000/events');
      print('Post endpoint: http://localhost:8000/send');
      transport = httpTransport;
      break;

    case 'ws':
      final wsTransport = WebSocketServerTransport();
      await wsTransport.start();
      print('WebSocket server listening on ws://localhost:8000/ws');
      transport = wsTransport;
      break;

    case 'stdio':
    default:
      transport = StdioTransport();
      print(
          'Server running on stdio. Communicate through standard input/output.');
      break;
  }

  // Start the server
  await server.start(transport);
  print('Server started successfully.');

  // Keep the server running until user terminates it
  if (transportType != 'stdio') {
    print('Press Ctrl+C to stop the server.');

    // Set up signal handling for clean shutdown
    ProcessSignal.sigint.watch().listen((signal) async {
      print('Received termination signal. Shutting down...');
      await server.stop();
      exit(0);
    });

    // Keep the server running
    await Completer<void>().future;
  }
}
