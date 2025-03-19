import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:mcp_dart_sdk/src/base/session.dart';
import 'package:mcp_dart_sdk/src/base/types.dart';
import 'package:mcp_dart_sdk/src/client/client.dart';
import 'package:mcp_dart_sdk/src/client/capabilities/roots.dart';
import 'package:mcp_dart_sdk/src/client/capabilities/sampling.dart';
import 'package:mcp_dart_sdk/src/shared/exceptions.dart';

@GenerateMocks([Transport])
import 'capabilities_test.mocks.dart';

void main() {
  group('Client Capabilities', () {
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

    Future<void> setupInitializedClient({
      bool withRoots = false,
      bool withSampling = false,
    }) async {
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
                if (withRoots) 'roots': {'supported': true},
                if (withSampling) 'sampling': {'supported': true},
              }
            }
          }));
        }
      });

      await client.initialize(
        clientInfo: ClientInfo(name: 'Test Client', version: '1.0.0'),
        rootsCapability: withRoots ? RootsCapability() : null,
        samplingCapability: withSampling ? SamplingCapability() : null,
      );
    }

    group('Roots capability', () {
      test('supportsRoots - should check if the roots capability is supported',
          () async {
        await setupInitializedClient(withRoots: true);

        expect(client.supportsRoots, isTrue);
      });

      test(
          'supportsRoots - should return false if roots capability is not supported',
          () async {
        await setupInitializedClient(withRoots: false);

        expect(client.supportsRoots, isFalse);
      });

      test('listRoots - should list the available roots', () async {
        await setupInitializedClient(withRoots: true);

        // Setup response for roots/list
        when(mockTransport.send(any)).thenAnswer((invocation) async {
          final message = invocation.positionalArguments[0] as String;
          final request = json.decode(message) as Map<String, dynamic>;

          if (request['method'] == 'roots/list') {
            incomingController.add(json.encode({
              'jsonrpc': '2.0',
              'id': request['id'],
              'result': {
                'roots': ['root1', 'root2', 'root3']
              }
            }));
          }
        });

        final roots = await client.listRoots();

        expect(roots, hasLength(3));
        expect(roots, contains('root1'));
        expect(roots, contains('root2'));
        expect(roots, contains('root3'));
      });

      test(
          'listRoots - should throw CapabilityNotSupportedException if roots capability is not supported',
          () async {
        await setupInitializedClient(withRoots: false);

        expect(() => client.listRoots(),
            throwsA(isA<CapabilityNotSupportedException>()));
      });
    });

    group('Sampling capability', () {
      test(
          'supportsSampling - should check if the sampling capability is supported',
          () async {
        await setupInitializedClient(withSampling: true);

        expect(client.supportsSampling, isTrue);
      });

      test(
          'supportsSampling - should return false if sampling capability is not supported',
          () async {
        await setupInitializedClient(withSampling: false);

        expect(client.supportsSampling, isFalse);
      });

      test('startSampling - should start a sampling session', () async {
        await setupInitializedClient(withSampling: true);

        // Setup response for sampling/start
        when(mockTransport.send(any)).thenAnswer((invocation) async {
          final message = invocation.positionalArguments[0] as String;
          final request = json.decode(message) as Map<String, dynamic>;

          if (request['method'] == 'sampling/start') {
            expect(request['params']['promptRequestId'], equals('prompt-123'));

            incomingController.add(json.encode({
              'jsonrpc': '2.0',
              'id': request['id'],
              'result': {'id': 'sampling-456'}
            }));
          }
        });

        final id = await client.startSampling(
          promptRequestId: 'prompt-123',
          interval: 100,
        );

        expect(id, equals('sampling-456'));
      });

      test(
          'startSampling - should throw CapabilityNotSupportedException if sampling capability is not supported',
          () async {
        await setupInitializedClient(withSampling: false);

        expect(
          () => client.startSampling(promptRequestId: 'prompt-123'),
          throwsA(isA<CapabilityNotSupportedException>()),
        );
      });

      test('stopSampling - should stop a sampling session', () async {
        await setupInitializedClient(withSampling: true);

        // Setup response for sampling/stop
        when(mockTransport.send(any)).thenAnswer((invocation) async {
          final message = invocation.positionalArguments[0] as String;
          final request = json.decode(message) as Map<String, dynamic>;

          if (request['method'] == 'sampling/stop') {
            expect(request['params']['id'], equals('sampling-456'));

            incomingController.add(json
                .encode({'jsonrpc': '2.0', 'id': request['id'], 'result': {}}));
          }
        });

        // Shouldn't throw
        await client.stopSampling('sampling-456');
      });
    });
  });
}
