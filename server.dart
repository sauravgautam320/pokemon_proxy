import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'routes/index.dart' as api;

// Middleware to handle CORS
Handler corsMiddleware(Handler handler) {
  return (context) async {
    if (context.request.method == 'OPTIONS') {
      return Response(statusCode: HttpStatus.noContent, headers: _corsHeaders);
    }
    final response = await handler(context);
    return response.copyWith(
      headers: {
        ...response.headers,
        ..._corsHeaders,
      },
    );
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

Future<HttpServer> runServer() {
  final handler = corsMiddleware(api.onRequest);
  return serve(
    handler,
    InternetAddress.anyIPv4,
    int.parse(Platform.environment['PORT'] ?? '8080'),
  );
}

void main() async {
  final server = await runServer();
  print('Server running on port ${server.port}');
}
