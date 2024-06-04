import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'routes/index.dart' as api;

Response _handleCors(RequestContext context, Response response) {
  return response.copyWith(
    headers: {
      ...response.headers,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  );
}

Handler middleware(Handler handler) {
  return handler.use(requestLogger()).use(cors(_handleCors));
}

Future<HttpServer> runServer() {
  final handler = middleware(onRequest);
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
