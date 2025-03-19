# MCP Dart SDK

[![pub package](https://img.shields.io/pub/v/mcp_dart_sdk.svg)](https://pub.dev/packages/mcp_dart_sdk)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A Dart implementation of the [Model Context Protocol (MCP)](https://spec.modelcontextprotocol.io/) for seamless integration between LLM applications and external data sources/tools.

## Features

- Full implementation of the Model Context Protocol
- Multiple transport options (stdio, HTTP+SSE, WebSocket)
- Support for all core capabilities (resources, tools, prompts, logging)
- Type-safe API with Dart idioms
- Comprehensive documentation and examples
- Support for both Flutter and standalone Dart applications

## Installation

Add `mcp_dart_sdk` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  mcp_dart_sdk: ^0.1.0
```

Then run:

```bash
dart pub get
```

Or with Flutter:

```bash
flutter pub get
```

## Usage

### Client Example

```dart
import 'dart:io';
import 'package:mcp_dart_sdk/mcp_dart_sdk.dart';

Future<void> main() async {
  // Launch a server process (e.g., a Python MCP server)
  final process = await Process.start(
    'python3',
    ['-m', 'mcp.server.stdio'],
    mode: ProcessStartMode.normal,
  );
  
  // Create a client
  final client = McpClient();
  
  try {
    // Connect to the server using stdio transport
    await client.connect(StdioTransport(process));
    
    // Initialize the session
    final capabilities = await client.initialize(
      clientInfo: ClientInfo(name: 'Dart MCP Client', version: '1.0.0'),
      capabilities: ClientCapabilities(),
    );
    
    print('Connected to server: ${client.serverInfo?.name} ${client.serverInfo?.version}');
    
    // Check if the server supports tools
    if (client.isCapabilitySupported('tools')) {
      // List available tools
      final result = await client.sendRequest('tools/list');
      final tools = result['tools'] as List<dynamic>;
      
      print('Available tools:');
      for (final tool in tools) {
        print('- ${tool['name']}: ${tool['description']}');
      }
      
      // Call a tool
      if (tools.isNotEmpty) {
        final toolName = tools.first['name'];
        final toolResult = await client.sendRequest('tools/execute', {
          'name': toolName,
          'params': {},
        });
        
        print('Tool result: $toolResult');
      }
    }
    
    // Clean shutdown
    await client.shutdown();
    await client.exit();
  } catch (e) {
    print('Error: $e');
  } finally {
    await client.close();
    process.kill();
  }
}
```

### WebSocket Transport Example

```dart
import 'package:mcp_dart_sdk/mcp_dart_sdk.dart';

Future<void> main() async {
  final client = McpClient();
  
  try {
    // Connect to a WebSocket server
    final transport = WebSocketTransport(url: 'ws://localhost:8000/ws');
    await transport.connect();
    
    await client.connect(transport);
    await client.initialize(
      clientInfo: ClientInfo(name: 'Dart MCP Client', version: '1.0.0'),
      capabilities: ClientCapabilities(),
    );
    
    // Use the client...
    
    await client.shutdown();
    await client.exit();
  } catch (e) {
    print('Error: $e');
  } finally {
    await client.close();
  }
}
```

### HTTP+SSE Transport Example

```dart
import 'package:mcp_dart_sdk/mcp_dart_sdk.dart';

Future<void> main() async {
  final client = McpClient();
  
  try {
    // Connect using HTTP+SSE
    final transport = HttpSseTransport(
      sendUrl: 'http://localhost:8000/send',
      receiveUrl: 'http://localhost:8000/events',
    );
    await transport.connect();
    
    await client.connect(transport);
    await client.initialize(
      clientInfo: ClientInfo(name: 'Dart MCP Client', version: '1.0.0'),
      capabilities: ClientCapabilities(),
    );
    
    // Use the client...
    
    await client.shutdown();
    await client.exit();
  } catch (e) {
    print('Error: $e');
  } finally {
    await client.close();
  }
}
```

## Documentation

For more detailed documentation, see the [API reference](https://pub.dev/documentation/mcp_dart_sdk/latest/) and [examples](https://github.com/yourusername/mcp_dart_sdk/tree/main/example).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
