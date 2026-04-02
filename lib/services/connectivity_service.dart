import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityService {
  // একবার চেক করা
  static Future<List<ConnectivityResult>> checkConnection() async {
    return await Connectivity().checkConnectivity();
  }

  // লাইভ শুনতে থাকা
  static StreamSubscription<List<ConnectivityResult>> listenToChanges(
    void Function(List<ConnectivityResult>) onChanged,
  ) {
    return Connectivity().onConnectivityChanged.listen(onChanged);
  }
}
