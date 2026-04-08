// mining_screen.dart
// Upgraded: real-time SOL mining counter, boostMultiplier/aiMultiplier from API

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_background/animated_background.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

// ─── Colors ──────────────────────────────────────────────────────────────────
class AppColors {
  static const Color background   = Color(0xFF0D0D12);
  static const Color accentGreen  = Color(0xFF14F195); // Solana green
  static const Color accentPurple = Color(0xFF9945FF); // Solana purple
  static const Color accentLeaf   = Color(0xFF76C442);
  static const Color bgCard       = Color(0xFF1B1B22);
  static const Color solanaGold   = Color(0xFFDC9C30);
}

// ─── Constants (mirrors backend) ─────────────────────────────────────────────
const double kEntryFee    = 18.0;
const double kUsdTarget   = 100.0;
const double kCoinsPerUsd = 1000.0;
const int    kNormalDays  = 360;
const int    kBoostDays   = 80;

// Fallback rate (used only before first API response)
const double kBaseUsdPerSec = kUsdTarget / (kNormalDays * 24 * 60 * 60);

// ─── Screen ───────────────────────────────────────────────────────────────────
class MiningScreen extends StatefulWidget {
  const MiningScreen({super.key});
  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen>
    with TickerProviderStateMixin {

  // ── Loading / error ────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool _hasError  = false;

  // ── From GET /api/mining/status ───────────────────────────────────────────
  bool   _miningActive    = false;
  double _minedCoins      = 0.0;
  double _equivalentUSD   = 0.0;
  double _withdrawableUSD = 0.0;

  // Multipliers (now comes from API)
  double _boostMultiplier = 1.0;
  double _aiMultiplier    = 1.0;
  bool   _boostActive     = false;
  double _boostAmount     = 0.0;   // boostUSD from API

  // Live rate fields (from API)
  double _usdPerSec  = kBaseUsdPerSec; // USD earned per second
  double _solPerSec  = 0.0;            // SOL earned per second
  double _solPrice   = 150.0;          // current SOL/USD price
  double _minedSOL   = 0.0;            // total SOL mined so far (server side)

  // ── Local UI state ────────────────────────────────────────────────────────
  bool   _dayStarted = false;
  bool   _isMining   = false;

  // Live counters (local estimate, resynced every 30 s)
  double    _liveUSD      = 0.0;   // USD counter (ticks every 100 ms)
  double    _liveSOL      = 0.0;   // SOL counter (ticks every 100 ms)
  double    _cycleProgress = 0.0;
  double    _baseUsdAtSync = 0.0;
  double    _baseSolAtSync = 0.0;
  DateTime? _lastSyncTime;

  // SOL per-second display (formatted, updated every second)
  String    _solPerSecDisplay = "0.00000000";

  Timer? _liveTimer;   // 100 ms — smooth counter
  Timer? _syncTimer;   // 30 s  — re-fetch from server

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchStatus());
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  // ── Token helper ──────────────────────────────────────────────────────────
  String? _getToken() =>
      Provider.of<AuthProvider>(context, listen: false).token;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  double _toDouble(dynamic v) =>
      double.tryParse(v?.toString() ?? '0') ?? 0.0;

  // ── GET /api/mining/status ────────────────────────────────────────────────
  Future<void> _fetchStatus() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _hasError = false; });

    try {
      final token = _getToken();
      if (token == null) {
        if (mounted) setState(() { _isLoading = false; _hasError = true; });
        return;
      }

      final res = await http.get(
        Uri.parse('https://web3.ltcminematrix.com/api/mining/status'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _applyStatus(data);
        setState(() => _isLoading = false);
      } else {
        setState(() { _isLoading = false; _hasError = true; });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  // Apply full status from server response
  void _applyStatus(Map<String, dynamic> data) {
    _miningActive    = data['miningActive'] == true;
    _minedCoins      = _toDouble(data['minedCoins']);
    _equivalentUSD   = _toDouble(data['equivalentUSD']);
    _withdrawableUSD = _toDouble(data['withdrawableUSD']);

    // Multipliers (now returned by upgraded backend)
    _boostMultiplier = _toDouble(data['boostMultiplier'] ?? 1.0);
    _aiMultiplier    = _toDouble(data['aiMultiplier']    ?? 1.0);
    _boostActive     = _boostMultiplier > 1.0;
    _boostAmount     = _toDouble(data['boostUSD']        ?? 0.0);

    // Live rate data (NEW from backend)
    _usdPerSec = _toDouble(data['usdPerSec'] ?? kBaseUsdPerSec);
    _solPerSec = _toDouble(data['solPerSec'] ?? 0.0);
    _solPrice  = _toDouble(data['solPriceUSD'] ?? 150.0);
    _minedSOL  = _toDouble(data['minedSOL']  ?? 0.0);

    // Seed live counters from server values
    _baseUsdAtSync  = _equivalentUSD;
    _baseSolAtSync  = _minedSOL;
    _lastSyncTime   = DateTime.now();
    _liveUSD        = _equivalentUSD;
    _liveSOL        = _minedSOL;
    _cycleProgress  = (_equivalentUSD / kUsdTarget).clamp(0.0, 1.0);
    _solPerSecDisplay = _formatSol(_solPerSec);

    if (_miningActive) {
      _dayStarted = true;
      _isMining   = true;
      _startLiveTimer();
      _startAutoSync();
    }
  }

  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isMining) _fetchStatus();
    });
  }

  // 100 ms ticker — updates live USD & SOL counters smoothly
  void _startLiveTimer() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_isMining || _lastSyncTime == null || !mounted) return;
      final secs = DateTime.now()
              .difference(_lastSyncTime!)
              .inMilliseconds /
          1000.0;

      final newUSD = (_baseUsdAtSync + secs * _usdPerSec)
          .clamp(0.0, kUsdTarget);
      final newSOL = _baseSolAtSync + secs * _solPerSec;

      setState(() {
        _liveUSD      = newUSD;
        _liveSOL      = newSOL;
        _cycleProgress = (newUSD / kUsdTarget).clamp(0.0, 1.0);
      });
    });
  }

  // ── POST /api/mining/start-day ────────────────────────────────────────────
  Future<void> _startDay() async {
    final token = _getToken();
    if (token == null) return;

    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('https://web3.ltcminematrix.com/api/mining/start-day'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res.statusCode == 200) {
        setState(() {
          _dayStarted    = true;
          _isMining      = true;
          _baseUsdAtSync = _equivalentUSD;
          _baseSolAtSync = _liveSOL;
          _lastSyncTime  = DateTime.now();
        });
        _startLiveTimer();
        _startAutoSync();
        _showSnack('⚡ Mining Started',
            'Earn \$100 to complete a cycle!', AppColors.accentGreen, Colors.black);
      } else {
        final body = jsonDecode(res.body);
        final msg  = body['error'] ?? body['message'] ?? 'Could not start mining';
        _showSnack('❌ Error', msg, Colors.red, Colors.white);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('❌ Error', 'Connection failed', Colors.red, Colors.white);
      }
    }
  }

  void _toggleMining() {
    if (!_dayStarted) {
      _startDay();
    } else if (_isMining) {
      _liveTimer?.cancel();
      setState(() => _isMining = false);
    } else {
      setState(() {
        _isMining      = true;
        _baseUsdAtSync = _liveUSD;
        _baseSolAtSync = _liveSOL;
        _lastSyncTime  = DateTime.now();
      });
      _startLiveTimer();
    }
  }

  // ── POST /api/mining/claim ────────────────────────────────────────────────
  Future<void> _doClaim() async {
    final token = _getToken();
    if (token == null) return;

    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('https://web3.ltcminematrix.com/api/mining/claim'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res.statusCode == 200) {
        final data       = jsonDecode(res.body);
        final double prevW   = _withdrawableUSD;
        final double newW    = _toDouble(data['withdrawable']);
        final double earned  = _liveUSD;
        final double added   = (newW - prevW).clamp(0.0, double.infinity);
        final bool complete  = (data['message'] ?? '')
            .toString().toLowerCase().contains('complete');

        _liveTimer?.cancel();
        _syncTimer?.cancel();
        setState(() {
          _dayStarted   = false;
          _isMining     = false;
          _lastSyncTime = null;
        });

        await _fetchStatus();

        if (mounted) {
          _showClaimSuccessDialog(earned, _liveSOL, added, newW);
          if (complete) {
            _showSnack('🎉 Cycle Complete!', '\$100 added to withdrawable!',
                AppColors.accentGreen, Colors.black);
          }
        }
      } else {
        final body = jsonDecode(res.body);
        final msg  = body['error'] ?? body['message'] ?? 'Claim failed';
        if (msg.toLowerCase().contains('wait')) {
          _showSnack('⏳ Too Soon',
              'Wait at least 60 seconds between claims', Colors.orange, Colors.white);
        } else {
          if (msg.toLowerCase().contains('no active')) {
            _liveTimer?.cancel();
            _syncTimer?.cancel();
            setState(() { _dayStarted = false; _isMining = false; });
          }
          _showSnack('❌ Claim Failed', msg, Colors.red, Colors.white);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('❌ Error', 'Connection failed', Colors.red, Colors.white);
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _showSnack(String title, String msg, Color bg, Color textColor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$title  $msg',
          style: GoogleFonts.inter(
              color: textColor, fontWeight: FontWeight.bold)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  String _formatSol(double v) {
    if (v >= 0.001)    return v.toStringAsFixed(6);
    if (v >= 0.000001) return v.toStringAsFixed(8);
    return v.toStringAsFixed(10);
  }

  double _dw(BuildContext ctx,
          {double pct = 0.84, double min = 260, double max = 340}) =>
      (MediaQuery.of(ctx).size.width * pct).clamp(min, max);
  double _dh(BuildContext ctx,
          {double pct = 0.45, double min = 240, double max = 360}) =>
      (MediaQuery.of(ctx).size.height * pct).clamp(min, max);

  // ═══════════════════════════════════════════════════════════════ BUILD ═════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Particle background
          AnimatedBackground(
            vsync: this,
            behaviour: RandomParticleBehaviour(
              options: const ParticleOptions(
                baseColor: AppColors.accentGreen,
                spawnOpacity: 0.1,
                particleCount: 15,
              ),
            ),
            child: Container(),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accentGreen))
                : _hasError
                    ? _buildError()
                    : RefreshIndicator(
                        color: AppColors.accentGreen,
                        backgroundColor: AppColors.bgCard,
                        onRefresh: _fetchStatus,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 18.w),
                          child: Column(
                            children: [
                              SizedBox(height: 15.h),
                              _buildLiveEarningsCard(),          // USD counter
                              SizedBox(height: 8.h),
                              _buildSolanaLiveCard(),            // ★ NEW SOL counter
                              SizedBox(height: 8.h),
                              _buildCycleProgressSection(),
                              SizedBox(height: 8.h),
                              if (_boostActive) ...[
                                _buildBoostInfoSection(),
                                SizedBox(height: 8.h),
                              ],
                              if (_withdrawableUSD > 0) ...[
                                _buildWithdrawableSection(),
                                SizedBox(height: 8.h),
                              ],
                              SizedBox(height: 16.h),
                              _buildMiningOrb(),
                              SizedBox(height: 20.h),
                              _buildCycleProgressBar(),
                              SizedBox(height: 25.h),
                              _buildActionButtons(),
                              SizedBox(height: 12.h),
                              _buildStatsGrid(),
                              SizedBox(height: 30.h),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ─── USD live earnings card (existing, kept) ──────────────────────────────
  Widget _buildLiveEarningsCard() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 115.h,
      borderRadius: 20.r,
      blur: 20,
      alignment: Alignment.center,
      border: 0.5,
      linearGradient: LinearGradient(colors: [
        AppColors.accentGreen.withOpacity(0.05),
        Colors.white.withOpacity(0.02),
      ]),
      borderGradient: LinearGradient(colors: [
        AppColors.accentGreen.withOpacity(0.2),
        Colors.transparent,
      ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("LIVE EARNINGS",
              style: GoogleFonts.inter(
                  color: Colors.white54, fontSize: 10.sp,
                  fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("\$${_liveUSD.toStringAsFixed(4)}",
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 28.sp,
                      fontWeight: FontWeight.bold)),
              SizedBox(width: 5.w),
              Padding(
                padding: EdgeInsets.only(bottom: 3.h),
                child: Text("USD",
                    style: GoogleFonts.inter(
                        color: AppColors.accentGreen,
                        fontSize: 14.sp, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Text(
            "Withdrawable: \$${_withdrawableUSD.toStringAsFixed(2)}"
            "  |  ${(_cycleProgress * 100).clamp(0, 100).toStringAsFixed(1)}% to \$100",
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  // ─── ★ NEW: Solana live mining card ──────────────────────────────────────
  Widget _buildSolanaLiveCard() {
    final bool active = _isMining;

    return GlassmorphicContainer(
      width: double.infinity,
      height: 130.h,
      borderRadius: 20.r,
      blur: 20,
      alignment: Alignment.center,
      border: active ? 1.0 : 0.5,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.accentPurple.withOpacity(active ? 0.12 : 0.04),
          AppColors.accentGreen.withOpacity(active ? 0.06 : 0.02),
        ],
      ),
      borderGradient: LinearGradient(colors: [
        AppColors.accentPurple.withOpacity(active ? 0.5 : 0.15),
        AppColors.accentGreen.withOpacity(active ? 0.3 : 0.08),
      ]),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Solana logo placeholder (circle)
                Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.accentPurple, AppColors.accentGreen],
                    ),
                  ),
                  child: Center(
                    child: Text("◎",
                        style: TextStyle(
                            color: Colors.white, fontSize: 11.sp,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 7.w),
                Text("SOLANA MINING",
                    style: GoogleFonts.inter(
                        color: AppColors.accentPurple,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0)),
                const Spacer(),
                // SOL price badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                        color: AppColors.accentPurple.withOpacity(0.3)),
                  ),
                  child: Text(
                    "1 SOL = \$${_solPrice.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(
                        color: AppColors.accentPurple,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10.h),

            // Big SOL counter
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatSol(_liveSOL),
                      style: GoogleFonts.spaceMono(
                          color: active ? AppColors.accentGreen : Colors.white38,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Text("SOL",
                      style: GoogleFonts.inter(
                          color: AppColors.accentGreen,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),

            SizedBox(height: 6.h),

            // Per-second rate + pulse dot
            Row(
              children: [
                if (active)
                  _PulseDot(color: AppColors.accentGreen)
                else
                  Container(
                    width: 7.w, height: 7.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white24,
                    ),
                  ),
                SizedBox(width: 6.w),
                Text(
                  active
                      ? "+${_formatSol(_solPerSec)} SOL/sec"
                      : "Start mining to earn SOL",
                  style: GoogleFonts.spaceMono(
                      color: active ? Colors.white60 : Colors.white24,
                      fontSize: 9.sp),
                ),
                const Spacer(),
                // USD equivalent of live SOL
                if (active)
                  Text(
                    "≈ \$${(_liveSOL * _solPrice).toStringAsFixed(4)}",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 9.sp),
                  ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate(target: active ? 1.0 : 0.0)
        .shimmer(
            duration: const Duration(milliseconds: 2000),
            color: AppColors.accentGreen.withOpacity(0.06));
  }

  // ─── Cycle progress section ───────────────────────────────────────────────
  Widget _buildCycleProgressSection() {
    String statusText;
    Color  statusColor;
    if (_isMining) {
      statusText  = "Mining in progress...";
      statusColor = AppColors.accentGreen;
    } else if (_dayStarted) {
      statusText  = "Paused – tap ORB to resume";
      statusColor = Colors.orange;
    } else {
      statusText  = "Tap ORB to start mining";
      statusColor = AppColors.accentGreen.withOpacity(0.85);
    }

    return GlassmorphicContainer(
      width: double.infinity,
      height: 82.h,
      borderRadius: 16.r,
      blur: 10,
      alignment: Alignment.center,
      border: 0.5,
      linearGradient: LinearGradient(colors: [
        AppColors.accentGreen.withOpacity(0.06),
        Colors.white.withOpacity(0.02),
      ]),
      borderGradient: LinearGradient(colors: [
        AppColors.accentGreen.withOpacity(0.35),
        Colors.transparent,
      ]),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(CupertinoIcons.chart_bar_fill,
                  color: AppColors.accentGreen, size: 10.sp),
              SizedBox(width: 4.w),
              Text("\$18 → \$100 CYCLE",
                  style: GoogleFonts.inter(
                      color: AppColors.accentGreen, fontSize: 9.sp,
                      fontWeight: FontWeight.w800, letterSpacing: 0.8)),
            ]),
            Flexible(
              child: Text(
                "\$${_liveUSD.toStringAsFixed(3)} / \$${kUsdTarget.toStringAsFixed(0)}",
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 9.sp),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          SizedBox(height: 6.h),
          LinearPercentIndicator(
            lineHeight: 5.h,
            percent: _cycleProgress.clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            linearGradient: const LinearGradient(
                colors: [AppColors.accentGreen, AppColors.accentPurple]),
            barRadius: const Radius.circular(10),
            padding: EdgeInsets.zero,
          ),
          SizedBox(height: 5.h),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("${(_cycleProgress * 100).toStringAsFixed(2)}% complete",
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp)),
            Flexible(
              child: Text(statusText,
                  style: GoogleFonts.inter(
                      color: statusColor, fontSize: 9.sp,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ]),
      ),
    );
  }

  // ─── Boost info ───────────────────────────────────────────────────────────
  Widget _buildBoostInfoSection() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 72.h,
      borderRadius: 16.r,
      blur: 10,
      alignment: Alignment.center,
      border: 0.5,
      linearGradient: LinearGradient(colors: [
        AppColors.accentPurple.withOpacity(0.08),
        Colors.white.withOpacity(0.02),
      ]),
      borderGradient: LinearGradient(colors: [
        AppColors.accentPurple.withOpacity(0.4),
        Colors.transparent,
      ]),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(CupertinoIcons.rocket_fill,
                  color: AppColors.accentPurple, size: 10.sp),
              SizedBox(width: 4.w),
              Text(
                "BOOST ACTIVE  |  \$${_boostAmount.toStringAsFixed(0)} invested",
                style: GoogleFonts.inter(
                    color: AppColors.accentPurple, fontSize: 9.sp,
                    fontWeight: FontWeight.w800, letterSpacing: 0.8)),
            ]),
            Text("${_boostMultiplier.toStringAsFixed(2)}x speed",
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 9.sp)),
          ]),
          SizedBox(height: 6.h),
          LinearPercentIndicator(
            lineHeight: 5.h,
            percent: ((_boostMultiplier - 1.0) /
                    (kNormalDays / kBoostDays - 1.0))
                .clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            linearGradient: const LinearGradient(
                colors: [AppColors.accentPurple, Color(0xFFCC44FF)]),
            barRadius: const Radius.circular(10),
            padding: EdgeInsets.zero,
          ),
          SizedBox(height: 5.h),
          Text(
            "360 days → $kBoostDays days  |  AI: ${_aiMultiplier.toStringAsFixed(2)}x",
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
          ),
        ]),
      ),
    );
  }

  // ─── Withdrawable section ─────────────────────────────────────────────────
  Widget _buildWithdrawableSection() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 58.h,
      borderRadius: 14.r,
      blur: 10,
      alignment: Alignment.center,
      border: 0.5,
      linearGradient: LinearGradient(colors: [
        AppColors.accentLeaf.withOpacity(0.08),
        Colors.white.withOpacity(0.02),
      ]),
      borderGradient: LinearGradient(colors: [
        AppColors.accentLeaf.withOpacity(0.4),
        Colors.transparent,
      ]),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: Row(children: [
          Icon(CupertinoIcons.checkmark_seal_fill,
              color: AppColors.accentLeaf, size: 16.sp),
          SizedBox(width: 8.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("WITHDRAWABLE BALANCE",
                  style: GoogleFonts.inter(
                      color: AppColors.accentLeaf, fontSize: 8.sp,
                      fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              Text("\$${_withdrawableUSD.toStringAsFixed(2)} USD",
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 13.sp,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ]),
      ),
    );
  }

  // ─── Mining ORB ───────────────────────────────────────────────────────────
  Widget _buildMiningOrb() {
    final isPaused = _dayStarted && !_isMining;

    IconData    orbIcon;
    String      orbLabel;
    String      orbSub = '';
    Color       orbIconColor;
    List<Color> borderColors;

    if (_isMining && _boostActive) {
      orbIcon      = CupertinoIcons.rocket_fill;
      orbLabel     = "BOOSTED";
      orbSub       = "MINING";
      orbIconColor = AppColors.accentPurple;
      borderColors = [AppColors.accentPurple, AppColors.accentGreen];
    } else if (_isMining) {
      orbIcon      = CupertinoIcons.hammer_fill;
      orbLabel     = "MINING";
      orbIconColor = AppColors.accentGreen;
      borderColors = [AppColors.accentGreen, AppColors.accentPurple];
    } else if (isPaused) {
      orbIcon      = CupertinoIcons.pause_fill;
      orbLabel     = "PAUSED";
      orbSub       = "Tap to resume";
      orbIconColor = Colors.orange;
      borderColors = [Colors.orange.withOpacity(0.6), Colors.white10];
    } else {
      orbIcon      = CupertinoIcons.bolt_fill;
      orbLabel     = "START";
      orbSub       = "Tap to mine";
      orbIconColor = Colors.white70;
      borderColors = [Colors.white38, Colors.white10];
    }

    return GestureDetector(
      onTap: _toggleMining,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isMining)
            Container(
              width: 160.w,
              height: 160.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (_boostActive
                          ? AppColors.accentPurple
                          : AppColors.accentGreen)
                      .withOpacity(0.5),
                  width: 2,
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .rotate(duration: const Duration(seconds: 3))
                .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    curve: Curves.easeInOutSine)
                .then()
                .scale(
                    begin: const Offset(1.1, 1.1),
                    end: const Offset(1, 1)),
          GlassmorphicContainer(
            width: 140.w,
            height: 140.w,
            borderRadius: 70.w,
            blur: 15,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(colors: [
              Colors.black.withOpacity(0.6),
              Colors.black.withOpacity(0.3),
            ]),
            borderGradient: LinearGradient(colors: borderColors),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(orbIcon, color: orbIconColor, size: 35.sp),
                SizedBox(height: 5.h),
                Text(orbLabel,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 12.sp,
                        fontWeight: FontWeight.w900)),
                if (orbSub.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(orbSub,
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 8.sp)),
                ],
                // Show per-second SOL inside ORB when mining
                if (_isMining) ...[
                  SizedBox(height: 4.h),
                  Text(
                    "+${_formatSol(_solPerSec)}/s",
                    style: GoogleFonts.spaceMono(
                        color: AppColors.accentGreen.withOpacity(0.8),
                        fontSize: 7.sp),
                  ),
                ],
              ],
            ),
          ).animate(target: _isMining ? 1 : 0).shimmer(
              duration: const Duration(milliseconds: 1500),
              color: Colors.white24),
        ],
      ),
    );
  }

  // ─── Cycle progress bar ───────────────────────────────────────────────────
  Widget _buildCycleProgressBar() {
    return LinearPercentIndicator(
      lineHeight: 6.h,
      percent: _cycleProgress.clamp(0.0, 1.0),
      backgroundColor: Colors.white10,
      linearGradient: const LinearGradient(
          colors: [AppColors.accentPurple, AppColors.accentGreen]),
      barRadius: const Radius.circular(10),
      padding: EdgeInsets.zero,
    );
  }

  // ─── Action buttons ───────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    final claimable = _dayStarted && _isMining;
    return Row(children: [
      Expanded(child: _claimButton(claimable)),
      SizedBox(width: 8.w),
      Expanded(
        child: _smallButton("REFRESH", CupertinoIcons.arrow_clockwise,
            AppColors.accentLeaf, _fetchStatus),
      ),
    ]);
  }

  Widget _claimButton(bool active) {
    return GestureDetector(
      onTap: active ? _showClaimDialog : _showClaimNotReadyDialog,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 60.h,
        borderRadius: 15.r,
        blur: 10,
        alignment: Alignment.center,
        border: active ? 1.0 : 0.5,
        linearGradient: LinearGradient(colors: [
          active
              ? AppColors.accentGreen.withOpacity(0.18)
              : Colors.white.withOpacity(0.05),
          Colors.transparent,
        ]),
        borderGradient: LinearGradient(colors: [
          active ? AppColors.accentGreen : Colors.white24,
          Colors.transparent,
        ]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(CupertinoIcons.drop_fill,
              color: active ? AppColors.accentGreen : Colors.white38,
              size: 16.sp),
          SizedBox(width: 5.w),
          Text("CLAIM",
              style: GoogleFonts.inter(
                  color: active ? AppColors.accentGreen : Colors.white38,
                  fontSize: 11.sp, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _smallButton(
      String label, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 60.h,
        borderRadius: 15.r,
        blur: 10,
        alignment: Alignment.center,
        border: 0.5,
        linearGradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.05), Colors.transparent]),
        borderGradient:
            LinearGradient(colors: [Colors.white24, Colors.transparent]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(width: 5.w),
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 11.sp,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  // ─── Stats grid ───────────────────────────────────────────────────────────
  Widget _buildStatsGrid() {
    return Row(children: [
      Expanded(
          child: _statBox("BOOST",
              "${_boostMultiplier.toStringAsFixed(2)}x", AppColors.accentPurple)),
      SizedBox(width: 8.w),
      Expanded(
          child: _statBox("AI MULT",
              "${_aiMultiplier.toStringAsFixed(2)}x", Colors.orangeAccent)),
      SizedBox(width: 8.w),
      Expanded(
          child: _statBox("WITHDRAW",
              "\$${_withdrawableUSD.toStringAsFixed(2)}", AppColors.accentLeaf)),
    ]);
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white38, fontSize: 9.sp,
                fontWeight: FontWeight.bold)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: GoogleFonts.inter(
                  color: color, fontSize: 14.sp, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────
  void _showClaimDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) {
        final dw = _dw(ctx, pct: 0.84, min: 260, max: 340);
        final dh = _dh(ctx, pct: 0.50, min: 280, max: 340);
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassmorphicContainer(
              width: dw,
              height: dh,
              borderRadius: 22.r,
              blur: 22,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentGreen.withOpacity(0.12),
                  Colors.black.withOpacity(0.8),
                ],
              ),
              borderGradient: LinearGradient(colors: [
                AppColors.accentGreen.withOpacity(0.7),
                AppColors.accentPurple.withOpacity(0.3),
              ]),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.drop_fill,
                        color: AppColors.accentGreen, size: 36.sp),
                    SizedBox(height: 10.h),
                    Text("CLAIM REWARD",
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 16.sp,
                            fontWeight: FontWeight.w900, letterSpacing: 1)),
                    SizedBox(height: 6.h),
                    Text(
                      "Claim your earned USD.\nReach \$100 to complete a cycle.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: Colors.white60, fontSize: 11.sp),
                    ),
                    SizedBox(height: 16.h),
                    // USD amount
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                            color: AppColors.accentGreen.withOpacity(0.3)),
                      ),
                      child: Column(children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                              "\$${_liveUSD.toStringAsFixed(4)} USD",
                              style: GoogleFonts.inter(
                                  color: AppColors.accentGreen,
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w900)),
                        ),
                        SizedBox(height: 2.h),
                        // SOL equivalent
                        Text(
                          "◎ ${_formatSol(_liveSOL)} SOL",
                          style: GoogleFonts.spaceMono(
                              color: AppColors.accentPurple,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2.h),
                        Text("Current session earnings",
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 10.sp)),
                      ]),
                    ),
                    SizedBox(height: 18.h),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            height: 46.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(13.r),
                              border: Border.all(color: Colors.white12),
                            ),
                            alignment: Alignment.center,
                            child: Text("Cancel",
                                style: GoogleFonts.inter(
                                    color: Colors.white60, fontSize: 13.sp)),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _doClaim();
                          },
                          child: Container(
                            height: 46.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                AppColors.accentGreen,
                                AppColors.accentGreen.withOpacity(0.75),
                              ]),
                              borderRadius: BorderRadius.circular(13.r),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.drop_fill,
                                    color: Colors.black, size: 14.sp),
                                SizedBox(width: 6.w),
                                Text("Claim Now",
                                    style: GoogleFonts.inter(
                                        color: Colors.black,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showClaimSuccessDialog(
      double earnedUSD, double earnedSOL, double withdrawableAdded, double totalWithdrawable) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) {
        final dw = _dw(ctx, pct: 0.78, min: 250, max: 310);
        final dh = _dh(ctx, pct: 0.48, min: 260, max: 320);
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassmorphicContainer(
              width: dw,
              height: dh,
              borderRadius: 22.r,
              blur: 22,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentLeaf.withOpacity(0.12),
                  Colors.black.withOpacity(0.8),
                ],
              ),
              borderGradient: LinearGradient(colors: [
                AppColors.accentLeaf.withOpacity(0.7),
                Colors.transparent,
              ]),
              child: Padding(
                padding: EdgeInsets.all(22.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.checkmark_seal_fill,
                        color: AppColors.accentLeaf, size: 44.sp),
                    SizedBox(height: 12.h),
                    Text("Claim Successful!",
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 16.sp,
                            fontWeight: FontWeight.w900)),
                    SizedBox(height: 8.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                          "Earned: \$${earnedUSD.toStringAsFixed(4)} USD",
                          style: GoogleFonts.inter(
                              color: AppColors.accentLeaf,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 4.h),
                    // SOL earned line (NEW)
                    Text(
                      "◎ ${_formatSol(earnedSOL)} SOL",
                      style: GoogleFonts.spaceMono(
                          color: AppColors.accentPurple,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold),
                    ),
                    if (withdrawableAdded > 0) ...[
                      SizedBox(height: 4.h),
                      Text(
                        "\$${withdrawableAdded.toStringAsFixed(2)} added to withdrawable!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            color: AppColors.accentGreen, fontSize: 11.sp),
                      ),
                    ],
                    SizedBox(height: 4.h),
                    Text(
                      "Total withdrawable: \$${totalWithdrawable.toStringAsFixed(2)}",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 10.sp),
                    ),
                    SizedBox(height: 18.h),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: double.infinity,
                        height: 44.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            AppColors.accentLeaf,
                            Color(0xFF2E8B00),
                          ]),
                          borderRadius: BorderRadius.circular(13.r),
                        ),
                        alignment: Alignment.center,
                        child: Text("OK",
                            style: GoogleFonts.inter(
                                color: Colors.white, fontSize: 14.sp,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showClaimNotReadyDialog() {
    final pct = (_liveUSD / kUsdTarget * 100).clamp(0.0, 100.0);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) {
        final dw = _dw(ctx, pct: 0.82, min: 250, max: 330);
        final dh = _dh(ctx, pct: 0.42, min: 250, max: 300);
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassmorphicContainer(
              width: dw,
              height: dh,
              borderRadius: 22.r,
              blur: 22,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.withOpacity(0.10),
                  Colors.black.withOpacity(0.8),
                ],
              ),
              borderGradient: LinearGradient(colors: [
                Colors.orange.withOpacity(0.6),
                Colors.transparent,
              ]),
              child: Padding(
                padding: EdgeInsets.all(22.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.lock_fill,
                        color: Colors.orange, size: 38.sp),
                    SizedBox(height: 12.h),
                    Text("Mining Not Active",
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 16.sp,
                            fontWeight: FontWeight.w900)),
                    SizedBox(height: 8.h),
                    Text(
                      "Start mining first by tapping the ORB.\nClaim is only available during an active session.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: Colors.white60, fontSize: 11.sp),
                    ),
                    SizedBox(height: 14.h),
                    LinearPercentIndicator(
                      lineHeight: 7.h,
                      percent: pct / 100,
                      backgroundColor: Colors.white10,
                      linearGradient: const LinearGradient(
                          colors: [Colors.orange, Color(0xFFFFCC00)]),
                      barRadius: const Radius.circular(10),
                      padding: EdgeInsets.zero,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "${pct.toStringAsFixed(1)}%  |  \$${(kUsdTarget - _liveUSD).toStringAsFixed(2)} remaining",
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 9.sp),
                    ),
                    SizedBox(height: 16.h),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: double.infinity,
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(13.r),
                          border: Border.all(color: Colors.white12),
                        ),
                        alignment: Alignment.center,
                        child: Text("OK",
                            style: GoogleFonts.inter(
                                color: Colors.white60, fontSize: 14.sp,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cloud_off_rounded, color: Colors.white30, size: 48.sp),
        SizedBox(height: 12.h),
        Text("Could not load mining data",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14.sp)),
        SizedBox(height: 16.h),
        ElevatedButton.icon(
          onPressed: _fetchStatus,
          icon: const Icon(Icons.refresh_rounded, color: Colors.black),
          label: Text("Retry",
              style: GoogleFonts.inter(
                  color: Colors.black, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r)),
          ),
        ),
      ]),
    );
  }
}

// ─── Pulsing green dot widget (shows live status) ─────────────────────────────
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 7.w,
          height: 7.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(color: widget.color.withOpacity(0.6), blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}

