import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../constants/mining_constants.dart';
import '../services/mining_service.dart';

class MiningController {
  final BuildContext context;
  final void Function(void Function()) setState;

  MiningController({required this.context, required this.setState});

  // ─── State ───────────────────────────────────────────────────────────────
  bool autoMining      = false;
  bool isLoading       = true;
  bool hasError        = false;
  bool miningActive    = false;
  double minedCoins      = 0.0;
  double equivalentUSD   = 0.0;
  double withdrawableUSD = 0.0;

  double boostMultiplier = 1.0;
  double aiMultiplier    = 1.0;
  bool   boostActive     = false;
  double boostAmount     = 0.0;

  double usdPerSec  = kBaseUsdPerSec;
  double solPerSec  = 0.0;
  double solPrice   = 150.0;
  double minedSOL   = 0.0;

  bool   dayStarted = false;
  bool   isMining   = false;

  double    liveUSD       = 0.0;
  double    liveSOL       = 0.0;
  double    cycleProgress = 0.0;
  double    baseUsdAtSync = 0.0;
  double    baseSolAtSync = 0.0;
  DateTime? lastSyncTime;

  Timer? liveTimer;
  Timer? syncTimer;

  // ─── Helpers ─────────────────────────────────────────────────────────────
  String? _getToken() =>
      Provider.of<AuthProvider>(context, listen: false).token;

  double _toDouble(dynamic v) =>
      double.tryParse(v?.toString() ?? '0') ?? 0.0;

  String formatSol(double v) {
    if (v >= 0.001)    return v.toStringAsFixed(6);
    if (v >= 0.000001) return v.toStringAsFixed(8);
    return v.toStringAsFixed(10);
  }

  // ─── Apply status from server ─────────────────────────────────────────────
  void applyStatus(Map<String, dynamic> data) {
    miningActive    = data['miningActive'] == true;
    autoMining      = data['autoMining'] == true;
    minedCoins      = _toDouble(data['minedCoins']);
    equivalentUSD   = _toDouble(data['equivalentUSD']);
    withdrawableUSD = _toDouble(data['withdrawableUSD']);

    boostMultiplier = _toDouble(data['boostMultiplier'] ?? 1.0);
    aiMultiplier    = _toDouble(data['aiMultiplier']    ?? 1.0);
    boostActive     = boostMultiplier > 1.0;
    boostAmount     = _toDouble(data['boostUSD']        ?? 0.0);

    usdPerSec = _toDouble(data['usdPerSec']    ?? kBaseUsdPerSec);
    solPerSec = _toDouble(data['solPerSec']    ?? 0.0);
    solPrice  = _toDouble(data['solPriceUSD']  ?? 150.0);
    minedSOL  = _toDouble(data['minedSOL']     ?? 0.0);

    baseUsdAtSync = equivalentUSD;
    baseSolAtSync = minedSOL;
    lastSyncTime  = DateTime.now();
    liveUSD       = equivalentUSD;
    liveSOL       = minedSOL;
    cycleProgress = (equivalentUSD / kUsdTarget).clamp(0.0, 1.0);

    if (miningActive) {
      // Server বলছে mining চলছে
      dayStarted = true;
      isMining   = true;
      startLiveTimer();
      startAutoSync();
    } else {
      // Mining active না, timer বন্ধ করো
      isMining = false;
      liveTimer?.cancel();
      // FIXED: equivalentUSD > 0 থাকলে claim করা যাবে
      dayStarted = equivalentUSD > 0;
    }
  }

  // ─── Purchase Logic ───────────────────────────────────────────────────────
  Future<bool> purchaseBoost(double amount) async {
    final token = _getToken();
    if (token == null) return false;
    try {
      await MiningService(token: token).buyBoost(amount);
      await fetchStatus();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> purchaseAutoMining() async {
    final token = _getToken();
    if (token == null) return false;
    try {
      await MiningService(token: token).buyAutoMining();
      await fetchStatus();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // ─── API Methods ──────────────────────────────────────────────────────────
  Future<void> fetchStatus() async {
    setState(() { isLoading = true; hasError = false; });
    try {
      final token = _getToken();
      if (token == null) {
        setState(() { isLoading = false; hasError = true; });
        return;
      }
      final data = await MiningService(token: token).fetchStatus();
      setState(() {
        applyStatus(data);
        isLoading = false;
      });
    } catch (_) {
      setState(() { isLoading = false; hasError = true; });
    }
  }

  Future<void> startDay() async {
    final token = _getToken();
    if (token == null) return;
    setState(() => isLoading = true);
    try {
      await MiningService(token: token).startDay();
      setState(() {
        isLoading     = false;
        dayStarted    = true;
        isMining      = true;
        baseUsdAtSync = equivalentUSD;
        baseSolAtSync = liveSOL;
        lastSyncTime  = DateTime.now();
      });
      startLiveTimer();
      startAutoSync();
    } catch (e) {
      setState(() => isLoading = false);
      rethrow;
    }
  }

  // ─── FIXED: doClaim ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> doClaim() async {
    final token = _getToken();
    if (token == null) throw Exception('No token');

    // Timer বন্ধ করো claim করার আগে
    liveTimer?.cancel();
    syncTimer?.cancel();

    setState(() => isLoading = true);

    try {
      // ✅ Real API call — MiningService এর claim() কে call করছে
      final data = await MiningService(token: token).claim();

      // ✅ Server response দিয়ে state update করো
      setState(() {
        isLoading    = false;
        dayStarted   = false;
        isMining     = false;
        miningActive = false;
        lastSyncTime = null;

        // Server থেকে withdrawable নাও — যেকোনো key হতে পারে
        if (data['withdrawable'] != null) {
          withdrawableUSD = _toDouble(data['withdrawable']);
        } else if (data['withdrawableUSD'] != null) {
          withdrawableUSD = _toDouble(data['withdrawableUSD']);
        }

        // Server থেকে earned amount
        if (data['equivalentUSD'] != null) {
          equivalentUSD = _toDouble(data['equivalentUSD']);
        }

        // সব live counter reset
        liveUSD       = 0.0;
        liveSOL       = 0.0;
        cycleProgress = 0.0;
        baseUsdAtSync = 0.0;
        baseSolAtSync = 0.0;
        minedCoins    = 0.0;
        minedSOL      = 0.0;
      });

      return data;
    } catch (e) {
      setState(() => isLoading = false);
      // Error হলে আগের অবস্থায় ফিরে যাও
      if (dayStarted && isMining) {
        startLiveTimer();
        startAutoSync();
      }
      rethrow;
    }
  }

  Future<void> toggleMining() async {
    if (!dayStarted) {
      await startDay();
    } else if (isMining) {
      liveTimer?.cancel();
      setState(() => isMining = false);
    } else {
      setState(() {
        isMining      = true;
        baseUsdAtSync = liveUSD;
        baseSolAtSync = liveSOL;
        lastSyncTime  = DateTime.now();
      });
      startLiveTimer();
    }
  }

  // ─── Timers ───────────────────────────────────────────────────────────────
  void startLiveTimer() {
    liveTimer?.cancel();
    liveTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!isMining || lastSyncTime == null) return;
      final secs = DateTime.now().difference(lastSyncTime!).inMilliseconds / 1000.0;
      final newUSD = (baseUsdAtSync + secs * usdPerSec).clamp(0.0, kUsdTarget);
      final newSOL = baseSolAtSync + secs * solPerSec;
      setState(() {
        liveUSD       = newUSD;
        liveSOL       = newSOL;
        cycleProgress = (newUSD / kUsdTarget).clamp(0.0, 1.0);
      });
    });
  }

  void startAutoSync() {
    syncTimer?.cancel();
    syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isMining) fetchStatus();
    });
  }

  void dispose() {
    liveTimer?.cancel();
    syncTimer?.cancel();
  }
}
