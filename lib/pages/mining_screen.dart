import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
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

void main() => runApp(const MineMatrixApp());

class MineMatrixApp extends StatelessWidget {
  const MineMatrixApp({super.key});
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
  static const double entryFee          = 18.0;
  static const int    planDays          = 365;
  static const double targetSOL         = 10000.0;   // 10,000 SOL = $100
  static const double solToUsd          = 0.01;      // 1 SOL = $0.01
  static const double claimThreshold    = 10000.0;   // = $100
  static const double dailySOL          = targetSOL / planDays;
  static const int    ticksPerDay       = 864000;
  static const double perTickEarning    = dailySOL / ticksPerDay;

  static const int    boostDays         = 80;
  static const int    totalBoostTicks   = boostDays * ticksPerDay;
  static const double autoStartFee      = 10.0;

  var isMining         = false.obs;
  var hasPaid          = false.obs;
  var isComplete       = false.obs;
  var balance          = 0.0.obs;
  var cycleProgress    = 0.0.obs;
  var planProgress     = 0.0.obs;
  var remainingDays    = planDays.obs;
  var totalEarned      = 0.0.obs;

  var completedDays    = 0.obs;
  var currentDayNum    = 1.obs;
  var dayProgress      = 0.0.obs;
  var dayStarted       = false.obs;
  var canStartNewDay   = true.obs;
  var todayEarned      = 0.0.obs;

  var hasAutoStart     = false.obs;

  var boostPaid           = false.obs;
  var boostIsComplete     = false.obs;
  var boostAmount         = 0.0.obs;
  var boostProgress       = 0.0.obs;
  var boostRemainingDays  = boostDays.obs;
  var boostEarned         = 0.0.obs;
  var boostTotalSOL       = 0.0.obs;

  // Claim
  var totalClaimedSOL  = 0.0.obs;
  var claimCount       = 0.obs;

  bool get canClaim => balance.value >= claimThreshold && hasPaid.value;

  Timer? _timer;
  int    _dayElapsedTicks   = 0;
  int    _boostElapsedTicks = 0;
  double _boostPerTick      = 0.0;

  void activatePlan() {
    hasPaid.value         = true;
    isComplete.value      = false;
    _dayElapsedTicks      = 0;
    completedDays.value   = 0;
    currentDayNum.value   = 1;
    balance.value         = 0;
    totalEarned.value     = 0;
    planProgress.value    = 0;
    remainingDays.value   = planDays;
    dayProgress.value     = 0;
    dayStarted.value      = false;
    canStartNewDay.value  = true;
    todayEarned.value     = 0;
  }

  void activateAutoStart() {
    hasAutoStart.value = true;
    if (hasPaid.value && !isComplete.value &&
        !isMining.value && canStartNewDay.value && !dayStarted.value) {
      _startNewDay();
    }
  }

  void toggleMining() {
    if (!hasPaid.value || isComplete.value) return;
    if (isMining.value) {
      _timer?.cancel();
      isMining.value = false;
    } else if (dayStarted.value) {
      _resumeMining();
    } else if (canStartNewDay.value) {
      _startNewDay();
    }
  }

  void _startNewDay() {
    dayStarted.value     = true;
    canStartNewDay.value = false;
    isMining.value       = true;
    _runTimer();
  }

  void _resumeMining() {
    isMining.value = true;
    _runTimer();
  }

  void _runTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (_dayElapsedTicks >= ticksPerDay) {
        t.cancel();
        isMining.value     = false;
        dayStarted.value   = false;
        completedDays.value++;
        _dayElapsedTicks   = 0;
        dayProgress.value  = 0;
        todayEarned.value  = 0;

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

      balance.value       += perTickEarning;
      totalEarned.value   += perTickEarning;
      todayEarned.value   += perTickEarning;
      cycleProgress.value  = (cycleProgress.value + 0.005) % 1.0;
      _dayElapsedTicks++;
      dayProgress.value    = _dayElapsedTicks / ticksPerDay;
      planProgress.value   =
          (completedDays.value * ticksPerDay + _dayElapsedTicks) /
          (planDays * ticksPerDay);
      remainingDays.value  =
          (planDays - completedDays.value - _dayElapsedTicks / ticksPerDay)
              .ceil()
              .clamp(0, planDays);

      if (boostPaid.value && !boostIsComplete.value) {
        if (_boostElapsedTicks < totalBoostTicks) {
          balance.value          += _boostPerTick;
          boostEarned.value      += _boostPerTick;
          _boostElapsedTicks++;
          boostProgress.value     = _boostElapsedTicks / totalBoostTicks;
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

  void activateBoost(double amount) {
    boostPaid.value          = true;
    boostIsComplete.value    = false;
    boostAmount.value        = amount;
    _boostElapsedTicks       = 0;
    boostProgress.value      = 0;
    boostEarned.value        = 0;
    boostRemainingDays.value = boostDays;
    final total              = amount * 2.0 * (10000.0 / 18.0);
    boostTotalSOL.value      = total;
    _boostPerTick            = total / totalBoostTicks;
  }

  /// Claim: balance 0 করে, totalClaimedSOL এ যোগ করে
  double claimReward() {
    final claimed         = balance.value;
    totalClaimedSOL.value += claimed;
    balance.value         = 0.0;
    claimCount.value++;
    return claimed;
  }

  @override
  void onClose() {
    _timer?.cancel();
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
          // ─── Claim Button ─────────────────────────────────
          Obx(() => controller.hasPaid.value
              ? _buildClaimSection()
              : const SizedBox.shrink()),
          SizedBox(height: 12.h),
          _buildStatsGrid(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // CLAIM SECTION
  // ══════════════════════════════════════════════════════
  Widget _buildClaimSection() {
    return Obx(() {
      final canClaim  = controller.canClaim;
      final balance   = controller.balance.value;
      final claimed   = controller.totalClaimedSOL.value;
      final claimCnt  = controller.claimCount.value;
      final pct       = (balance / MiningController.claimThreshold * 100).clamp(0.0, 100.0);
      final usdVal    = balance * MiningController.solToUsd;

      return GlassmorphicContainer(
        width: double.infinity,
        height: canClaim ? 130.h : 110.h,
        borderRadius: 20.r,
        blur: 20,
        alignment: Alignment.center,
        border: canClaim ? 1.5 : 0.5,
        linearGradient: LinearGradient(colors: [
          canClaim
              ? AppColors.accentGreen.withOpacity(0.12)
              : Colors.white.withOpacity(0.03),
          Colors.white.withOpacity(0.02),
        ]),
        borderGradient: LinearGradient(colors: [
          canClaim
              ? AppColors.accentGreen.withOpacity(0.7)
              : Colors.white.withOpacity(0.1),
          Colors.transparent,
        ]),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(
                      CupertinoIcons.gift_fill,
                      color: canClaim ? AppColors.accentGreen : Colors.white38,
                      size: 11.sp,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      "CLAIM REWARD",
                      style: GoogleFonts.inter(
                        color: canClaim ? AppColors.accentGreen : Colors.white38,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ]),
                  if (claimCnt > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.accentPurple.withOpacity(0.4),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        "$claimCnt claimed",
                        style: GoogleFonts.inter(
                          color: AppColors.accentPurple,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.h),

              // Progress bar toward $100 claim
              LinearPercentIndicator(
                lineHeight: 5.h,
                percent: pct / 100,
                backgroundColor: Colors.white10,
                linearGradient: LinearGradient(
                  colors: canClaim
                      ? [AppColors.accentGreen, const Color(0xFF00FFB2)]
                      : [Colors.white24, Colors.white12],
                ),
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: 5.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${pct.toStringAsFixed(1)}%  •  \$${usdVal.toStringAsFixed(2)} / \$100",
                    style: GoogleFonts.inter(
                      color: canClaim ? Colors.white60 : Colors.white30,
                      fontSize: 9.sp,
                    ),
                  ),
                  if (claimed > 0)
                    Text(
                      "Total: ${claimed.toStringAsFixed(0)} SOL",
                      style: GoogleFonts.inter(
                        color: AppColors.accentPurple.withOpacity(0.8),
                        fontSize: 9.sp,
                      ),
                    ),
                ],
              ),

              // Claim button (only visible when claimable)
              if (canClaim) ...[
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: () => _handleClaim(),
                  child: Container(
                    width: double.infinity,
                    height: 36.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentGreen, Color(0xFF00D4A0)],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGreen.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.arrow_down_circle_fill,
                            color: Colors.black, size: 14.sp),
                        SizedBox(width: 6.w),
                        Text(
                          "CLAIM \$100",
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(
                      duration: 1800.ms,
                      color: Colors.white38,
                    ),
              ] else ...[
                SizedBox(height: 6.h),
                Text(
                  "Mine ${(MiningController.claimThreshold - balance).toStringAsFixed(0)} more SOL to unlock \$100 claim",
                  style: GoogleFonts.inter(
                    color: Colors.white24,
                    fontSize: 8.5.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
    });
  }

  void _handleClaim() {
    final claimed = controller.claimReward();
    final usd     = (claimed * MiningController.solToUsd).toStringAsFixed(2);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: GlassmorphicContainer(
          width: 300.w,
          height: 220.h,
          borderRadius: 24.r,
          blur: 20,
          alignment: Alignment.center,
          border: 1.5,
          linearGradient: LinearGradient(colors: [
            AppColors.accentGreen.withOpacity(0.15),
            Colors.white.withOpacity(0.03),
          ]),
          borderGradient: LinearGradient(colors: [
            AppColors.accentGreen.withOpacity(0.7),
            Colors.transparent,
          ]),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("🎉", style: TextStyle(fontSize: 36.sp)),
              SizedBox(height: 10.h),
              Text(
                "Claim Successful!",
                style: GoogleFonts.inter(
                  color: AppColors.accentGreen,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                "${claimed.toStringAsFixed(0)} SOL  ≈  \$$usd",
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                "Reward #${controller.claimCount.value}",
                style: GoogleFonts.inter(
                  color: AppColors.accentPurple,
                  fontSize: 10.sp,
                ),
              ),
              SizedBox(height: 18.h),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentGreen, Color(0xFF00D4A0)],
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Text(
                    "AWESOME!",
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // DAILY SECTION
  // ══════════════════════════════════════════════════════
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
        statusText  = "Plan Complete! 🎉";
        statusColor = AppColors.accentLeaf;
      } else if (mining && hasAuto) {
        statusText  = "⚡ Auto Mining Active";
        statusColor = AppColors.accentOrange;
      } else if (mining) {
        statusText  = "Mining in progress...";
        statusColor = AppColors.accentGreen;
      } else if (started && !mining) {
        statusText  = "Paused — tap ORB to resume";
        statusColor = Colors.orange;
      } else if (!canStart && !started) {
        statusText  = "Today done — next day soon";
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
                      "DAY $dayNum / 365${hasAuto ? '   ⚡ AUTO' : ''}",
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

  // ══════════════════════════════════════════════════════
  // BALANCE SECTION
  // ══════════════════════════════════════════════════════
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
                          color: AppColors.accentGreen, fontSize: 14.sp, fontWeight: FontWeight.w800),
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
              "≈ \$${usd.toStringAsFixed(2)} USD  •  ${pct.toStringAsFixed(1)}% to \$100 Claim",
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
            );
          }),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  // ══════════════════════════════════════════════════════
  // PLAN PROGRESS
  // ══════════════════════════════════════════════════════
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
                  Text(
                    "365-DAY PLAN  •  \$18 → \$100",
                    style: GoogleFonts.inter(
                        color: AppColors.accentLeaf, fontSize: 9.sp,
                        fontWeight: FontWeight.w800, letterSpacing: 0.8),
                  ),
                  Flexible(
                    child: Text(
                      "${earned.toStringAsFixed(1)} / 10,000 SOL",
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

  // ══════════════════════════════════════════════════════
  // BOOST PROGRESS
  // ══════════════════════════════════════════════════════
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
          AppColors.accentPurple.withOpacity(0.35),
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
                  Text(
                    "⚡ BOOST  •  80 DAYS",
                    style: GoogleFonts.inter(
                        color: AppColors.accentPurple, fontSize: 9.sp,
                        fontWeight: FontWeight.w800, letterSpacing: 0.8),
                  ),
                  Flexible(
                    child: Text(
                      complete
                          ? "Complete ✓"
                          : "${earned.toStringAsFixed(1)} / ${total.toStringAsFixed(0)} SOL",
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
                  Text("${(prog * 100).toStringAsFixed(1)}% complete",
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp)),
                  Text(complete ? "Done!" : "$left days left",
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp)),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ══════════════════════════════════════════════════════
  // MINING ORB
  // ══════════════════════════════════════════════════════
  Widget _buildMiningOrb() {
    return Obx(() {
      final mining  = controller.isMining.value;
      final hasPaid = controller.hasPaid.value;
      final complete = controller.isComplete.value;

      return GestureDetector(
        onTap: controller.toggleMining,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (mining)
              Container(
                width: 140.w,
                height: 140.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGreen.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat()).scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.15, 1.15),
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: complete
                      ? [AppColors.accentLeaf, const Color(0xFF2E8B00)]
                      : mining
                          ? [AppColors.accentGreen, const Color(0xFF00A060)]
                          : hasPaid
                              ? [const Color(0xFF1A2A1A), AppColors.background]
                              : [const Color(0xFF1A1A2A), AppColors.background],
                ),
                border: Border.all(
                  color: complete
                      ? AppColors.accentLeaf
                      : mining
                          ? AppColors.accentGreen
                          : hasPaid
                              ? AppColors.accentGreen.withOpacity(0.3)
                              : Colors.white12,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    complete
                        ? CupertinoIcons.checkmark_seal_fill
                        : mining
                            ? CupertinoIcons.waveform
                            : CupertinoIcons.bolt_fill,
                    color: complete
                        ? Colors.white
                        : mining
                            ? Colors.white
                            : hasPaid
                                ? AppColors.accentGreen.withOpacity(0.5)
                                : Colors.white24,
                    size: 28.sp,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    complete
                        ? "DONE"
                        : mining
                            ? "MINING"
                            : hasPaid
                                ? "TAP"
                                : "LOCKED",
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ══════════════════════════════════════════════════════
  // CYCLE PROGRESS BAR
  // ══════════════════════════════════════════════════════
  Widget _buildCycleProgressBar() {
    return Obx(() {
      final prog = controller.cycleProgress.value;
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("MINING CYCLE",
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 8.sp, letterSpacing: 0.8)),
              Text("${(prog * 100).toStringAsFixed(0)}%",
                  style: GoogleFonts.inter(
                      color: AppColors.accentGreen, fontSize: 8.sp, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 6.h),
          LinearPercentIndicator(
            lineHeight: 4.h,
            percent: prog.clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            linearGradient: const LinearGradient(
                colors: [AppColors.accentPurple, AppColors.accentGreen]),
            barRadius: const Radius.circular(10),
            padding: EdgeInsets.zero,
          ),
        ],
      );
    });
  }

  // ══════════════════════════════════════════════════════
  // ENTRY FEE BUTTON
  // ══════════════════════════════════════════════════════
  Widget _buildEntryFeeButton() {
    return GestureDetector(
      onTap: () {
        // Payment flow here
        controller.activatePlan();
      },
      child: Container(
        width: double.infinity,
        height: 50.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.accentGreen, Color(0xFF00A060)]),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGreen.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.lock_open_fill, color: Colors.black, size: 16.sp),
            SizedBox(width: 8.w),
            Text(
              "ACTIVATE PLAN — \$${MiningController.entryFee.toStringAsFixed(0)}",
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // ACTION BUTTONS (Mining controls)
  // ══════════════════════════════════════════════════════
  Widget _buildActionButtons() {
    return Obx(() {
      final hasAuto = controller.hasAutoStart.value;
      final complete = controller.isComplete.value;
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: controller.toggleMining,
              child: Container(
                height: 46.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: controller.isMining.value
                        ? [Colors.red.shade700, Colors.red.shade900]
                        : [AppColors.accentGreen, const Color(0xFF00A060)],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: (controller.isMining.value
                              ? Colors.red
                              : AppColors.accentGreen)
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      controller.isMining.value
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      color: Colors.white,
                      size: 14.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      controller.isMining.value ? "PAUSE" : "START",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!hasAuto && !complete) ...[
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: () => controller.activateAutoStart(),
              child: GlassmorphicContainer(
                width: 110.w,
                height: 46.h,
                borderRadius: 14.r,
                blur: 10,
                alignment: Alignment.center,
                border: 1,
                linearGradient: LinearGradient(colors: [
                  AppColors.accentOrange.withOpacity(0.15),
                  Colors.white.withOpacity(0.02),
                ]),
                borderGradient: LinearGradient(colors: [
                  AppColors.accentOrange.withOpacity(0.5),
                  Colors.transparent,
                ]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.bolt_fill,
                        color: AppColors.accentOrange, size: 12.sp),
                    SizedBox(width: 4.w),
                    Text(
                      "AUTO",
                      style: GoogleFonts.inter(
                        color: AppColors.accentOrange,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  // ══════════════════════════════════════════════════════
  // STATS GRID
  // ══════════════════════════════════════════════════════
  Widget _buildStatsGrid() {
    return Obx(() {
      final stats = [
        {
          'label': 'Total Earned',
          'value': '${controller.totalEarned.value.toStringAsFixed(1)} SOL',
          'icon': CupertinoIcons.chart_bar_fill,
          'color': AppColors.accentGreen,
        },
        {
          'label': 'Total Claimed',
          'value':
              '\$${(controller.totalClaimedSOL.value * MiningController.solToUsd).toStringAsFixed(2)}',
          'icon': CupertinoIcons.gift_fill,
          'color': AppColors.accentPurple,
        },
        {
          'label': 'Claim Count',
          'value': '${controller.claimCount.value}x',
          'icon': CupertinoIcons.checkmark_seal_fill,
          'color': AppColors.accentLeaf,
        },
        {
          'label': 'Day',
          'value': '${controller.currentDayNum.value} / 365',
          'icon': CupertinoIcons.calendar,
          'color': AppColors.accentOrange,
        },
      ];

      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 2.2,
        children: stats.map((s) {
          final color = s['color'] as Color;
          return GlassmorphicContainer(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 14.r,
            blur: 10,
            alignment: Alignment.center,
            border: 0.5,
            linearGradient: LinearGradient(colors: [
              color.withOpacity(0.07),
              Colors.white.withOpacity(0.02),
            ]),
            borderGradient: LinearGradient(colors: [
              color.withOpacity(0.3),
              Colors.transparent,
            ]),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  Icon(s['icon'] as IconData, color: color, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['label'] as String,
                          style: GoogleFonts.inter(
                              color: Colors.white38, fontSize: 8.sp),
                        ),
                        Text(
                          s['value'] as String,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}
