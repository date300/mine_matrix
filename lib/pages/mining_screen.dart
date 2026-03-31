// mining_screen.dart
// pubspec.yaml এ যোগ করো:
//   http: ^1.2.1
//
// ✅ শুধু এই একটা লাইন পরিবর্তন করো তোমার server URL দিয়ে:
//   static const String _baseUrl = 'https://yourdomain.com/api/mining';
//
// ✅ লগইনের পর token সেট করো:
//   MiningApi.token = 'তোমার_jwt_token';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_background/animated_background.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColors {
  static const Color background   = Color(0xFF0D0D12);
  static const Color accentGreen  = Color(0xFF14F195);
  static const Color accentPurple = Color(0xFF9945FF);
  static const Color glassWhite   = Color(0xAAFFFFFF);
  static const Color accentLeaf   = Color(0xFF76C442);
  static const Color accentOrange = Color(0xFFFF9500);
}

// ===================== API SERVICE =====================
// API Endpoints (from backend):
//   GET  /api/mining/status   → { balance, coins, withdrawable, boostMultiplier, aiMultiplier, liveUSD }
//   POST /api/mining/start-day → starts mining session (needs $18 balance)
//   POST /api/mining/claim     → claims earned USD (requires mining active, <24h, resets coins when ≥$100)
//   POST /api/mining/boost     → body: { amount: 1-50 } → activates boost multiplier

class MiningApi {
  // ✅ তোমার server URL এখানে বসাও
  static const String _baseUrl = 'https://ltcminematrix.com/api/mining';

  // ✅ লগইনের পর এখানে JWT token সেট করো: MiningApi.token = '...';
  static String token = '';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // GET /mining/status
  // Returns: { balance, coins, withdrawable, boostMultiplier, aiMultiplier, liveUSD }
  static Future<Map<String, dynamic>?> getStatus() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/status'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  // POST /mining/start-day
  // Requires: balance >= $18
  // Returns: { msg: "Mining started" }
  static Future<Map<String, dynamic>?> startDay() async {
    try {
      final res = await http
          .post(Uri.parse('$_baseUrl/start-day'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  // POST /mining/claim
  // Returns: { msg, earned, withdrawableAdded, totalWithdrawable }
  // Errors: 400 if not started, 24h expired, or mining not active
  static Future<Map<String, dynamic>?> claim() async {
    try {
      final res = await http
          .post(Uri.parse('$_baseUrl/claim'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
      // Return error body for 400 cases
      return {'error': true, 'body': res.body, 'statusCode': res.statusCode};
    } catch (_) {}
    return null;
  }

  // POST /mining/boost
  // Body: { amount: 1-50 }
  // Returns: { msg, boostMultiplier, balance }
  static Future<Map<String, dynamic>?> boost(double amount) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/boost'),
            headers: _headers,
            body: jsonEncode({'amount': amount}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
      return {'error': true, 'body': res.body};
    } catch (_) {}
    return null;
  }
}

void main() => runApp(const VexylonApp());

class VexylonApp extends StatelessWidget {
  const VexylonApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppColors.background,
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          home: const MiningScreen(),
        );
      },
    );
  }
}

// ===================== CONTROLLER =====================
// API Logic:
//   - BASE_PER_SECOND = $100 / (360 days * 86400 sec) = ~0.00000321 USD/sec
//   - boostMultiplier: 1x to 4.5x (boost $1-$50, NORMAL_DAYS/BOOST_DAYS = 360/80)
//   - aiMultiplier: 0.85 to 1.15 (based on session behavior)
//   - liveUSD = coins + seconds * (BASE_PER_SECOND * boostMultiplier * aiMultiplier)
//   - coins → withdrawableCoins when coins >= $100

class MiningController extends GetxController {
  // Config matching backend
  static const double entryFee     = 18.0;   // $18 entry fee
  static const double usdTarget    = 100.0;  // $100 to complete a cycle
  static const int    normalDays   = 360;    // base plan days
  static const int    boostDays    = 80;     // boosted plan days
  static const double boostMin     = 1.0;
  static const double boostMax     = 50.0;

  // BASE_PER_SECOND from backend
  static const double basePerSecond = usdTarget / (normalDays * 24 * 60 * 60);

  // ─── Observables ───────────────────────────────────────
  var isLoading        = false.obs;

  // From GET /status
  var balance          = 0.0.obs;   // wallet balance (deducted on boost/start)
  var coins            = 0.0.obs;   // current mining cycle accumulated USD
  var withdrawable     = 0.0.obs;   // total withdrawable USD
  var boostMultiplier  = 1.0.obs;   // 1.0 → 4.5
  var aiMultiplier     = 1.0.obs;   // 0.85 → 1.15
  var liveUSD          = 0.0.obs;   // live calculated USD from server

  // Local derived state
  var isMining         = false.obs;
  var hasPaid          = false.obs;  // true if balance >= $18 (can start)
  var dayStarted       = false.obs;  // true after start-day called
  var boostActive      = false.obs;  // true if boostMultiplier > 1
  var boostAmount      = 0.0.obs;

  // Progress tracking (local UI)
  var cycleProgress    = 0.0.obs;   // 0→1 for $100 cycle
  var liveEarning      = 0.0.obs;   // local live calculation (updates every 100ms)

  Timer? _liveTimer;
  Timer? _syncTimer;
  DateTime? _sessionStart;

  bool get canClaim => dayStarted.value && isMining.value;
  bool get canStartDay => hasPaid.value && !dayStarted.value;

  @override
  void onInit() {
    super.onInit();
    _loadFromServer();
  }

  // ✅ Server থেকে status লোড করো
  Future<void> _loadFromServer() async {
    isLoading.value = true;
    final data = await MiningApi.getStatus();
    if (data != null && data['error'] == null) {
      balance.value         = _toDouble(data['balance']);
      coins.value           = _toDouble(data['coins']);
      withdrawable.value    = _toDouble(data['withdrawable']);
      boostMultiplier.value = _toDouble(data['boostMultiplier'] ?? 1.0);
      aiMultiplier.value    = _toDouble(data['aiMultiplier'] ?? 1.0);
      liveUSD.value         = _toDouble(data['liveUSD']);

      // Derived
      hasPaid.value    = balance.value >= entryFee;
      boostActive.value = boostMultiplier.value > 1.0;
      cycleProgress.value = (coins.value / usdTarget).clamp(0.0, 1.0);
      liveEarning.value = liveUSD.value;
    }
    isLoading.value = false;
  }

  // ✅ Refresh status (call after any action)
  Future<void> refreshStatus() async {
    final data = await MiningApi.getStatus();
    if (data != null && data['error'] == null) {
      balance.value         = _toDouble(data['balance']);
      coins.value           = _toDouble(data['coins']);
      withdrawable.value    = _toDouble(data['withdrawable']);
      boostMultiplier.value = _toDouble(data['boostMultiplier'] ?? 1.0);
      aiMultiplier.value    = _toDouble(data['aiMultiplier'] ?? 1.0);
      liveUSD.value         = _toDouble(data['liveUSD']);

      boostActive.value   = boostMultiplier.value > 1.0;
      cycleProgress.value = (coins.value / usdTarget).clamp(0.0, 1.0);
      liveEarning.value   = liveUSD.value;
    }
  }

  // ✅ Start Mining Day — POST /mining/start-day
  Future<bool> startDay() async {
    if (balance.value < entryFee) {
      Get.snackbar('❌ Error', 'Need \$18 balance to start mining',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8));
      return false;
    }

    isLoading.value = true;
    final data = await MiningApi.startDay();
    isLoading.value = false;

    if (data != null && data['error'] == null) {
      dayStarted.value  = true;
      isMining.value    = true;
      _sessionStart     = DateTime.now();
      _startLiveTimer();
      _startAutoSync();
      Get.snackbar('✅ Mining Started', 'Earn \$100 to complete a cycle!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.accentGreen.withOpacity(0.9),
          colorText: Colors.black);
      return true;
    } else {
      // Parse error message from backend
      String errMsg = 'Could not start mining';
      try {
        final body = data?['body'];
        if (body != null) {
          final parsed = jsonDecode(body);
          errMsg = parsed['msg'] ?? errMsg;
        }
      } catch (_) {}
      Get.snackbar('❌ Error', errMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8));
      return false;
    }
  }

  void toggleMining() {
    if (!hasPaid.value) {
      Get.snackbar('❌ Locked', 'Need \$18 balance to unlock mining',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8));
      return;
    }
    if (!dayStarted.value) {
      startDay();
    } else if (isMining.value) {
      // Pause local timer (session is still valid on server)
      _liveTimer?.cancel();
      isMining.value = false;
    } else {
      // Resume local timer
      isMining.value = true;
      _startLiveTimer();
    }
  }

  // Live USD counter (local, based on backend formula)
  void _startLiveTimer() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!isMining.value || _sessionStart == null) return;
      final seconds = DateTime.now().difference(_sessionStart!).inMilliseconds / 1000.0;
      final usdPerSecond = basePerSecond * boostMultiplier.value * aiMultiplier.value;
      liveEarning.value = coins.value + seconds * usdPerSecond;
      cycleProgress.value = (liveEarning.value / usdTarget).clamp(0.0, 1.0);
    });
  }

  // Auto-sync status every 30s
  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isMining.value) refreshStatus();
    });
  }

  // ✅ Claim — POST /mining/claim
  // Returns { earned, withdrawableAdded, totalWithdrawable } on success
  Future<Map<String, dynamic>?> claimReward() async {
    isLoading.value = true;
    final data = await MiningApi.claim();
    isLoading.value = false;

    if (data != null && data['error'] == null) {
      // Reset local state
      _liveTimer?.cancel();
      _syncTimer?.cancel();
      isMining.value    = false;
      dayStarted.value  = false;
      _sessionStart     = null;

      // Refresh from server to get updated coins/withdrawable
      await refreshStatus();

      Get.snackbar('✅ Claim Success', 'Earned: \$${data['earned']}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.accentGreen.withOpacity(0.9),
          colorText: Colors.black);
      return data;
    } else {
      // Parse server error
      String errMsg = 'Claim failed';
      try {
        final body = data?['body'];
        if (body != null) {
          final parsed = jsonDecode(body);
          errMsg = parsed['msg'] ?? errMsg;
        }
      } catch (_) {}

      // If 24h expired, reset local mining state
      if (errMsg.contains('expired') || errMsg.contains('24h')) {
        dayStarted.value = false;
        isMining.value   = false;
        _liveTimer?.cancel();
        _syncTimer?.cancel();
        _sessionStart = null;
      }

      Get.snackbar('❌ Claim Failed', errMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8));
      return null;
    }
  }

  // ✅ Boost — POST /mining/boost
  Future<bool> activateBoost(double amount) async {
    isLoading.value = true;
    final data = await MiningApi.boost(amount);
    isLoading.value = false;

    if (data != null && data['error'] == null) {
      boostMultiplier.value = _toDouble(data['boostMultiplier'] ?? 1.0);
      balance.value         = _toDouble(data['balance']);
      boostAmount.value     = amount;
      boostActive.value     = true;

      Get.snackbar('✅ Boost Activated!',
          'Mining speed: ${boostMultiplier.value.toStringAsFixed(2)}x  |  80 days',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.accentPurple.withOpacity(0.9));
      return true;
    } else {
      String errMsg = 'Boost failed';
      try {
        final body = data?['body'];
        if (body != null) {
          final parsed = jsonDecode(body);
          errMsg = parsed['msg'] ?? errMsg;
        }
      } catch (_) {}
      Get.snackbar('❌ Error', errMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8));
      return false;
    }
  }

  // Helper converters
  double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  @override
  void onClose() {
    _liveTimer?.cancel();
    _syncTimer?.cancel();
    super.onClose();
  }
}

// ===================== SCREEN =====================
class MiningScreen extends StatefulWidget {
  const MiningScreen({super.key});
  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen>
    with TickerProviderStateMixin {
  final MiningController controller = Get.put(MiningController());

  double _dw(BuildContext ctx, {double pct = 0.84, double min = 260, double max = 340}) =>
      (MediaQuery.of(ctx).size.width * pct).clamp(min, max);
  double _dh(BuildContext ctx, {double pct = 0.45, double min = 240, double max = 360}) =>
      (MediaQuery.of(ctx).size.height * pct).clamp(min, max);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: LayoutBuilder(
                builder: (context, constraints) => _buildMiningContent(),
              ),
            ),
          ),
          // Loading overlay
          Obx(() => controller.isLoading.value
              ? Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.accentGreen),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildMiningContent() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Column(
        children: [
          SizedBox(height: 15.h),
          _buildBalanceSection(),
          SizedBox(height: 10.h),
          _buildCycleProgressSection(),
          SizedBox(height: 8.h),
          Obx(() => controller.boostActive.value
              ? _buildBoostInfoSection()
              : const SizedBox.shrink()),
          SizedBox(height: 8.h),
          _buildWithdrawableSection(),
          SizedBox(height: 24.h),
          _buildMiningOrb(),
          SizedBox(height: 20.h),
          _buildCycleProgressBar(),
          SizedBox(height: 25.h),
          Obx(() => controller.hasPaid.value
              ? _buildActionButtons()
              : _buildEntryFeeInfo()),
          SizedBox(height: 12.h),
          _buildStatsGrid(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // ─── Balance Section ───────────────────────────────────
  Widget _buildBalanceSection() {
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
      borderGradient: LinearGradient(
          colors: [AppColors.accentGreen.withOpacity(0.2), Colors.transparent]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "LIVE EARNINGS",
            style: GoogleFonts.inter(
                color: Colors.white54, fontSize: 10.sp,
                fontWeight: FontWeight.w600, letterSpacing: 1.2),
          ),
          SizedBox(height: 4.h),
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "\$${controller.liveEarning.value.toStringAsFixed(4)}",
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 5.w),
                  Padding(
                    padding: EdgeInsets.only(bottom: 3.h),
                    child: Text(
                      "USD",
                      style: GoogleFonts.inter(
                          color: AppColors.accentGreen,
                          fontSize: 14.sp, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              )),
          SizedBox(height: 5.h),
          Obx(() {
            final pct = (controller.liveEarning.value / MiningController.usdTarget * 100)
                .clamp(0.0, 100.0);
            return Text(
              "Wallet: \$${controller.balance.value.toStringAsFixed(2)}  |  ${pct.toStringAsFixed(1)}% to \$100 Claim",
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
            );
          }),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  // ─── Cycle Progress Section ────────────────────────────
  Widget _buildCycleProgressSection() {
    return Obx(() {
      final prog   = controller.cycleProgress.value;
      final earned = controller.liveEarning.value;
      final mining = controller.isMining.value;

      String statusText;
      Color  statusColor;
      if (mining) {
        statusText  = "Mining in progress...";
        statusColor = AppColors.accentGreen;
      } else if (controller.dayStarted.value) {
        statusText  = "Paused — tap ORB to resume";
        statusColor = Colors.orange;
      } else if (controller.hasPaid.value) {
        statusText  = "Tap ORB to start mining";
        statusColor = AppColors.accentGreen.withOpacity(0.85);
      } else {
        statusText  = "Need \$18 balance";
        statusColor = Colors.white38;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(CupertinoIcons.chart_bar_fill,
                        color: AppColors.accentGreen, size: 10.sp),
                    SizedBox(width: 4.w),
                    Text(
                      "\$18 → \$100 CYCLE",
                      style: GoogleFonts.inter(
                        color: AppColors.accentGreen, fontSize: 9.sp,
                        fontWeight: FontWeight.w800, letterSpacing: 0.8,
                      ),
                    ),
                  ]),
                  Flexible(
                    child: Text(
                      "\$${earned.toStringAsFixed(3)} / \$${MiningController.usdTarget.toStringAsFixed(0)}",
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 9.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              LinearPercentIndicator(
                lineHeight: 5.h,
                percent: prog.clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                linearGradient: const LinearGradient(
                  colors: [AppColors.accentGreen, AppColors.accentPurple],
                ),
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: 5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${(prog * 100).toStringAsFixed(2)}% complete",
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
                  ),
                  Flexible(
                    child: Text(
                      statusText,
                      style: GoogleFonts.inter(
                        color: statusColor, fontSize: 9.sp, fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ─── Boost Info Section ────────────────────────────────
  Widget _buildBoostInfoSection() {
    return Obx(() {
      final multiplier = controller.boostMultiplier.value;
      final amount     = controller.boostAmount.value;
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
          AppColors.accentPurple.withOpacity(0.4), Colors.transparent,
        ]),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(CupertinoIcons.rocket_fill,
                        color: AppColors.accentPurple, size: 10.sp),
                    SizedBox(width: 4.w),
                    Text(
                      "BOOST ACTIVE  |  \$${amount.toStringAsFixed(0)} invested",
                      style: GoogleFonts.inter(
                          color: AppColors.accentPurple, fontSize: 9.sp,
                          fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                  ]),
                  Text(
                    "${multiplier.toStringAsFixed(2)}x speed",
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 9.sp),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              LinearPercentIndicator(
                lineHeight: 5.h,
                percent: ((multiplier - 1.0) / (MiningController.normalDays / MiningController.boostDays - 1.0))
                    .clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                linearGradient: const LinearGradient(
                    colors: [AppColors.accentPurple, Color(0xFFCC44FF)]),
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: 5.h),
              Text(
                "360 days → ${MiningController.boostDays} days  |  AI multiplier: ${controller.aiMultiplier.value.toStringAsFixed(2)}x",
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ─── Withdrawable Section ──────────────────────────────
  Widget _buildWithdrawableSection() {
    return Obx(() {
      final withdrawable = controller.withdrawable.value;
      if (withdrawable <= 0) return const SizedBox.shrink();
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
          AppColors.accentLeaf.withOpacity(0.4), Colors.transparent,
        ]),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Row(
            children: [
              Icon(CupertinoIcons.checkmark_seal_fill,
                  color: AppColors.accentLeaf, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("WITHDRAWABLE BALANCE",
                        style: GoogleFonts.inter(
                            color: AppColors.accentLeaf, fontSize: 8.sp,
                            fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                    Text("\$${withdrawable.toStringAsFixed(2)} USD",
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 13.sp,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ─── Mining Orb ───────────────────────────────────────
  Widget _buildMiningOrb() {
    return Obx(() {
      final active    = controller.isMining.value;
      final paid      = controller.hasPaid.value;
      final started   = controller.dayStarted.value;
      final boosted   = controller.boostActive.value;

      final isPaused  = paid && started && !active;

      IconData    orbIcon;
      String      orbLabel;
      String      orbSubLabel = '';
      Color       orbIconColor;
      List<Color> borderColors;

      if (active && boosted) {
        orbIcon      = CupertinoIcons.rocket_fill;
        orbLabel     = "BOOSTED";
        orbSubLabel  = "MINING";
        orbIconColor = AppColors.accentPurple;
        borderColors = [AppColors.accentPurple, AppColors.accentGreen];
      } else if (active) {
        orbIcon      = CupertinoIcons.hammer_fill;
        orbLabel     = "MINING";
        orbIconColor = AppColors.accentGreen;
        borderColors = [AppColors.accentGreen, AppColors.accentPurple];
      } else if (isPaused) {
        orbIcon      = CupertinoIcons.pause_fill;
        orbLabel     = "PAUSED";
        orbSubLabel  = "Tap to resume";
        orbIconColor = Colors.orange;
        borderColors = [Colors.orange.withOpacity(0.6), Colors.white10];
      } else if (paid) {
        orbIcon      = CupertinoIcons.bolt_fill;
        orbLabel     = "START";
        orbSubLabel  = "Tap to mine";
        orbIconColor = Colors.white70;
        borderColors = [Colors.white38, Colors.white10];
      } else {
        orbIcon      = CupertinoIcons.lock_fill;
        orbLabel     = "LOCKED";
        orbSubLabel  = "\$18 balance needed";
        orbIconColor = AppColors.accentLeaf.withOpacity(0.75);
        borderColors = [AppColors.accentLeaf.withOpacity(0.45), Colors.white10];
      }

      return GestureDetector(
        onTap: controller.toggleMining,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (active)
              Container(
                width: 160.w,
                height: 160.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (boosted ? AppColors.accentPurple : AppColors.accentGreen)
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
                  .scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1)),
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
                  Text(
                    orbLabel,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w900),
                  ),
                  if (orbSubLabel.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(orbSubLabel,
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 8.sp)),
                  ],
                ],
              ),
            ).animate(target: active ? 1 : 0).shimmer(
                  duration: const Duration(milliseconds: 1500),
                  color: Colors.white24),
          ],
        ),
      );
    });
  }

  Widget _buildCycleProgressBar() {
    return Obx(() => LinearPercentIndicator(
          lineHeight: 6.h,
          percent: controller.cycleProgress.value.clamp(0.0, 1.0),
          backgroundColor: Colors.white10,
          linearGradient: const LinearGradient(
              colors: [AppColors.accentPurple, AppColors.accentGreen]),
          barRadius: const Radius.circular(10),
          padding: EdgeInsets.zero,
        ));
  }

  // ─── Action Buttons ────────────────────────────────────
  Widget _buildActionButtons() {
    return Obx(() {
      final claimable = controller.canClaim;
      return Row(
        children: [
          Expanded(child: _claimButton(claimable)),
          SizedBox(width: 8.w),
          Expanded(
            child: _smallButton("BOOST", CupertinoIcons.rocket_fill,
                AppColors.accentPurple, _showBoostDialog),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _smallButton("REFRESH", CupertinoIcons.arrow_clockwise,
                AppColors.accentLeaf, () => controller.refreshStatus()),
          ),
        ],
      );
    });
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.drop_fill,
                color: active ? AppColors.accentGreen : Colors.white38,
                size: 16.sp),
            SizedBox(width: 5.w),
            Text("CLAIM",
                style: GoogleFonts.inter(
                    color: active ? AppColors.accentGreen : Colors.white38,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryFeeInfo() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 64.h,
      borderRadius: 18.r,
      blur: 14,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.accentLeaf.withOpacity(0.13),
          Colors.white.withOpacity(0.03),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [AppColors.accentLeaf.withOpacity(0.55), Colors.transparent],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppColors.accentLeaf.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(CupertinoIcons.lock_fill,
                  color: AppColors.accentLeaf, size: 17.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MINING LOCKED",
                    style: GoogleFonts.inter(
                        color: AppColors.accentLeaf, fontSize: 13.sp,
                        fontWeight: FontWeight.w800, letterSpacing: 0.8),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "Need \$18 balance — deposit to start mining",
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 2200.ms, color: AppColors.accentLeaf.withOpacity(0.18));
  }

  Widget _smallButton(String label, IconData icon, Color color, VoidCallback? onTap) {
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16.sp),
            SizedBox(width: 5.w),
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ─── Stats Grid ────────────────────────────────────────
  Widget _buildStatsGrid() {
    return Obx(() => Row(
          children: [
            Expanded(child: _statBox(
              "BOOST",
              "${controller.boostMultiplier.value.toStringAsFixed(2)}x",
              AppColors.accentPurple,
            )),
            SizedBox(width: 8.w),
            Expanded(child: _statBox(
              "AI MULT",
              "${controller.aiMultiplier.value.toStringAsFixed(2)}x",
              Colors.orangeAccent,
            )),
            SizedBox(width: 8.w),
            Expanded(child: _statBox(
              "WITHDRAW",
              "\$${controller.withdrawable.value.toStringAsFixed(2)}",
              AppColors.accentLeaf,
            )),
          ],
        ));
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 9.sp, fontWeight: FontWeight.bold)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: GoogleFonts.inter(
                    color: color, fontSize: 14.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ===================== DIALOGS =====================

  void _showClaimDialog() {
    final currentEarned = controller.liveEarning.value;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) {
        final dw = _dw(ctx, pct: 0.84, min: 260, max: 340);
        final dh = _dh(ctx, pct: 0.44, min: 260, max: 310);
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
                      "Claim your earned USD to withdrawable balance.\nWhen you reach \$100 it becomes withdrawable.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 11.sp),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text("\$${currentEarned.toStringAsFixed(4)} USD",
                                style: GoogleFonts.inter(
                                    color: AppColors.accentGreen, fontSize: 26.sp,
                                    fontWeight: FontWeight.w900)),
                          ),
                          SizedBox(height: 4.h),
                          Text("Current session earnings",
                              style: GoogleFonts.inter(
                                  color: Colors.white54, fontSize: 11.sp)),
                        ],
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
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
                            onTap: () async {
                              Navigator.pop(ctx);
                              final data = await controller.claimReward();
                              if (data != null) {
                                _showClaimSuccessDialog(
                                  double.tryParse(data['earned']?.toString() ?? '0') ?? 0,
                                  double.tryParse(data['withdrawableAdded']?.toString() ?? '0') ?? 0,
                                  double.tryParse(data['totalWithdrawable']?.toString() ?? '0') ?? 0,
                                );
                              }
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
                                          color: Colors.black, fontSize: 13.sp,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _showClaimSuccessDialog(double earned, double withdrawableAdded, double totalWithdrawable) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) {
        final dw = _dw(ctx, pct: 0.78, min: 250, max: 310);
        final dh = _dh(ctx, pct: 0.42, min: 240, max: 290);
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
                AppColors.accentLeaf.withOpacity(0.7), Colors.transparent,
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
                        "Earned: \$${earned.toStringAsFixed(4)} USD",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            color: AppColors.accentLeaf, fontSize: 15.sp,
                            fontWeight: FontWeight.bold, height: 1.4),
                      ),
                    ),
                    if (withdrawableAdded > 0) ...[
                      SizedBox(height: 4.h),
                      Text(
                        "\$${withdrawableAdded.toStringAsFixed(2)} added to withdrawable!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppColors.accentGreen, fontSize: 11.sp),
                      ),
                    ],
                    SizedBox(height: 4.h),
                    Text(
                      "Total withdrawable: \$${totalWithdrawable.toStringAsFixed(2)}",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp),
                    ),
                    SizedBox(height: 18.h),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: double.infinity,
                        height: 44.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.accentLeaf, Color(0xFF2E8B00)]),
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
    final earned = controller.liveEarning.value;
    final pct    = (earned / MiningController.usdTarget * 100).clamp(0.0, 100.0);
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
                Colors.orange.withOpacity(0.6), Colors.transparent,
              ]),
              child: Padding(
                padding: EdgeInsets.all(22.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.lock_fill, color: Colors.orange, size: 38.sp),
                    SizedBox(height: 12.h),
                    Text("Mining Not Active",
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 16.sp,
                            fontWeight: FontWeight.w900)),
                    SizedBox(height: 8.h),
                    Text(
                      "Start mining first by tapping the ORB.\nClaim is only available during an active session.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 11.sp),
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
                      "${pct.toStringAsFixed(1)}%  |  \$${(MiningController.usdTarget - earned).toStringAsFixed(2)} remaining to \$100",
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
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

  void _showBoostDialog() {
    final TextEditingController amountCtrl = TextEditingController();
    double? previewMultiplier;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final dw = _dw(ctx, pct: 0.84, min: 260, max: 340);
          final dh = _dh(ctx, pct: 0.50, min: 290, max: 360);
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
                    AppColors.accentPurple.withOpacity(0.12),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
                borderGradient: LinearGradient(colors: [
                  AppColors.accentPurple.withOpacity(0.7),
                  AppColors.accentGreen.withOpacity(0.3),
                ]),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 18.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.rocket_fill,
                          color: AppColors.accentPurple, size: 28.sp),
                      SizedBox(height: 8.h),
                      Text("BOOST MINING",
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 16.sp,
                              fontWeight: FontWeight.w900, letterSpacing: 1)),
                      SizedBox(height: 4.h),
                      Text("Max \$50  |  360 days → 80 days",
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 10.sp)),
                      SizedBox(height: 18.h),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(13.r),
                          border: Border.all(
                              color: AppColors.accentPurple.withOpacity(0.45),
                              width: 1),
                        ),
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 16.sp),
                          decoration: InputDecoration(
                            hintText: "Enter amount (\$1 - \$50)",
                            hintStyle: GoogleFonts.inter(
                                color: Colors.white30, fontSize: 11.sp),
                            prefixIcon: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 13.h),
                              child: Text("\$",
                                  style: GoogleFonts.inter(
                                      color: AppColors.accentPurple,
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.bold)),
                            ),
                            prefixIconConstraints:
                                BoxConstraints(minWidth: 0.w, minHeight: 0.h),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 14.h),
                          ),
                          onChanged: (val) {
                            final v = double.tryParse(val);
                            setState(() {
                              if (v != null && v >= 1 && v <= 50) {
                                // Backend formula: 1 + (ratio) * (360/80 - 1)
                                final ratio = v / MiningController.boostMax;
                                final maxMult = MiningController.normalDays / MiningController.boostDays;
                                previewMultiplier = 1 + ratio * (maxMult - 1);
                              } else {
                                previewMultiplier = null;
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 12.h),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: previewMultiplier != null
                            ? Container(
                                key: const ValueKey('preview'),
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 10.h),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                      color: AppColors.accentGreen.withOpacity(0.2)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(CupertinoIcons.arrow_up_right,
                                            color: AppColors.accentGreen, size: 12.sp),
                                        SizedBox(width: 5.w),
                                        Flexible(
                                          child: Text(
                                            "${previewMultiplier!.toStringAsFixed(2)}x speed  |  ${MiningController.boostDays} days",
                                            style: GoogleFonts.inter(
                                                color: AppColors.accentGreen,
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 3.h),
                                    Text("Reach \$100 faster",
                                        style: GoogleFonts.inter(
                                            color: Colors.white38, fontSize: 9.sp)),
                                  ],
                                ),
                              )
                            : SizedBox(key: const ValueKey('empty'), height: 44.h),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                height: 46.h,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(13.r),
                                  border: Border.all(color: Colors.white12, width: 1),
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
                                final v = double.tryParse(amountCtrl.text);
                                if (v == null || v < 1 || v > 50) return;
                                Navigator.pop(ctx);
                                controller.activateBoost(v);
                              },
                              child: Container(
                                height: 46.h,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    AppColors.accentPurple,
                                    AppColors.accentPurple.withOpacity(0.75),
                                  ]),
                                  borderRadius: BorderRadius.circular(13.r),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.rocket_fill,
                                        color: Colors.white, size: 14.sp),
                                    SizedBox(width: 6.w),
                                    Text("BOOST",
                                        style: GoogleFonts.inter(
                                            color: Colors.white, fontSize: 13.sp,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
