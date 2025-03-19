import 'dart:async';
import 'dart:convert';

import 'package:mcp_dart_sdk/src/base/lifecycle.dart';
import 'package:mcp_dart_sdk/src/base/session.dart';
import 'package:mcp_dart_sdk/src/base/types.dart';
import 'package:mcp_dart_sdk/src/client/client.dart';

/// A very simple in-memory transport for testing.
/// This provides both client and server sides of the transport.
class InMemoryTransport implements Transport {
  final StreamController<String> _incomingController =
      StreamController<String>();
  InMemoryTransport? _other;

  @override
  Stream<String> get incoming => _incomingController.stream;

  /// Links this transport to another transport.
  void linkTo(InMemoryTransport other) {
    _other = other;
  }

  @override
  Future<void> send(String message) async {
    if (_other == null) {
      throw Exception('Transport not linked');
    }
    _other!._incomingController.add(message);
  }

  @override
  Future<void> close() async {
    await _incomingController.close();
  }
}

/// A very simple MCP server implementation for testing.
class SimpleServer {
  final InMemoryTransport _transport;
  final ServerInfo _serverInfo;
  final ServerCapabilities _capabilities;

  Map<String, dynamic>? _initialize(Map<String, dynamic> params) {
    return {
      'serverInfo': _serverInfo.toJson(),
      'capabilities': _capabilities.toJson(),
    };
  }

  Map<String, dynamic>? _shutdown(Map<String, dynamic> params) {
    return {};
  }

  Map<String, dynamic>? _toolsList(Map<String, dynamic> params) {
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
  }

  Map<String, dynamic>? _toolsExecute(Map<String, dynamic> params) {
    if (params['name'] == 'calculator') {
      final toolParams = params['params'] as Map<String, dynamic>;
      final operation = toolParams['operation'] as String;
      final a = toolParams['a'] as num;
      final b = toolParams['b'] as num;

      switch (operation) {
        case 'add':
          return {'result': a + b};
        case 'subtract':
          return {'result': a - b};
        case 'multiply':
          return {'result': a * b};
        case 'divide':
          if (b == 0) {
            throw Exception('Division by zero');
          }
          return {'result': a / b};
        default:
          throw Exception('Unknown operation: $operation');
      }
    } else {
      throw Exception('Unknown tool: ${params['name']}');
    }
  }

  /// Creates a new SimpleServer.
  SimpleServer(
    this._transport, {
    String name = 'Simple MCP Server',
    String version = '0.1.0',
  })  : _serverInfo = ServerInfo(name: name, version: version),
        _capabilities = ServerCapabilities(
          tools: {'execute': true, 'list': true},
        ) {
    _startHandlingRequests();
  }

  /// Starts handling requests from the client.
  void _startHandlingRequests() {
    _transport.incoming.listen((message) {
      final request = json.decode(message) as Map<String, dynamic>;

      if (request.containsKey('method')) {
        final method = request['method'] as String;
        final params = request['params'] as Map<String, dynamic>?;

        try {
          Map<String, dynamic>? result;

          switch (method) {
            case 'initialize':
              result = _initialize(params ?? {});
              break;
            case 'shutdown':
              result = _shutdown(params ?? {});
              break;
            case 'tools/list':
              result = _toolsList(params ?? {});
              break;
            case 'tools/execute':
              result = _toolsExecute(params ?? {});
              break;
            default:
              // Ignore unknown methods or notifications
              if (request.containsKey('id')) {
                _sendErrorResponse(
                    request['id'], -32601, 'Method not found: $method');
              }
              return;
          }

          if (request.containsKey('id')) {
            _sendSuccessResponse(request['id'], result);
          }
        } catch (e) {
          if (request.containsKey('id')) {
            _sendErrorResponse(request['id'], -32603, e.toString());
          }
        }
      }
    });
  }

  /// Sends a success response.
  void _sendSuccessResponse(dynamic id, Map<String, dynamic>? result) {
    _transport.send(json.encode({
      'jsonrpc': '2.0',
      'id': id,
      'result': result,
    }));
  }

  /// Sends an error response.
  void _sendErrorResponse(dynamic id, int code, String message) {
    _transport.send(json.encode({
      'jsonrpc': '2.0',
      'id': id,
      'error': {
        'code': code,
        'message': message,
      },
    }));
  }
}

/// This example demonstrates using a simple in-memory server with the MCP client.
/// This doesn't require any external dependencies like the Python server.
Future<void> main() async {
  // Create the transport for both client and server
  final clientTransport = InMemoryTransport();
  final serverTransport = InMemoryTransport();

  // Link them together
  clientTransport.linkTo(serverTransport);
  serverTransport.linkTo(clientTransport);

  // Create a simple server
  final server = SimpleServer(serverTransport);

  // Create a client
  final client = McpClient();

  try {
    // Connect to the in-memory server
    await client.connect(clientTransport);
    print('Connected to server');

    // Initialize the session
    final capabilities = await client.initialize(
      clientInfo: ClientInfo(name: 'Dart MCP Client', version: '0.1.0'),
      capabilities: ClientCapabilities(),
    );

    print('Initialized session with server:');
    print('  Server: ${client.serverInfo!.name} ${client.serverInfo!.version}');
    print('  Capabilities:');
    print('    Tools: ${capabilities.tools != null}');

    // Test the tools capability
    if (client.isCapabilitySupported('tools')) {
      print('\nFetching available tools...');

      // List tools
      final toolsResult = await client.sendRequest('tools/list');
      final tools = toolsResult['tools'] as List<dynamic>;

      print('Available tools:');
      for (final tool in tools) {
        print('  - ${tool['name']}: ${tool['description']}');
      }

      // Call the calculator tool
      print('\nTesting calculator tool:');

      final addResult = await client.sendRequest('tools/execute', {
        'name': 'calculator',
        'params': {
          'operation': 'add',
          'a': 5,
          'b': 3,
        },
      });

      print('5 + 3 = ${addResult['result']}');

      final multiplyResult = await client.sendRequest('tools/execute', {
        'name': 'calculator',
        'params': {
          'operation': 'multiply',
          'a': 4,
          'b': 7,
        },
      });

      print('4 * 7 = ${multiplyResult['result']}');
    }

    // Shutdown and exit
    print('\nShutting down...');
    await client.shutdown();
    await client.exit();

    print('Done');
  } catch (e) {
    print('Error: $e');
  } finally {
    // Make sure to close the client
    await client.close();

    // Close the transports
    await clientTransport.close();
    await serverTransport.close();
  }
}
