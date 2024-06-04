import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'routes/index.dart' as api;

// Middleware to handle CORS
Handler cors(Handler handler) {
  return (context) async {
    final response = await handler(context);
    return response.copyWith(
      headers: {
        ...response.headers,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    );
  };
}

Future<HttpServer> runServer() {
  final handler = Pipeline().addMiddleware(cors).addHandler(onRequest);
  return serve(handler, InternetAddress.anyIPv4, int.parse(Platform.environment['PORT'] ?? '8080'));
}

void main() async {
  final server = await runServer();
  print('Server running on port ${server.port}');
}
