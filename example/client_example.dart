import 'dart:io';

import 'package:mcp_dart_sdk/mcp_dart_sdk.dart';

/// This example demonstrates how to use the MCP client with a Python MCP server.
///
/// NOTE: This requires the Python MCP server implementation to be installed:
/// You can install it using:
///   pip install mcp
///
/// If you don't have the Python MCP server installed, you will see a
/// "ModuleNotFoundError: No module named 'mcp'" error when running this example.
Future<void> main() async {
  print('Starting MCP client example...');
  print('Trying to launch Python MCP server...');
  print(
      '(If this fails, make sure you have the Python MCP package installed with "pip install mcp")');

  // Try to launch a server process
  Process? process;
  try {
    process = await Process.start(
      'python3',
      ['-m', 'mcp.server.stdio'],
      mode: ProcessStartMode.normal,
    );

    print('Server process started successfully.');
  } catch (e) {
    print('Failed to start server process: $e');
    print('\nAlternatives:');
    print('1. Install the Python MCP server: pip install mcp');
    print(
        '2. Run a standalone MCP server and update this example to connect to it');
    return;
  }

  // Create a client
  final client = McpClient();

  try {
    // Connect to the server
    await client.connect(StdioTransport(process));

    print('Connected to server');

    // Initialize the session
    final capabilities = await client.initialize(
      clientInfo: ClientInfo(name: 'Dart MCP Client', version: '0.1.0'),
      capabilities: ClientCapabilities(),
    );

    print('Initialized session with server:');
    print('  Server: ${client.serverInfo!.name} ${client.serverInfo!.version}');
    print('  Capabilities:');
    print('    Resources: ${capabilities.resources != null}');
    print('    Tools: ${capabilities.tools != null}');
    print('    Prompts: ${capabilities.prompts != null}');
    print('    Logging: ${capabilities.logging != null}');

    // Check for tools capability
    if (client.isCapabilitySupported('tools')) {
      print('\nFetching available tools...');

      // List tools
      final toolsResult = await client.sendRequest('tools/list');
      final tools = toolsResult['tools'] as List<dynamic>;

      print('Available tools:');
      for (final tool in tools) {
        print('  - ${tool['name']}: ${tool['description']}');
      }

      // Call a tool if available
      if (tools.isNotEmpty) {
        final toolName = tools.first['name'];
        print('\nCalling tool: $toolName');

        final toolResult = await client.sendRequest('tools/execute', {
          'name': toolName,
          'params': {},
        });

        print('Tool result: $toolResult');
      }
    }

    // Shutdown and exit
    print('\nShutting down...');
    await client.shutdown();
    await client.exit();

    print('Done');
  } catch (e) {
    print('Error during client execution: $e');
  } finally {
    // Make sure to close the client
    await client.close();

    // Terminate the process if it's still running
    if (process != null) {
      try {
        process.kill();
        print('Server process terminated.');
      } catch (e) {
        print('Failed to terminate server process: $e');
      }
    }
  }
}
