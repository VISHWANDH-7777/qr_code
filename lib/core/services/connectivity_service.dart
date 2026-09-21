import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum InternetStatus { checking, connected, disconnected }

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final internetStatusProvider = StateNotifierProvider<InternetStatusNotifier, InternetStatus>((ref) {
  return InternetStatusNotifier(ref.watch(connectivityServiceProvider));
});

class InternetStatusNotifier extends StateNotifier<InternetStatus> {
  final ConnectivityService _service;
  late StreamSubscription<InternetStatus> _subscription;

  InternetStatusNotifier(this._service) : super(InternetStatus.checking) {
    _subscription = _service.internetStatusStream.listen((status) {
      state = status;
    });
    _service.checkInternet();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> retry() async {
    state = InternetStatus.checking;
    await _service.checkInternet();
  }
}

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _statusController = StreamController<InternetStatus>.broadcast();

  ConnectivityService() {
    _monitorInternet();
  }

  Stream<InternetStatus> get internetStatusStream => _statusController.stream;

  Future<void> checkInternet() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _statusController.add(InternetStatus.disconnected);
      return;
    }

    final hasActualInternet = await _hasActualInternetAccess();
    if (hasActualInternet) {
      _statusController.add(InternetStatus.connected);
    } else {
      _statusController.add(InternetStatus.disconnected);
    }
  }

  void _monitorInternet() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      if (results.contains(ConnectivityResult.none)) {
        _statusController.add(InternetStatus.disconnected);
        return;
      }

      final hasActualInternet = await _hasActualInternetAccess();
      if (hasActualInternet) {
        _statusController.add(InternetStatus.connected);
      } else {
        _statusController.add(InternetStatus.disconnected);
      }
    });
  }

  Future<bool> _hasActualInternetAccess() async {
    Future<bool> check() async {
      try {
        final result = await InternetAddress.lookup('google.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      }
    }

    if (await check()) return true;
    
    // Brief network hiccup retry
    await Future.delayed(const Duration(seconds: 1));
    return await check();
  }
}
