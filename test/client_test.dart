import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:mcp_dart_sdk/src/base/session.dart';
import 'package:mcp_dart_sdk/src/base/types.dart';
import 'package:mcp_dart_sdk/src/client/client.dart';

@GenerateMocks([Transport])
import 'client_test.mocks.dart';

void main() {
  group('McpClient', () {
    late MockTransport mockTransport;
    late McpClient client;
    late StreamController<String> incomingController;

    setUp(() {
      incomingController = StreamController<String>();
      mockTransport = MockTransport();
      when(mockTransport.incoming).thenAnswer((_) => incomingController.stream);
      when(mockTransport.send(any)).thenAnswer((_) async {});
      when(mockTransport.close()).thenAnswer((_) async {});

      client = McpClient();
    });

    tearDown(() async {
      await incomingController.close();
    });

    test('connect - should create a new session', () async {
      expect(client.isConnected, isFalse);

      await client.connect(mockTransport);

      expect(client.isConnected, isTrue);
      expect(client.isInitialized, isFalse);
    });

    test('initialize - should initialize the session', () async {
      await client.connect(mockTransport);

      // Setup a response for the initialize request
      when(mockTransport.send(any)).thenAnswer((invocation) async {
        final message = invocation.positionalArguments[0] as String;
        final request = json.decode(message) as Map<String, dynamic>;

        expect(request['method'], equals('initialize'));
        expect(request['params']['clientInfo']['name'], equals('Test Client'));

        // Send a response back
        incomingController.add(json.encode({
          'jsonrpc': '2.0',
          'id': request['id'],
          'result': {
            'serverInfo': {'name': 'Test Server', 'version': '1.0.0'},
            'capabilities': {
              'resources': {'content': true},
              'tools': {'execute': true}
            }
          }
        }));
      });

      final capabilities = await client.initialize(
        clientInfo: ClientInfo(name: 'Test Client', version: '1.0.0'),
        capabilities: ClientCapabilities(),
      );

      expect(client.isInitialized, isTrue);
      expect(client.serverInfo?.name, equals('Test Server'));
      expect(client.serverInfo?.version, equals('1.0.0'));
      expect(capabilities.resources, isNotNull);
      expect(capabilities.tools, isNotNull);
    });

    test('isCapabilitySupported - should check if a capability is supported',
        () async {
      await client.connect(mockTransport);

      // Setup a response for the initialize request
      when(mockTransport.send(any)).thenAnswer((invocation) async {
        final message = invocation.positionalArguments[0] as String;
        final request = json.decode(message) as Map<String, dynamic>;

        if (request['method'] == 'initialize') {
          // Send a response back
          incomingController.add(json.encode({
            'jsonrpc': '2.0',
            'id': request['id'],
            'result': {
              'serverInfo': {'name': 'Test Server', 'version': '1.0.0'},
              'capabilities': {
                'resources': {'content': true}
              }
            }
          }));
        }
      });

      await client.initialize(
        clientInfo: ClientInfo(name: 'Test Client', version: '1.0.0'),
        capabilities: ClientCapabilities(),
      );

      expect(client.isCapabilitySupported('resources'), isTrue);
      expect(client.isCapabilitySupported('tools'), isFalse);
      expect(client.isCapabilitySupported('prompts'), isFalse);
    });

    test('shutdown and exit - should close the session', () async {
      await client.connect(mockTransport);

      // Setup responses for the initialize and shutdown requests
      when(mockTransport.send(any)).thenAnswer((invocation) async {
        final message = invocation.positionalArguments[0] as String;
        final jsonMsg = json.decode(message) as Map<String, dynamic>;

        if (jsonMsg['method'] == 'initialize') {
          incomingController.add(json.encode({
            'jsonrpc': '2.0',
            'id': jsonMsg['id'],
            'result': {
              'serverInfo': {'name': 'Test Server', 'version': '1.0.0'},
              'capabilities': {}
            }
          }));
        } else if (jsonMsg['method'] == 'shutdown') {
          incomingController.add(json
              .encode({'jsonrpc': '2.0', 'id': jsonMsg['id'], 'result': {}}));
        }
      });

      await client.initialize(
        clientInfo: ClientInfo(name: 'Test Client', version: '1.0.0'),
        capabilities: ClientCapabilities(),
      );

      expect(client.isInitialized, isTrue);

      await client.shutdown();
      await client.exit();

      expect(client.isConnected, isFalse);

      // Verify that exit notification was sent
      verify(mockTransport.send(argThat(contains('"method":"exit"'))))
          .called(1);
      verify(mockTransport.close()).called(1);
    });

    test('sendRequest - should send a custom request', () async {
      await client.connect(mockTransport);

      // Setup responses for initialize and custom request
      when(mockTransport.send(any)).thenAnswer((invocation) async {
        final message = invocation.positionalArguments[0] as String;
        final jsonMsg = json.decode(message) as Map<String, dynamic>;

        if (jsonMsg['method'] == 'initialize') {
          incomingController.add(json.encode({
            'jsonrpc': '2.0',
            'id': jsonMsg['id'],
            'result': {
              'serverInfo': {'name': 'Test Server', 'version': '1.0.0'},
              'capabilities': {}
            }
          }));
        } else if (jsonMsg['method'] == 'customMethod') {
          expect(jsonMsg['params']['key'], equals('value'));

          incomingController.add(json.encode({
            'jsonrpc': '2.0',
            'id': jsonMsg['id'],
            'result': {'response': 'success'}
          }));
        }
      });

      await client.initialize(
        clientInfo: ClientInfo(name: 'Test Client', version: '1.0.0'),
        capabilities: ClientCapabilities(),
      );

      final result = await client.sendRequest('customMethod', {'key': 'value'});

      expect(result['response'], equals('success'));
    });

    test('sendNotification - should send a custom notification', () async {
      await client.connect(mockTransport);

      // Setup response for initialize
      when(mockTransport.send(any)).thenAnswer((invocation) async {
        final message = invocation.positionalArguments[0] as String;
        final jsonMsg = json.decode(message) as Map<String, dynamic>;

        if (jsonMsg['method'] == 'initialize') {
          incomingController.add(json.encode({
            'jsonrpc': '2.0',
            'id': jsonMsg['id'],
            'result': {
              'serverInfo': {'name': 'Test Server', 'version': '1.0.0'},
              'capabilities': {}
            }
          }));
        }
      });

      await client.initialize(
        clientInfo: ClientInfo(name: 'Test Client', version: '1.0.0'),
        capabilities: ClientCapabilities(),
      );

      await client.sendNotification('customNotification', {'key': 'value'});

      // Verify that the notification was sent with a more specific matcher
      verify(mockTransport.send(argThat(predicate<String>((message) {
        final jsonMsg = json.decode(message) as Map<String, dynamic>;
        return jsonMsg['method'] == 'customNotification' &&
            jsonMsg['params'] != null &&
            jsonMsg['params']['key'] == 'value';
      }, 'notification with method "customNotification" and key "value"'))))
          .called(1);
    });
  });
}
