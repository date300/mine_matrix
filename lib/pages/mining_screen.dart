// mining_screen.dart
// pubspec.yaml এ যোগ করো:
//   http: ^1.2.1
//
// ✅ শুধু এই একটা লাইন পরিবর্তন করো তোমার server URL দিয়ে:
//   static const String _baseUrl = 'https://yourdomain.com/mining';
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
  static Future<Map<String, dynamic>?> getStatus() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/status'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  // POST /mining/activate-plan
  static Future<bool> activatePlan() async {
    try {
      final res = await http.post(Uri.parse('$_baseUrl/activate-plan'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  // POST /mining/start-day
  static Future<bool> startDay() async {
    try {
      final res = await http.post(Uri.parse('$_baseUrl/start-day'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  // POST /mining/sync
  static Future<bool> sync({
    required double balance,
    required double totalEarned,
    required int completedDays,
    required bool isMining,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/sync'),
        headers: _headers,
        body: jsonEncode({
          'balance': balance,
          'total_earned': totalEarned,
          'completed_days': completedDays,
          'is_mining': isMining,
        }),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  // POST /mining/buy-boost
  static Future<bool> buyBoost(double amount) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/buy-boost'),
        headers: _headers,
        body: jsonEncode({'amount': amount}),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  // POST /mining/buy-autostart
  static Future<bool> buyAutoStart() async {
    try {
      final res = await http.post(Uri.parse('$_baseUrl/buy-autostart'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  // POST /mining/claim
  static Future<bool> claim() async {
    try {
      final res = await http.post(Uri.parse('$_baseUrl/claim'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) { return false; }
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
class MiningController extends GetxController {
  static const double entryFee       = 18.0;
  static const int    planDays       = 365;
  static const double targetSOL      = 10000.0;
  static const double solToUsd       = 0.01;
  static const double claimThreshold = 10000.0;
  static const double dailySOL       = targetSOL / planDays;
  static const int    ticksPerDay    = 864000;
  static const double perTickEarning = dailySOL / ticksPerDay;

  static const int    boostDays       = 80;
  static const int    totalBoostTicks = boostDays * ticksPerDay;
  static const double autoStartFee   = 10.0;

  var isMining        = false.obs;
  var hasPaid         = false.obs;
  var isComplete      = false.obs;
  var balance         = 0.0.obs;
  var cycleProgress   = 0.0.obs;
  var planProgress    = 0.0.obs;
  var remainingDays   = planDays.obs;
  var totalEarned     = 0.0.obs;

  var completedDays   = 0.obs;
  var currentDayNum   = 1.obs;
  var dayProgress     = 0.0.obs;
  var dayStarted      = false.obs;
  var canStartNewDay  = true.obs;
  var todayEarned     = 0.0.obs;

  var hasAutoStart    = false.obs;

  var boostPaid           = false.obs;
  var boostIsComplete     = false.obs;
  var boostAmount         = 0.0.obs;
  var boostProgress       = 0.0.obs;
  var boostRemainingDays  = boostDays.obs;
  var boostEarned         = 0.0.obs;
  var boostTotalSOL       = 0.0.obs;

  var totalClaimedSOL = 0.0.obs;
  var claimCount      = 0.obs;

  // Loading state for API calls
  var isLoading = false.obs;

  bool get canClaim => balance.value >= claimThreshold && hasPaid.value;

  Timer? _timer;
  Timer? _syncTimer;
  int    _dayElapsedTicks   = 0;
  int    _boostElapsedTicks = 0;
  double _boostPerTick      = 0.0;

  @override
  void onInit() {
    super.onInit();
    _loadFromServer();
  }

  // ✅ App খুললেই server থেকে data লোড
  Future<void> _loadFromServer() async {
    isLoading.value = true;
    final data = await MiningApi.getStatus();
    if (data != null && data['success'] == true) {
      final u = data['data'];
      hasPaid.value       = _toBool(u['has_paid']);
      balance.value       = _toDouble(u['balance']);
      totalEarned.value   = _toDouble(u['total_earned']);
      completedDays.value = _toInt(u['completed_days']);
      hasAutoStart.value  = _toBool(u['has_auto_start']);
      isMining.value      = _toBool(u['is_mining']);
      boostPaid.value     = _toBool(u['boost_paid']);
      boostAmount.value   = _toDouble(u['boost_amount']);
      claimCount.value    = _toInt(u['claim_count']);

      // Derived values
      currentDayNum.value = completedDays.value + 1;
      planProgress.value  = completedDays.value / planDays;
      remainingDays.value = planDays - completedDays.value;

      if (boostPaid.value && boostAmount.value > 0) {
        final total = boostAmount.value * 2.0 * (targetSOL / entryFee);
        boostTotalSOL.value = total;
        _boostPerTick = total / totalBoostTicks;
      }
    }
    isLoading.value = false;
  }

  // ✅ প্ল্যান অ্যাক্টিভেট — API call করে
  Future<void> activatePlan() async {
    isLoading.value = true;
    final ok = await MiningApi.activatePlan();
    if (ok) {
      hasPaid.value        = true;
      isComplete.value     = false;
      _dayElapsedTicks     = 0;
      completedDays.value  = 0;
      currentDayNum.value  = 1;
      balance.value        = 0;
      totalEarned.value    = 0;
      planProgress.value   = 0;
      remainingDays.value  = planDays;
      dayProgress.value    = 0;
      dayStarted.value     = false;
      canStartNewDay.value = true;
      todayEarned.value    = 0;
      Get.snackbar('✅ সফল', 'প্ল্যান অ্যাক্টিভেট হয়েছে!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.accentLeaf.withOpacity(0.9),
          colorText: Colors.black);
    } else {
      Get.snackbar('❌ Error', 'প্ল্যান অ্যাক্টিভেট হয়নি, আবার চেষ্টা করো',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8));
    }
    isLoading.value = false;
  }

  // ✅ অটো-স্টার্ট — API call করে
  Future<void> activateAutoStart() async {
    isLoading.value = true;
    final ok = await MiningApi.buyAutoStart();
    if (ok) {
      hasAutoStart.value = true;
      if (hasPaid.value && !isComplete.value &&
          !isMining.value && canStartNewDay.value && !dayStarted.value) {
        _startNewDay();
      }
      Get.snackbar('✅ সফল', 'Auto-Start চালু হয়েছে!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.accentOrange.withOpacity(0.9),
          colorText: Colors.black);
    } else {
      Get.snackbar('❌ Error', 'Auto-Start হয়নি',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8));
    }
    isLoading.value = false;
  }

  void toggleMining() {
    if (!hasPaid.value || isComplete.value) return;
    if (isMining.value) {
      _timer?.cancel();
      _syncTimer?.cancel();
      isMining.value = false;
      _syncToServer(); // pause হলে sync
    } else if (dayStarted.value) {
      _resumeMining();
    } else if (canStartNewDay.value) {
      _startNewDay();
    }
  }

  Future<void> _startNewDay() async {
    // ✅ API: start-day
    final ok = await MiningApi.startDay();
    if (!ok) {
      Get.snackbar('❌ Error', 'Day start হয়নি',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8));
      return;
    }
    dayStarted.value     = true;
    canStartNewDay.value = false;
    isMining.value       = true;
    _runTimer();
    _startAutoSync();
  }

  void _resumeMining() {
    isMining.value = true;
    _runTimer();
    _startAutoSync();
  }

  // ✅ প্রতি ৩০ সেকেন্ডে auto sync
  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isMining.value) _syncToServer();
    });
  }

  Future<void> _syncToServer() async {
    await MiningApi.sync(
      balance: balance.value,
      totalEarned: totalEarned.value,
      completedDays: completedDays.value,
      isMining: isMining.value,
    );
  }

  void _runTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (_dayElapsedTicks >= ticksPerDay) {
        t.cancel();
        _syncTimer?.cancel();
        isMining.value    = false;
        dayStarted.value  = false;
        completedDays.value++;
        _dayElapsedTicks  = 0;
        dayProgress.value = 0;
        todayEarned.value = 0;

        _syncToServer(); // day complete হলে sync

        if (completedDays.value >= planDays) {
          isComplete.value    = true;
          planProgress.value  = 1.0;
          remainingDays.value = 0;
          currentDayNum.value = planDays;
          return;
        }

        currentDayNum.value  = completedDays.value + 1;
        planProgress.value   = completedDays.value / planDays;
        remainingDays.value  = planDays - completedDays.value;

        Future.delayed(const Duration(seconds: 2), () {
          if (!isComplete.value) {
            canStartNewDay.value = true;
            if (hasAutoStart.value) _startNewDay();
          }
        });
        return;
      }

      balance.value      += perTickEarning;
      totalEarned.value  += perTickEarning;
      todayEarned.value  += perTickEarning;
      cycleProgress.value = (cycleProgress.value + 0.005) % 1.0;
      _dayElapsedTicks++;
      dayProgress.value   = _dayElapsedTicks / ticksPerDay;
      planProgress.value  =
          (completedDays.value * ticksPerDay + _dayElapsedTicks) /
          (planDays * ticksPerDay);
      remainingDays.value =
          (planDays - completedDays.value - _dayElapsedTicks / ticksPerDay)
              .ceil()
              .clamp(0, planDays);

      if (boostPaid.value && !boostIsComplete.value) {
        if (_boostElapsedTicks < totalBoostTicks) {
          balance.value         += _boostPerTick;
          boostEarned.value     += _boostPerTick;
          _boostElapsedTicks++;
          boostProgress.value    = _boostElapsedTicks / totalBoostTicks;
          boostRemainingDays.value =
              (boostDays - _boostElapsedTicks / ticksPerDay)
                  .ceil()
                  .clamp(0, boostDays);
        } else {
          boostIsComplete.value = true;
        }
      }
    });
  }

  // ✅ বুস্ট — API call করে
  Future<void> activateBoost(double amount) async {
    isLoading.value = true;
    final ok = await MiningApi.buyBoost(amount);
    if (ok) {
      boostPaid.value          = true;
      boostIsComplete.value    = false;
      boostAmount.value        = amount;
      _boostElapsedTicks       = 0;
      boostProgress.value      = 0;
      boostEarned.value        = 0;
      boostRemainingDays.value = boostDays;
      final total              = amount * 2.0 * (targetSOL / entryFee);
      boostTotalSOL.value      = total;
      _boostPerTick            = total / totalBoostTicks;
      Get.snackbar('✅ সফল', 'Boost চালু হয়েছে!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.accentPurple.withOpacity(0.9));
    } else {
      Get.snackbar('❌ Error', 'Boost হয়নি',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8));
    }
    isLoading.value = false;
  }

  // ✅ ক্লেইম — API call করে, return করে claimed amount (0 = failed)
  Future<double> claimReward() async {
    isLoading.value = true;
    final ok = await MiningApi.claim();
    if (ok) {
      final claimed         = balance.value;
      totalClaimedSOL.value += claimed;
      balance.value         = 0.0;
      claimCount.value++;
      isLoading.value = false;
      return claimed;
    } else {
      Get.snackbar('❌ Error', 'ক্লেইম হয়নি — Balance বা Plan চেক করো',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8));
      isLoading.value = false;
      return 0.0;
    }
  }

  // Helper converters
  bool   _toBool(dynamic v)   => v == 1 || v == true;
  double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;
  int    _toInt(dynamic v)    => int.tryParse(v?.toString() ?? '0') ?? 0;

  @override
  void onClose() {
    _timer?.cancel();
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
          // ✅ Loading overlay
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
          _buildPlanProgressSection(),
          SizedBox(height: 8.h),
          Obx(() => controller.hasPaid.value
              ? _buildDailySection()
              : const SizedBox.shrink()),
          SizedBox(height: 8.h),
          Obx(() => controller.boostPaid.value
              ? _buildBoostProgressSection()
              : const SizedBox.shrink()),
          SizedBox(height: 24.h),
          _buildMiningOrb(),
          SizedBox(height: 20.h),
          _buildCycleProgressBar(),
          SizedBox(height: 25.h),
          Obx(() => controller.hasPaid.value
              ? _buildActionButtons()
              : _buildEntryFeeButton()),
          SizedBox(height: 12.h),
          _buildStatsGrid(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildDailySection() {
    return Obx(() {
      final dayNum   = controller.currentDayNum.value;
      final prog     = controller.dayProgress.value;
      final earned   = controller.todayEarned.value;
      final mining   = controller.isMining.value;
      final started  = controller.dayStarted.value;
      final canStart = controller.canStartNewDay.value;
      final hasAuto  = controller.hasAutoStart.value;
      final complete = controller.isComplete.value;

      String statusText;
      Color  statusColor;
      if (complete) {
        statusText  = "Plan Complete!";
        statusColor = AppColors.accentLeaf;
      } else if (mining && hasAuto) {
        statusText  = "Auto Mining Active";
        statusColor = AppColors.accentOrange;
      } else if (mining) {
        statusText  = "Mining in progress...";
        statusColor = AppColors.accentGreen;
      } else if (started && !mining) {
        statusText  = "Paused - tap ORB to resume";
        statusColor = Colors.orange;
      } else if (!canStart && !started) {
        statusText  = "Today done - next day soon";
        statusColor = Colors.white38;
      } else {
        statusText  = "Tap ORB to start today";
        statusColor = AppColors.accentGreen.withOpacity(0.85);
      }

      final barColor = hasAuto ? AppColors.accentOrange : AppColors.accentGreen;

      return GlassmorphicContainer(
        width: double.infinity,
        height: 82.h,
        borderRadius: 16.r,
        blur: 10,
        alignment: Alignment.center,
        border: 0.5,
        linearGradient: LinearGradient(colors: [
          barColor.withOpacity(0.06),
          Colors.white.withOpacity(0.02),
        ]),
        borderGradient: LinearGradient(colors: [
          barColor.withOpacity(0.35),
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
                    Icon(
                      hasAuto ? CupertinoIcons.bolt_fill : CupertinoIcons.calendar,
                      color: barColor, size: 10.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "DAY $dayNum / 365${hasAuto ? '   AUTO' : ''}",
                      style: GoogleFonts.inter(
                        color: barColor, fontSize: 9.sp,
                        fontWeight: FontWeight.w800, letterSpacing: 0.8,
                      ),
                    ),
                  ]),
                  Flexible(
                    child: Text(
                      "${earned.toStringAsFixed(3)} / ${MiningController.dailySOL.toStringAsFixed(2)} SOL",
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
                linearGradient: LinearGradient(
                  colors: hasAuto
                      ? [AppColors.accentOrange, const Color(0xFFFFCC00)]
                      : [AppColors.accentGreen, AppColors.accentPurple],
                ),
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: 5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${(prog * 100).toStringAsFixed(2)}% of today",
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
            "MINED BALANCE",
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
                    controller.balance.value.toStringAsFixed(4),
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 5.w),
                  Padding(
                    padding: EdgeInsets.only(bottom: 3.h),
                    child: Text(
                      "SOL",
                      style: GoogleFonts.inter(
                          color: AppColors.accentGreen,
                          fontSize: 14.sp, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              )),
          SizedBox(height: 5.h),
          Obx(() {
            final usd = controller.balance.value * MiningController.solToUsd;
            final pct = (controller.balance.value / MiningController.claimThreshold * 100)
                .clamp(0.0, 100.0);
            return Text(
              "= \$${usd.toStringAsFixed(2)} USD  |  ${pct.toStringAsFixed(1)}% to \$100 Claim",
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
            );
          }),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildPlanProgressSection() {
    return Obx(() {
      final prog   = controller.planProgress.value;
      final left   = controller.remainingDays.value;
      final earned = controller.totalEarned.value;
      final done   = controller.completedDays.value;
      return GlassmorphicContainer(
        width: double.infinity,
        height: 76.h,
        borderRadius: 16.r,
        blur: 10,
        alignment: Alignment.center,
        border: 0.5,
        linearGradient: LinearGradient(colors: [
          AppColors.accentLeaf.withOpacity(0.06),
          Colors.white.withOpacity(0.02),
        ]),
        borderGradient: LinearGradient(colors: [
          AppColors.accentLeaf.withOpacity(0.35), Colors.transparent,
        ]),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      "365-DAY PLAN  |  \$18 => \$100",
                      style: GoogleFonts.inter(
                          color: AppColors.accentLeaf, fontSize: 9.sp,
                          fontWeight: FontWeight.w800, letterSpacing: 0.8),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "${earned.toStringAsFixed(1)} / 10,000 SOL",
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 9.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              LinearPercentIndicator(
                lineHeight: 5.h,
                percent: prog.clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                linearGradient: const LinearGradient(
                    colors: [AppColors.accentLeaf, Color(0xFF2E8B00)]),
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: 5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("$done / 365 days mined",
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp)),
                  Text("$left days left",
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp)),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBoostProgressSection() {
    return Obx(() {
      final prog     = controller.boostProgress.value;
      final left     = controller.boostRemainingDays.value;
      final earned   = controller.boostEarned.value;
      final total    = controller.boostTotalSOL.value;
      final complete = controller.boostIsComplete.value;
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
                      "BOOST  |  \$${controller.boostAmount.value.toStringAsFixed(0)} => \$${(controller.boostAmount.value * 2).toStringAsFixed(0)}",
                      style: GoogleFonts.inter(
                          color: AppColors.accentPurple, fontSize: 9.sp,
                          fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    if (complete) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text("DONE",
                            style: GoogleFonts.inter(
                                color: AppColors.accentGreen,
                                fontSize: 7.sp, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  Flexible(
                    child: Text(
                      "${earned.toStringAsFixed(1)} / ${total.toStringAsFixed(0)} SOL",
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
                    colors: [AppColors.accentPurple, Color(0xFFCC44FF)]),
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: 5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${(prog * 100).toStringAsFixed(2)}% complete",
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp)),
                  Text(complete ? "Boost Complete!" : "$left days left",
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp)),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMiningOrb() {
    return Obx(() {
      final active   = controller.isMining.value;
      final complete = controller.isComplete.value;
      final paid     = controller.hasPaid.value;
      final started  = controller.dayStarted.value;
      final canStart = controller.canStartNewDay.value;
      final hasAuto  = controller.hasAutoStart.value;

      final isPaused  = paid && started && !active && !complete;
      final isWaiting = paid && !started && !canStart && !active && !complete;

      IconData    orbIcon;
      String      orbLabel;
      String      orbSubLabel = '';
      Color       orbIconColor;
      List<Color> borderColors;

      if (complete) {
        orbIcon      = CupertinoIcons.checkmark_seal_fill;
        orbLabel     = "COMPLETE";
        orbIconColor = AppColors.accentLeaf;
        borderColors = [AppColors.accentLeaf, const Color(0xFF2E8B00)];
      } else if (active && hasAuto) {
        orbIcon      = CupertinoIcons.bolt_fill;
        orbLabel     = "AUTO";
        orbSubLabel  = "MINING";
        orbIconColor = AppColors.accentOrange;
        borderColors = [AppColors.accentOrange, AppColors.accentGreen];
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
      } else if (isWaiting) {
        orbIcon      = CupertinoIcons.clock_fill;
        orbLabel     = "NEXT DAY";
        orbSubLabel  = "Coming soon...";
        orbIconColor = Colors.white38;
        borderColors = [Colors.white24, Colors.white10];
      } else if (paid && canStart) {
        orbIcon      = CupertinoIcons.bolt_fill;
        orbLabel     = "START";
        orbSubLabel  = "Today's mining";
        orbIconColor = Colors.white70;
        borderColors = [Colors.white38, Colors.white10];
      } else {
        orbIcon      = CupertinoIcons.lock_fill;
        orbLabel     = "LOCKED";
        orbSubLabel  = "\$18 to unlock";
        orbIconColor = AppColors.accentLeaf.withOpacity(0.75);
        borderColors = [AppColors.accentLeaf.withOpacity(0.45), Colors.white10];
      }

      return GestureDetector(
        onTap: paid ? controller.toggleMining : _showConfirmDialog,
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
                    color: (hasAuto ? AppColors.accentOrange : AppColors.accentGreen)
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
          percent: controller.cycleProgress.value,
          backgroundColor: Colors.white10,
          linearGradient: const LinearGradient(
              colors: [AppColors.accentPurple, AppColors.accentGreen]),
          barRadius: const Radius.circular(10),
          padding: EdgeInsets.zero,
        ));
  }

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
            child: controller.hasAutoStart.value
                ? _activeAutoButton()
                : _smallButton("AUTO", CupertinoIcons.bolt_fill,
                    AppColors.accentOrange, _showAutoStartDialog),
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

  Widget _buildEntryFeeButton() {
    return GestureDetector(
      onTap: _showConfirmDialog,
      child: GlassmorphicContainer(
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
                      "\$18 ENTRY FEE",
                      style: GoogleFonts.inter(
                          color: AppColors.accentLeaf, fontSize: 13.sp,
                          fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "Tap to unlock 365-day mining plan",
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right,
                  color: AppColors.accentLeaf.withOpacity(0.6), size: 15.sp),
            ],
          ),
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

  Widget _activeAutoButton() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 60.h,
      borderRadius: 15.r,
      blur: 10,
      alignment: Alignment.center,
      border: 0.5,
      linearGradient: LinearGradient(colors: [
        AppColors.accentOrange.withOpacity(0.15), Colors.transparent,
      ]),
      borderGradient: LinearGradient(colors: [
        AppColors.accentOrange.withOpacity(0.6), Colors.transparent,
      ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.bolt_fill, color: AppColors.accentOrange, size: 16.sp),
          SizedBox(width: 5.w),
          Text("AUTO ON",
              style: GoogleFonts.inter(
                  color: AppColors.accentOrange,
                  fontSize: 11.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Obx(() => Row(
          children: [
            Expanded(child: _statBox("SPEED", "450 TH/S", AppColors.accentGreen)),
            SizedBox(width: 8.w),
            Expanded(child: _statBox("MINED DAYS", "${controller.completedDays.value}", Colors.orangeAccent)),
            SizedBox(width: 8.w),
            Expanded(child: _statBox("DAYS LEFT", "${controller.remainingDays.value}", AppColors.accentLeaf)),
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

  void _showConfirmDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text("Confirm Payment",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16.sp)),
        content: Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Text(
            "Pay \$18.00 to activate your plan.\n\n"
            "Plan: Mine 10,000 SOL over 365 days.\n\n"
            "Tap the ORB each day to start mining and earn SOL daily.\n\n"
            "Add Auto Start for \$10 to mine automatically every day.",
            style: GoogleFonts.inter(fontSize: 12.sp),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.inter(fontSize: 14.sp)),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              controller.activatePlan(); // ✅ API call
            },
            child: Text("Pay \$18",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  void _showClaimDialog() {
    final solAmount = controller.balance.value;
    final usdAmount = solAmount * MiningController.solToUsd;
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
                      "Send your earned Solana to your wallet.",
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
                            child: Text("${solAmount.toStringAsFixed(2)} SOL",
                                style: GoogleFonts.inter(
                                    color: AppColors.accentGreen, fontSize: 26.sp,
                                    fontWeight: FontWeight.w900)),
                          ),
                          SizedBox(height: 4.h),
                          Text("= \$${usdAmount.toStringAsFixed(2)} USD",
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
                              final claimed = await controller.claimReward(); // ✅ API call
                              if (claimed > 0) {
                                _showClaimSuccessDialog(claimed, claimed * MiningController.solToUsd);
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

  void _showClaimSuccessDialog(double sol, double usd) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) {
        final dw = _dw(ctx, pct: 0.78, min: 250, max: 310);
        final dh = _dh(ctx, pct: 0.38, min: 230, max: 270);
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
                        "${sol.toStringAsFixed(2)} SOL  =  \$${usd.toStringAsFixed(2)} USD",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            color: AppColors.accentLeaf, fontSize: 15.sp,
                            fontWeight: FontWeight.bold, height: 1.4),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "Sent to your Solana wallet successfully.",
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
    final bal  = controller.balance.value;
    final need = MiningController.claimThreshold - bal;
    final pct  = (bal / MiningController.claimThreshold * 100).clamp(0.0, 100.0);
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
                    Text("Not Ready Yet",
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 16.sp,
                            fontWeight: FontWeight.w900)),
                    SizedBox(height: 8.h),
                    Text(
                      "You need 10,000 SOL and an active plan to claim.",
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
                      "${pct.toStringAsFixed(1)}%  |  ${need.toStringAsFixed(0)} SOL remaining",
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

  void _showAutoStartDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) {
        final dw = _dw(ctx, pct: 0.84, min: 260, max: 340);
        final dh = _dh(ctx, pct: 0.48, min: 270, max: 330);
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
                  AppColors.accentOrange.withOpacity(0.12),
                  Colors.black.withOpacity(0.8),
                ],
              ),
              borderGradient: LinearGradient(colors: [
                AppColors.accentOrange.withOpacity(0.7),
                AppColors.accentGreen.withOpacity(0.3),
              ]),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.bolt_fill,
                        color: AppColors.accentOrange, size: 32.sp),
                    SizedBox(height: 10.h),
                    Text("AUTO START MINING",
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 15.sp,
                            fontWeight: FontWeight.w900, letterSpacing: 1)),
                    SizedBox(height: 8.h),
                    Text(
                      "Automatically starts the ORB each day.\nNo need to tap manually every day!\nEarn SOL hands-free, every single day.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: Colors.white60, fontSize: 11.sp, height: 1.5),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                            color: AppColors.accentOrange.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text("\$10.00",
                              style: GoogleFonts.inter(
                                  color: AppColors.accentOrange, fontSize: 26.sp,
                                  fontWeight: FontWeight.w900)),
                          Text("One-time fee for lifetime auto mining",
                              style: GoogleFonts.inter(
                                  color: Colors.white38, fontSize: 9.sp)),
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
                              Navigator.pop(ctx);
                              controller.activateAutoStart(); // ✅ API call
                            },
                            child: Container(
                              height: 46.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  AppColors.accentOrange,
                                  AppColors.accentOrange.withOpacity(0.75),
                                ]),
                                borderRadius: BorderRadius.circular(13.r),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.bolt_fill,
                                      color: Colors.white, size: 14.sp),
                                  SizedBox(width: 6.w),
                                  Text("Pay \$10",
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
    );
  }

  void _showBoostDialog() {
    final TextEditingController amountCtrl = TextEditingController();
    double? previewSOL;

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
                      Text("Max \$50  |  Earn 2x in 80 days",
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
                              previewSOL = (v != null && v >= 1 && v <= 50)
                                  ? v * 2.0 * (10000.0 / 18.0)
                                  : null;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 12.h),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: previewSOL != null
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
                                            "You'll earn: ${previewSOL!.toStringAsFixed(2)} SOL",
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
                                    Text("in 80 days",
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
                                controller.activateBoost(v); // ✅ API call
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
