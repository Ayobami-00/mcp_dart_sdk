/// HTTP with Server-Sent Events transport for MCP client.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../../../src/base/session.dart';
import '../../../src/shared/exceptions.dart';

/// A transport implementation that uses HTTP for sending messages
/// and Server-Sent Events (SSE) for receiving messages.
class HttpSseTransport implements Transport {
  final Logger _logger = Logger('HttpSseTransport');
  final String _sendUrl;
  final String _receiveUrl;
  final http.Client _httpClient;
  final Map<String, String> _headers;

  final StreamController<String> _incomingController =
      StreamController<String>();
  StreamSubscription<dynamic>? _eventSourceSubscription;
  EventSource? _eventSource;

  /// Creates a new [HttpSseTransport] instance.
  HttpSseTransport({
    required String sendUrl,
    required String receiveUrl,
    http.Client? httpClient,
    Map<String, String>? headers,
  })  : _sendUrl = sendUrl,
        _receiveUrl = receiveUrl,
        _httpClient = httpClient ?? http.Client(),
        _headers = headers ?? {};

  @override
  Stream<String> get incoming => _incomingController.stream;

  /// Connects to the SSE endpoint.
  Future<void> connect() async {
    try {
      _eventSource = EventSource(
        uri: Uri.parse(_receiveUrl),
        httpClient: _httpClient,
        headers: _headers,
      );

      _eventSourceSubscription = _eventSource!.events.listen(
        _handleSseEvent,
        onError: _handleSseError,
        cancelOnError: false,
      );

      _logger.info('Connected to SSE endpoint: $_receiveUrl');
    } catch (e) {
      _logger.severe('Failed to connect to SSE endpoint: $e');
      throw TransportException('Failed to connect to SSE endpoint: $e');
    }
  }

  @override
  Future<void> send(String message) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(_sendUrl),
        headers: {
          'Content-Type': 'application/json',
          ..._headers,
        },
        body: message,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw TransportException(
          'HTTP error: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      _logger.severe('Failed to send message: $e');
      throw TransportException('Failed to send message: $e');
    }
  }

  @override
  Future<void> close() async {
    await _eventSourceSubscription?.cancel();
    _eventSource?.close();
    await _incomingController.close();
    _httpClient.close();
  }

  /// Handles an SSE event.
  void _handleSseEvent(Event event) {
    if (event.data != null && event.data!.isNotEmpty) {
      _incomingController.add(event.data!);
    }
  }

  /// Handles an SSE error.
  void _handleSseError(Object error) {
    _logger.warning('SSE error: $error');
    _incomingController.addError(error);
  }
}

/// A simple implementation of Server-Sent Events (SSE) client.
class EventSource {
  final Logger _logger = Logger('EventSource');
  final Uri uri;
  final http.Client httpClient;
  final Map<String, String> headers;

  http.StreamedResponse? _response;
  StreamSubscription<List<int>>? _subscription;
  final StreamController<Event> _controller =
      StreamController<Event>.broadcast();

  String _buffer = '';
  bool _closed = false;

  /// Creates a new [EventSource] instance.
  EventSource({
    required this.uri,
    required this.httpClient,
    this.headers = const {},
  }) {
    _connect();
  }

  /// Stream of SSE events.
  Stream<Event> get events => _controller.stream;

  /// Connects to the SSE endpoint.
  Future<void> _connect() async {
    if (_closed) return;

    try {
      final request = http.Request('GET', uri);
      request.headers.addAll({
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        ...headers,
      });

      _response = await httpClient.send(request);

      if (_response!.statusCode != 200) {
        throw Exception(
          'Failed to connect to SSE endpoint: ${_response!.statusCode}',
        );
      }

      _subscription = _response!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      _logger.severe('Failed to connect to SSE endpoint: $e');
      _controller.addError(e);
      _scheduleReconnect();
    }
  }

  /// Closes the connection.
  void close() {
    _closed = true;
    _subscription?.cancel();
    _controller.close();
  }

  /// Handles incoming data.
  void _onData(List<int> data) {
    if (_closed) return;

    _buffer += utf8.decode(data);

    final events = _parseEvents();
    for (final event in events) {
      _controller.add(event);
    }
  }

  /// Handles an error.
  void _onError(Object error) {
    _logger.warning('SSE error: $error');
    _controller.addError(error);
    _scheduleReconnect();
  }

  /// Handles the end of the stream.
  void _onDone() {
    _logger.info('SSE connection closed');
    _scheduleReconnect();
  }

  /// Schedules a reconnection attempt.
  void _scheduleReconnect() {
    if (_closed) return;

    _subscription?.cancel();
    _subscription = null;

    // Wait a second before reconnecting
    Future.delayed(Duration(seconds: 1), _connect);
  }

  /// Parses SSE events from the buffer.
  List<Event> _parseEvents() {
    final events = <Event>[];

    // Split the buffer into lines
    final lines = _buffer.split('\n');

    // If the buffer doesn't end with a newline, keep the last line in the buffer
    if (!_buffer.endsWith('\n')) {
      _buffer = lines.removeLast();
    } else {
      _buffer = '';
    }

    Event currentEvent = Event();

    for (String line in lines) {
      // Remove trailing \r if present
      if (line.endsWith('\r')) {
        line = line.substring(0, line.length - 1);
      }

      // Empty line indicates the end of an event
      if (line.isEmpty) {
        if (currentEvent.data != null) {
          events.add(currentEvent);
          currentEvent = Event();
        }
        continue;
      }

      // Parse the field
      if (line.startsWith('data:')) {
        final value = line.substring(5).trimLeft();
        if (currentEvent.data == null) {
          currentEvent.data = value;
        } else {
          currentEvent.data = '${currentEvent.data}\n$value';
        }
      } else if (line.startsWith('event:')) {
        currentEvent.event = line.substring(6).trim();
      } else if (line.startsWith('id:')) {
        currentEvent.id = line.substring(3).trim();
      } else if (line.startsWith('retry:')) {
        final retryStr = line.substring(6).trim();
        try {
          currentEvent.retry = int.parse(retryStr);
        } catch (e) {
          _logger.warning('Invalid retry value: $retryStr');
        }
      }
    }

    return events;
  }
}

/// Represents a Server-Sent Events (SSE) event.
class Event {
  /// The event name.
  String? event;

  /// The event data.
  String? data;

  /// The event ID.
  String? id;

  /// The retry timeout in milliseconds.
  int? retry;
}
