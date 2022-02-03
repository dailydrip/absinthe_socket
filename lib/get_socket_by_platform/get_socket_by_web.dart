import 'package:absinthe_socket/absinthe_socket_options.dart';
import 'package:phoenix_wings/html.dart';

PhoenixSocket getPheonixSocket(
    String endpoint, AbsintheSocketOptions socketOptions) {
  return PhoenixSocket(
    endpoint,
    connectionProvider: PhoenixHtmlConnection.provider,
    socketOptions: PhoenixSocketOptions(
      params: socketOptions.params?..addAll({"vsn": "2.0.0"}),
    ),
  );
}
