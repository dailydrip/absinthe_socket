import 'package:phoenix_wings/phoenix_wings.dart';

PhoenixSocket getPheonixSocket(
    String endpoint, PhoenixSocketOptions socketOptions) {
  return PhoenixSocket(
    endpoint,
    socketOptions: PhoenixSocketOptions(
      params: socketOptions.params?..addAll({"vsn": "2.0.0"}),
    ),
  );
}
