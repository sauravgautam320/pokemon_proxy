import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'routes/index.dart' as api;

Future<HttpServer> runServer() {
  final handler = api.onRequest;
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
