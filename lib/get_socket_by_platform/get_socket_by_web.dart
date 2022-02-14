import 'package:phoenix_wings/html.dart';

PhoenixSocket getPheonixSocket(
    String endpoint, PhoenixSocketOptions socketOptions) {
  return PhoenixSocket(
    endpoint,
    connectionProvider: PhoenixHtmlConnection.provider,
    socketOptions: PhoenixSocketOptions(
      params: socketOptions.params?..addAll({"vsn": "2.0.0"}),
    ),
  );
}
