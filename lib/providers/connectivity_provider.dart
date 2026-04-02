import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';                                      // ← এই লাইনটা যোগ করা হয়েছে
import '../services/connectivity_service.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityProvider() {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    // প্রথমবার চেক
    final result = await ConnectivityService.checkConnection();
    _updateStatus(result);

    // লাইভ লিসেনার
    _subscription = ConnectivityService.listenToChanges((result) {
      _updateStatus(result);
    });
  }

  void _updateStatus(List<ConnectivityResult> result) {
    final connected = !result.contains(ConnectivityResult.none);
    if (connected != _isConnected) {
      _isConnected = connected;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
