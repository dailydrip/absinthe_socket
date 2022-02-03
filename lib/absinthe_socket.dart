library absinthe_socket;

import 'package:phoenix_wings/phoenix_wings.dart';
import 'absinthe_socket_options.dart';

import 'get_socket_by_platform/get_socket_by_platform_abstract.dart'
    if (dart.library.io) 'get_socket_by_platform/get_socket_by_mobile.dart'
    if (dart.library.js) 'get_socket_by_platform/get_socket_by_web.dart';

/// An Absinthe Socket
class AbsintheSocket {
  String endpoint;
  AbsintheSocketOptions? socketOptions = AbsintheSocketOptions();
  PhoenixSocket? _phoenixSocket;
  PhoenixChannel? _absintheChannel;
  List<Notifier> _notifiers = [];
  List<Notifier> _queuedPushes = [];
  NotifierPushHandler? subscriptionHandler;
  NotifierPushHandler? unsubscriptionHandler;

  static _onError(Map? response) {
    print("onError");
    print(response?.toString());
  }

  static _onSubscriptionSucceed(Notifier? notifier) {
    return (Map response) {
      print("response");
      print(response.toString());
      notifier?.subscriptionId = response["subscriptionId"];
    };
  }

  _onUnsubscriptionSucceed(Notifier? notifier) {
    return (Map response) {
      print("unsubscription response");
      print(response.toString());
      notifier?.cancel();
      _notifiers.remove(notifier);
    };
  }

  static _onTimeout(Map? response) {
    print("onTimeout");
  }

  AbsintheSocket(this.endpoint, {this.socketOptions}) {
    if (socketOptions == null) socketOptions = AbsintheSocketOptions();
    subscriptionHandler = NotifierPushHandler(
      onError: _onError,
      onTimeout: _onTimeout,
      onSucceed: _onSubscriptionSucceed,
    );
    unsubscriptionHandler = NotifierPushHandler(
      onError: _onError,
      onTimeout: _onTimeout,
      onSucceed: _onUnsubscriptionSucceed,
    );
    _phoenixSocket = getPheonixSocket(endpoint, socketOptions!);
    _connect();
  }

  _connect() async {
    await _phoenixSocket?.connect();
    _phoenixSocket?.onMessage(_onMessage);
    _absintheChannel = _phoenixSocket?.channel("__absinthe__:control", {});
    _absintheChannel?.join()?.receive("ok", _sendQueuedPushes);
  }

  disconnect() {
    _phoenixSocket?.disconnect();
  }

  _sendQueuedPushes(_) {
    _queuedPushes.forEach((notifier) {
      _pushRequest(notifier);
    });
    _queuedPushes = [];
  }

  void cancel(Notifier notifier) {
    unsubscribe(notifier);
  }

  void unsubscribe(Notifier notifier) {
    _handlePush(
        _absintheChannel?.push(
            event: "unsubscribe",
            payload: {"subscriptionId": notifier.subscriptionId}),
        _createPushHandler(unsubscriptionHandler, notifier));
  }

  Notifier send(GqlRequest request) {
    Notifier notifier = Notifier(request: request);
    _notifiers.add(notifier);
    _pushRequest(notifier);
    return notifier;
  }

  _onMessage(PhoenixMessage message) {
    String? subscriptionId = message.topic;
    _notifiers
        .where((Notifier notifier) => notifier.subscriptionId == subscriptionId)
        .forEach(
            (Notifier notifier) => notifier.notify(message.payload?["result"]));
  }

  _pushRequest(Notifier notifier) {
    if (_absintheChannel == null) {
      _queuedPushes.add(notifier);
    } else {
      _handlePush(
          _absintheChannel?.push(
              event: "doc", payload: {"query": notifier.request.operation}),
          _createPushHandler(subscriptionHandler, notifier));
    }
  }

  _handlePush(PhoenixPush? push, PushHandler handler) {
    push
        ?.receive("ok", handler.onSucceed)
        .receive("error", handler.onError)
        .receive("timeout", handler.onTimeout);
  }

  PushHandler _createPushHandler(
      NotifierPushHandler? notifierPushHandler, Notifier notifier) {
    return _createEventHandler(notifier, notifierPushHandler);
  }

  _createEventHandler(
      Notifier notifier, NotifierPushHandler? notifierPushHandler) {
    return PushHandler(
      onError: notifierPushHandler?.onError ?? (data) {},
      onSucceed: (data) => notifierPushHandler?.onSucceed(notifier),
      onTimeout: notifierPushHandler?.onTimeout ?? (data) {},
    );
  }
}

class Notifier<Result> {
  GqlRequest request;
  List<Observer<Result>> observers = [];
  String? subscriptionId;

  Notifier({required this.request});

  void observe(Observer<Result> observer) {
    observers.add(observer);
  }

  void notify(Map result) {
    observers.forEach((Observer observer) => observer.onResult(result));
  }

  void cancel() {
    observers.forEach((Observer observer) => observer.onCancel());
  }
}

class Observer<Result> {
  Function onAbort;
  Function onCancel;
  Function onError;
  Function onStart;
  Function onResult;

  Observer({
    required this.onAbort,
    required this.onCancel,
    required this.onError,
    required this.onStart,
    required this.onResult,
  });
}

class GqlRequest {
  String? operation;

  GqlRequest({this.operation});
}

class NotifierPushHandler<Response> {
  Function(Map?) onError;
  Function(Notifier?) onSucceed;
  Function(Map?) onTimeout;

  NotifierPushHandler({
    required this.onError,
    required this.onSucceed,
    required this.onTimeout,
  });
}

class PushHandler<Response> {
  Function(Map?) onError;
  Function(Map?) onSucceed;
  Function(Map?) onTimeout;

  PushHandler({
    required this.onError,
    required this.onSucceed,
    required this.onTimeout,
  });
}
