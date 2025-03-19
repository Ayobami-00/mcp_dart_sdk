/// A Dart implementation of the Model Context Protocol (MCP) for seamless
/// integration between LLM applications and external data sources/tools.
library mcp_dart_sdk;

// Base protocol components
export 'src/base/json_rpc.dart';
export 'src/base/lifecycle.dart';
export 'src/base/session.dart';
export 'src/base/types.dart';

// Client implementation
export 'src/client/client.dart';
export 'src/client/session.dart';
export 'src/client/transport/stdio.dart';
// export 'src/client/transport/http_sse.dart';
export 'src/client/transport/websocket.dart';
// export 'src/client/capabilities/roots.dart';
// export 'src/client/capabilities/sampling.dart';

// Server implementation
// export 'src/server/server.dart';
// export 'src/server/session.dart';
// export 'src/server/transport/stdio.dart';
// export 'src/server/transport/http_sse.dart';
// export 'src/server/transport/websocket.dart';
// export 'src/server/capabilities/prompts.dart';
// export 'src/server/capabilities/resources.dart';
// export 'src/server/capabilities/tools.dart';
// export 'src/server/capabilities/logging.dart';

// Shared functionality
export 'src/shared/context.dart';
export 'src/shared/exceptions.dart';
export 'src/shared/utils.dart';
export 'src/shared/version.dart';

// Protocol utilities
// export 'src/utilities/ping.dart';
// export 'src/utilities/cancellation.dart';
// export 'src/utilities/progress.dart';
// export 'src/utilities/completion.dart';
// export 'src/utilities/pagination.dart';
