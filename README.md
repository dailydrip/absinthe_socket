# absinthe_socket

A dart client for GraphQL subscriptions via [Absinthe](http://absinthe-graphql.org/) sockets

## Getting Started

Use the package:

```yaml
# pubspec.yaml
# ...
  absinthe_socket: ^0.0.1
# ...
```

Create a socket, connect it, add a subscription:

```dart
    _socket = AbsintheSocket("ws://10.0.2.2:4000/socket/websocket");
    Observer _categoryObserver = Observer(
        onAbort: _onAbort,
        onCancel: _onCancel,
        onError: _onError,
        onResult: _onResult,
        onStart: _onStart);

    Notifier notifier = _socket.send(GqlRequest(
        operation:
            "subscription CategoryAdded { categoryAdded { id, title } }"));
    notifier.observe(_categoryObserver);
    // I also track notifiers to cancel them when my flutter widget is disposed of
    _notifiers.add(notifier);
```

This is a shameless bad rip-off of part of the API of [@absinthe/socket](https://github.com/absinthe-graphql/absinthe-socket).
