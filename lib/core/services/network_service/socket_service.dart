import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/config/constants/app_constants.dart';
import 'package:orange_taxi_customer_app/core/services/network_service/connectivity_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();
  IO.Socket? socket;

  int _instanceSeq = 0;
  String? _token;
  int _attemptSeq = 0;
  int? _lastFailedAttempt;
  final Map<String, List<Function(dynamic)>> _handlers = {};

  bool get isConnected => socket?.connected == true;
  bool get hasInstance => socket != null;

  String get _tag => '[socket#$_instanceSeq]';

  int listenerCount(String event) => _handlers[event]?.length ?? 0;

  String get diagnostics =>
      '$_tag instance=${socket != null} connected=$isConnected id=${socket?.id} '
      'listeners={${_handlers.entries.map((e) => '${e.key}:${e.value.length}').join(', ')}}';

  void connect(String token) {
    if (socket != null) {
      if (_token != token) {
        print('$_tag connect() auth token changed -> rebuilding instance');
        _disposeInstance();
      } else {
        if (isConnected) {
          print('$_tag connect() ignored, already connected id=${socket?.id}');
        } else {
          print('$_tag connect() reusing instance, not connected -> connect()');
          _attemptSeq++;
          socket?.connect();
        }
        return;
      }
    }

    _token = token;
    _instanceSeq++;
    print('$_tag creating instance url=${AppConstants.baseUrl}/customer hasToken=${token.isNotEmpty}');

    socket = IO.io(
      '${AppConstants.baseUrl}/customer',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': 'Bearer $token'})
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    _attachDiagnosticHandlers();
    _replayHandlers();

    _attemptSeq++;
    socket?.connect();
  }

  void _handleUpgradeFailure(dynamic data) {
    if (!data.toString().contains('was not upgraded to websocket')) return;
    if (_lastFailedAttempt == _attemptSeq) return;
    _lastFailedAttempt = _attemptSeq;
    if (Get.isRegistered<ConnectivityService>()) {
      Get.find<ConnectivityService>().reportSocketUpgradeFailure();
    }
  }

  void _handleSocketUp() {
    _lastFailedAttempt = null;
    if (Get.isRegistered<ConnectivityService>()) {
      Get.find<ConnectivityService>().reportServerUp();
    }
  }

  void _attachDiagnosticHandlers() {
    socket?.onConnect((_) {
      print('✅ $_tag CONNECTED id=${socket?.id}');
      print('$_tag $diagnostics');
      _handleSocketUp();
    });

    socket?.onDisconnect((reason) {
      print('❌ $_tag DISCONNECTED reason=$reason');
    });

    socket?.onReconnect((data) {
      print('🔄 $_tag RECONNECTED => $data');
      print('$_tag $diagnostics');
      _handleSocketUp();
    });

    socket?.onReconnectAttempt((data) {
      print('🔄 $_tag RECONNECT ATTEMPT => $data');
      _attemptSeq++;
    });

    socket?.onReconnectError((data) {
      print('🚨 $_tag RECONNECT ERROR => $data');
      _handleUpgradeFailure(data);
    });

    socket?.onReconnectFailed((data) {
      print('🚨 $_tag RECONNECT FAILED (giving up) => $data');
    });

    socket?.onConnectError((data) {
      print('🚨 $_tag CONNECT ERROR => $data');
      _handleUpgradeFailure(data);
    });

    socket?.onError((data) {
      print('🚨 $_tag SOCKET ERROR => $data');
      _handleUpgradeFailure(data);
    });

    socket?.onAny((event, data) {
      print('$_tag EVENT => $event (listeners=${listenerCount(event)})');
      print('DATA => $data');
    });
  }

  void _replayHandlers() {
    if (_handlers.isEmpty) return;
    int replayed = 0;
    _handlers.forEach((event, callbacks) {
      for (final cb in callbacks) {
        socket?.on(event, cb);
        replayed++;
      }
    });
    print('$_tag replayed $replayed listener(s) onto the new instance');
  }

  void on(String event, Function(dynamic) callback) {
    final list = _handlers.putIfAbsent(event, () => <Function(dynamic)>[]);
    if (list.contains(callback)) {
      return;
    }
    list.add(callback);
    socket?.on(event, callback);
  }

  void off(String event, [Function(dynamic)? callback]) {
    final int before = listenerCount(event);
    if (callback == null) {
      _handlers.remove(event);
      print('$_tag off("$event") removed ALL listeners (was $before)');
    } else {
      _handlers[event]?.remove(callback);
      if (_handlers[event]?.isEmpty ?? false) _handlers.remove(event);
      print('$_tag off("$event") removed 1 listener (was $before, now ${listenerCount(event)})');
    }
    socket?.off(event, callback);
  }

  void emit(String event, [dynamic data]) {
    socket?.emit(event, data);
  }

  void _disposeInstance() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
  }

  void disconnect() {
    print('$_tag disconnect() disposing instance, keeping ${_handlers.length} event(s) for replay. $diagnostics');
    _disposeInstance();
    _token = null;
  }
}
